;;;; source/legal-casegrammar.lisp
;;;; ============================================================================
;;;; Σ4β — ΓΡΑΜΜΑΤΙΚΗ ΠΤΩΣΕΩΝ (Fillmore): από ΑΦΗΓΗΣΗ σε γεγονότα υπόθεσης
;;;; ============================================================================
;;;;
;;;; Η υπαγωγή (Σ4) δέχεται γεγονότα-tuples· εδώ χτίζεται η γέφυρα από τα
;;;; φυσικά ελληνικά: κάθε ρήμα-κατηγόρημα φέρει ΠΛΑΙΣΙΟ ΠΤΩΣΕΩΝ (case frame)
;;;; — δράστης (ονομαστική προ του ρήματος), θέμα (αιτιατική μετά), κτήτορας
;;;; (γενική μετά το θέμα) — και χαρτογραφείται σε κατηγόρημα της γλώσσας
;;;; γεγονότων (:γεγονός <υποκείμενο> <κατηγόρημα> <αντικείμενο>).
;;;;
;;;; ΟΛΗ η γλωσσική γνώση είναι ΔΗΛΩΤΙΚΗ (πακέτο :verb-frames): ρήμα→κατηγόρημα,
;;;; ουσιαστικό→κατηγορία (τροφοδοτεί τις Κατηγορίες του Οργάνου), δείκτες
;;;; σκοπού/τρόπου. Το λημματικό υπόστρωμα είναι Η ΜΙΑ έδρα γλώσσας
;;;; (orchestrator.citation-authority) — καμία δεύτερη μορφολογία εδώ.
;;;;
;;;; ΤΙΜΙΟΤΗΤΑ: ό,τι δεν αναγνωρίζεται, ΔΗΛΩΝΕΤΑΙ ως μη-αναγνωσμένο — ποτέ
;;;; δεν εφευρίσκονται γεγονότα. Δογματική χαρτογράφηση: κτήτορας ≠ δράστης
;;;; ⇒ το πράγμα είναι ΞΕΝΟ ως προς τον δράστη (η έννοια του «ξένου» στα
;;;; περιουσιακά αδικήματα).

(defpackage :orchestrator.casegrammar
  (:use :cl)
  (:import-from :orchestrator.citation-authority
                #:tokenize-greek #:known-lemma #:normalize-greek #:content-lemma-p
                #:surface-stem)
  (:export #:*verb-frames* #:*noun-classes* #:*markers* #:*phrase-markers*
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
  "alist: επιθετικό λήμμα → κατηγορία (πχ \"ξένος\" → :ξένο). Τα επίθετα
   της ονοματικής φράσης του νόμου ΕΙΝΑΙ κατηγορήματα του αντικειμένου —
   «ξένο κινητό πράγμα» = πράγμα ∧ ξένο ∧ κινητό (οι Κατηγορίες στη σύνταξη).")

(defvar *phrase-markers* '()
  "λίστα (ΚΑΝΟΝΙΚΟΠΟΙΗΜΕΝΑ-tokens κατηγόρημα τιμή): ΠΟΛΥΛΕΚΤΙΚΟΙ ΟΡΟΙ-ΤΕΧΝΗΣ του
   δικαίου — «νόμιμη άμυνα», «παράνομη ιδιοποίηση» — ως ΕΝΟΤΗΤΑ, όχι μεμονωμένα
   ουσιαστικά (τα νομικά concepts ΕΙΝΑΙ φράσεις). Ταιριάζουν ως ΣΥΝΕΧΟΜΕΝΗ
   υπακολουθία στα κανονικοποιημένα tokens (τόνος/πεζά/τελικό-σ) και γεννούν
   γεγονός ΔΡΑΣΤΗ. Μία δήλωση ανά έννοια. ΔΗΛΩΜΕΝΑ ΟΡΙΑ (ΟΧΙ overclaim): (α)
   ΟΧΙ stemming — κλίση που αλλάζει το θέμα (πχ «συναινέσεως») δεν πιάνεται· (β)
   ΜΟΝΟ συνεχόμενο span — παρεμβαλλόμενη λέξη σπάει το ταίριασμα· (γ) αναιρετής
   («χωρίς») ΠΡΙΝ τη φράση την ακυρώνει. Το πλήρες κάλυμμα ρέει από γραμματική
   συστατικών (δηλωμένη ανώτερη φάση, [0075] verify).")

(orchestrator.knowledge-packs:define-knowledge-kind :verb-frames
 :doc "Πλαίσια πτώσεων: (:frame ΡΗΜΑ-ΛΗΜΜΑ ΚΑΤΗΓΟΡΗΜΑ) · (:noun-class ΛΗΜΜΑ
 ΚΑΤΗΓΟΡΙΑ) · (:marker ΛΗΜΜΑ ΚΑΤΗΓΟΡΗΜΑ ΤΙΜΗ) — η γέφυρα αφήγησης→γεγονότων."
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
       (:phrase (destructuring-bind (k phrase pred value) e
                  (declare (ignore k))
                  (let ((toks (mapcar #'normalize-greek (tokenize-greek phrase))))
                    (setf *phrase-markers*
                          (cons (list toks pred value)
                                (remove toks *phrase-markers*
                                        :key #'first :test #'equal)))))))))
 :snapshot (lambda () (list (copy-tree *verb-frames*)
                            (copy-tree *noun-classes*)
                            (copy-tree *markers*)
                            (copy-tree *adjectives*)
                            (copy-tree *phrase-markers*)))
 :restore  (lambda (st) (destructuring-bind (vf nc mk &optional aj pm) st
                          (setf *verb-frames* vf *noun-classes* nc
                                *markers* mk *adjectives* aj *phrase-markers* pm))))

;;; ── Ανάλυση ──

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

(defun %entity (token)
  "Οντότητα από επιφανειακή λέξη: το ΛΗΜΜΑ αν είναι γνωστό (ταυτότητα έννοιας,
   όχι γράμματα), αλλιώς η κανονικοποιημένη μορφή (κύρια ονόματα)."
  (let ((l (or (known-lemma token) (normalize-greek token))))
    (intern (string-upcase l) :keyword)))

(defun %content-token-p (token)
  "Λέξη ΠΕΡΙΕΧΟΜΕΝΟΥ: η διάκριση γίνεται στην έδρα της γλώσσας (κλειστές
   γραμματικές κλάσεις), πάνω στο λήμμα αν υπάρχει, αλλιώς στη μορφή."
  (content-lemma-p (or (known-lemma token) token)))

(defparameter +negation-lemmas+
  '("δεν" "μη" "μην" "ουδείς" "ουδέν" "ουδέποτε" "ούτε"
    "κανείς" "κανένας" "καμία" "κανένα" "ποτέ")
  "Οι δείκτες ΑΡΝΗΣΗΣ της ελληνικής (μόρια + αρνητικές αντωνυμίες/επιρρήματα).
   Χωρίς αυτούς, «ο Χ ΔΕΝ αφαίρεσε» παρήγαγε ΚΑΤΑΦΑΤΙΚΟ γεγονός — ενεργός
   κίνδυνος ορθότητας (εσωτερικός έλεγχος 05-07-2026). Κλειστή κλάση.")

(defparameter +accusative-articles+ '("τον" "την")
  "Οριστικά άρθρα ΑΙΤΙΑΤΙΚΗΣ (μονοσήμαντα) — σημαίνουν ΑΝΤΙΚΕΙΜΕΝΟ. Τα ουδέτερα
   «το/τα» είναι αμφίσημα (ονομ.=αιτ.) και ΔΕΝ οδηγούν ρόλο — δηλωμένο όριο.")
(defparameter +nominative-articles+ '("ο" "η" "οι")
  "Οριστικά άρθρα ΟΝΟΜΑΣΤΙΚΗΣ (μονοσήμαντα) — σημαίνουν ΥΠΟΚΕΙΜΕΝΟ (δράστη).")

(defun %negated-p (before)
  "Άρνηση του ρήματος: δείκτης άρνησης ΠΡΙΝ το ρήμα-πλαίσιο (στην ίδια πρόταση)."
  (some (lambda (tk)
          (member (normalize-greek (or (known-lemma tk) tk))
                  +negation-lemmas+ :key #'normalize-greek :test #'string=))
        before))

(defun %case-of (tokens i)
  "Μορφολογική πτώση του περιεχομένου-token στη θέση I από το ΠΡΟΗΓΟΥΜΕΝΟ
   οριστικό άρθρο (μονοσήμαντο): :acc | :nom | nil (καμία σήμανση)."
  (when (> i 0)
    (let ((a (normalize-greek (nth (1- i) tokens))))
      (cond ((member a +accusative-articles+ :key #'normalize-greek :test #'string=) :acc)
            ((member a +nominative-articles+  :key #'normalize-greek :test #'string=) :nom)
            (t nil)))))

(defun %recover-nominative (surface article)
  "Ανακτά την ΟΝΟΜΑΣΤΙΚΗ κύριου ονόματος από πλάγια πτώση, με βάση το οριστικό
   άρθρο (κλιτική ελληνικών κυρίων ονομάτων). Ώστε ο ΙΔΙΟΣ διάδικος — «ο
   Γιώργος» (υποκ.), «τον Γιώργο» (αντικ.), «του Γιώργου» (γεν.) — να είναι
   ΜΙΑ οντότητα (συναναφορά) και να ονομάζεται σωστά. ΔΗΛΩΜΕΝΑ best-effort για
   κύρια ονόματα (τα λήμματα κανονικοποιούνται ήδη)· άγνωστο άρθρο ⇒ αμετάβλητο."
  (let ((n (normalize-greek surface))
        (a (and article (normalize-greek article)))
        (len (length surface)))
    (flet ((ends (suf) (let ((k (length suf)))
                         (and (>= (length n) k) (string= suf n :start2 (- (length n) k)))))
           (chop (k) (subseq surface 0 (- len k))))
      (cond
        ((or (null a) (zerop len)) surface)
        ;; αιτιατική αρσενικού (τον Γιώργο→Γιώργος, τον Γιάννη→Γιάννης)
        ((string= a "τον")
         (if (find (char n (1- (length n))) "αεηιουω")
             (concatenate 'string surface "ς") surface))
        ;; γενική αρσενικού: -ου → -ος (του Γιώργου→Γιώργος)
        ((and (string= a "του") (ends "ου")) (concatenate 'string (chop 2) "ος"))
        ;; γενική θηλυκού: -ας→-α, -ης→-η (της Μαρίας→Μαρία, της Ελένης→Ελένη)
        ((and (string= a "της") (or (ends "ας") (ends "ης"))) (chop 1))
        ;; ονομαστική / αιτιατική θηλυκού / λοιπά: αμετάβλητο
        (t surface)))))

(defun %entity* (tokens i)
  "Οντότητα από τη θέση I, ΚΑΝΟΝΙΚΟΠΟΙΗΜΕΝΗ σε ονομαστική: λήμμα αν είναι
   γνωστό, αλλιώς ανάκτηση ονομαστικής κύριου ονόματος από το προηγούμενο άρθρο."
  (let* ((token (nth i tokens))
         (l (known-lemma token)))
    (if l
        (intern (string-upcase l) :keyword)
        (intern (string-upcase
                 (normalize-greek
                  (%recover-nominative token (when (> i 0) (nth (1- i) tokens)))))
                :keyword))))

(defun %content-indices (tokens lo hi)
  "Δείκτες λέξεων περιεχομένου στο [LO, HI) — με τη σειρά τους."
  (loop for i from lo below hi
        when (%content-token-p (nth i tokens)) collect i))

(defparameter +prepositions+
  '("με" "σε" "από" "για" "προς" "κατά" "χωρίς" "μετά" "πριν" "ως" "έως" "μέχρι"
    "παρά" "αντί" "στη" "στην" "στο" "στον" "στα" "στους" "στις" "εκ" "εξ" "ενώ")
  "Κλειστή κλάση: προθέσεις/σύνδεσμοι που ΟΡΙΖΟΥΝ το τέλος μιας ονοματικής φράσης
   αντικειμένου (η επόμενη φράση είναι εμπρόθετος/δευτερεύουσα, όχι η κεφαλή).")

(defparameter +genitive-articles+ '("του" "της" "των")
  "Οριστικά άρθρα ΓΕΝΙΚΗΣ — σημαίνουν ΚΤΗΤΟΡΑ (το επόμενο περιεχόμενο ανήκει-σε).")

(defun %post-verb-np (tokens vpos)
  "(values κεφαλή-index τροποποιητές-indices ΟΛΟΙ-οι-δείκτες): η ΠΡΩΤΗ ονοματική
   φράση ΑΝΤΙΚΕΙΜΕΝΟΥ αμέσως μετά το ρήμα (άρθρα ονομ./αιτ. αγνοούνται, επίθετα+
   κεφαλή) ΩΣΠΟΥ πρόθεση / άρθρο ΓΕΝΙΚΗΣ (κτήτορας = χωριστή φράση) / δείκτης /
   άλλο ρηματικό πλαίσιο. ΚΕΦΑΛΗ = ΤΕΛΕΥΤΑΙΑ λέξη περιεχομένου του NP (όχι η πρώτη
   — το bug: «τα ξένα κινητά εργαλεία» έδινε θέμα «ξένα»). nil αν δεν υπάρχει NP
   αμέσως (πχ πρόθεση) — τότε ισχύει η μορφολογική διαδρομή. Ο καλών κάνει
   membership-έλεγχο: refine ΜΟΝΟ αν το μορφολογικό θέμα ανήκει σε ΑΥΤΟ το NP."
  (let ((content '()))
    (loop for i from (1+ vpos) below (length tokens)
          for tk = (nth i tokens)
          for l = (known-lemma tk)
          do (cond
               ((or (member (normalize-greek tk) +prepositions+
                            :key #'normalize-greek :test #'string=)
                    (member (normalize-greek tk) +genitive-articles+
                            :key #'normalize-greek :test #'string=)
                    (and l (assoc l *markers* :test #'string=))
                    (and l (assoc l *verb-frames* :test #'string=)))
                (return))                       ; όριο NR — σταμάτα (κενό ⇒ nil)
               ((%content-token-p tk) (push i content))
               (t nil)))                        ; άρθρο ονομ./αιτ. εντός NP: αγνόησε
    (let ((idxs (nreverse content)))
      (values (car (last idxs)) (butlast idxs) idxs))))

(defun %genitive-owner-index (tokens vpos)
  "Δείκτης ΚΤΗΤΟΡΑ: πρώτο περιεχόμενο μετά το ρήμα με ΠΡΟΗΓΟΥΜΕΝΟ άρθρο γενικής
   (του/της/των). ΟΧΙ «δεύτερο περιεχόμενο» (που έπαιρνε επίθετο ως κτήτορα)."
  (loop for i from (1+ vpos) below (length tokens)
        when (and (%content-token-p (nth i tokens))
                  (> i 0)
                  (member (normalize-greek (nth (1- i) tokens))
                          +genitive-articles+ :key #'normalize-greek :test #'string=))
          return i))

(defun %subseq-start (needle haystack)
  "Θέση όπου το NEEDLE (λίστα strings) εμφανίζεται ως ΣΥΝΕΧΟΜΕΝΗ υπακολουθία στο
   HAYSTACK, ή nil."
  (let ((n (length needle)) (h (length haystack)))
    (and (plusp n) (<= n h)
         (loop for start from 0 to (- h n)
               when (loop for i from 0 below n
                          always (string= (nth i needle) (nth (+ start i) haystack)))
                 return start))))

(defparameter +phrase-negators+ '("χωρίς" "δίχως")
  "Προθέσεις ΑΠΟΚΛΕΙΣΜΟΥ: «χωρίς τη συναίνεση» ΑΝΑΙΡΕΙ τον όρο — αλλιώς το phrase
   marker θα έδινε αθώωση εκεί που στοιχειοθετείται η πράξη ([0075] verify Q2a).")

(defun %article-skip-p (tok)
  "Οριστικό άρθρο (κάθε πτώση + ουδέτερα) — προσπερνιέται όταν ψάχνουμε πίσω τον
   αναιρετή μιας ονοματικής φράσης όρου-τέχνης."
  (let ((n (normalize-greek tok)))
    (or (member n '("το" "τα" "τη" "την") :key #'normalize-greek :test #'string=)
        (member n +accusative-articles+ :key #'normalize-greek :test #'string=)
        (member n +nominative-articles+ :key #'normalize-greek :test #'string=)
        (member n +genitive-articles+   :key #'normalize-greek :test #'string=))))

(defun %phrase-negated-p (tokens start)
  "ΠΡΙΝ τη φράση (θέση START), εντός της άμεσης εμβέλειας άρνησης, υπάρχει αναιρετής
   («χωρίς/δίχως») ή δείκτης άρνησης («δεν/μη/…»); ⇒ ο όρος ΔΕΝ ισχύει καταφατικά.
   Εμβέλεια (bounded, ΔΕΝ διασχίζει πρόταση): προσπερνά άρθρα + προθέσεις + ΕΝΑ
   κυβερνών ρήμα («δεν τελούσε σε νόμιμη άμυνα»)· σταματά στην πρώτη ΑΛΛΗ λέξη.
   Θάνατος του Q2a: «χωρίς τη συναίνεση»/«δεν τελούσε σε άμυνα» ⇒ καμία σιωπηλή αθώωση."
  (let ((budget 1))                                    ; ΕΝΑ αυθαίρετο token (κυβερνών ρήμα/βοηθητικό)
    (loop for i from (1- start) downto 0
          for tok = (nth i tokens)
          do (cond
               ((or (member (normalize-greek tok) +phrase-negators+
                            :key #'normalize-greek :test #'string=)
                    (member (normalize-greek tok) +negation-lemmas+
                            :key #'normalize-greek :test #'string=))
                (return t))
               ((%article-skip-p tok))                ; άρθρο → πίσω (ελεύθερα)
               ((member (normalize-greek tok) +prepositions+
                        :key #'normalize-greek :test #'string=))   ; πρόθεση → πίσω (ελεύθερα)
               ((plusp budget) (decf budget))          ; προσπέρασε ΕΝΑ ρήμα («δεν ΤΕΛΟΥΣΕ σε…»)
               (t (return nil))))))                    ; εκτός άμεσης εμβέλειας άρνησης

(defun %phrase-marker-facts (tokens agent)
  "Γεγονότα από ΠΟΛΥΛΕΚΤΙΚΟΥΣ όρους-τέχνης: κάθε *phrase-markers* που ταιριάζει ως
   συνεχόμενη υπακολουθία στα κανονικοποιημένα tokens → (:γεγονός ΔΡΑΣΤΗΣ pred value),
   ΕΚΤΟΣ αν προηγείται αναιρετής/«χωρίς» (τότε ο όρος αναιρείται — καμία εφεύρεση
   καταφατικού). Ταίριασμα κανονικοποιημένο (τόνος/πεζά/τελικό-σ)· ΟΧΙ stemming —
   κλίση που αλλάζει το θέμα δεν πιάνεται (δηλωμένο όριο). ΤΟ VALUE ΕΙΝΑΙ ΚΥΡΙΟΛΕΚΤΙΚΟ:
   ΔΕΝ εφευρίσκεται co-reference προς το θέμα ([0075] verify Q3/D1 — το παλιό slot
   :theme κατασκεύαζε «συναίνεση για το θέμα» ακόμη κι όταν το κείμενο έλεγε ΑΛΛΟ
   αντικείμενο· η ανάλυση αντικειμένου-όρου ρέει από τη γραμματική συστατικών, όχι
   από εδώ — τίμια άγνοια αντί εφεύρεσης)."
  (let ((norm (mapcar #'normalize-greek tokens)) (facts '()))
    (dolist (pm *phrase-markers* facts)
      (destructuring-bind (phrase pred value) pm
        (let ((start (%subseq-start phrase norm)))
          (when (and start (not (%phrase-negated-p tokens start)))
            (pushnew (list :γεγονός agent pred value) facts :test #'equal)))))))

(defun %role-indices (tokens vpos before after)
  "(values δείκτης-δράστη δείκτης-θέματος): πρώτα ΜΟΡΦΟΛΟΓΙΚΑ (ονομαστική=
   δράστης, αιτιατική=θέμα — «τον Α σκότωσε ο Β» σωστά), αλλιώς ΘΕΣΙΑΚΑ (δράστης=
   τελευταίο περιεχόμενο πριν το ρήμα, θέμα=πρώτο μετά). Η θεσιακή διαδρομή είναι
   ΑΚΡΙΒΩΣ η προηγούμενη — καμία παλινδρόμηση όπου δεν υπάρχει άρθρο."
  (let (nom acc)
    (loop for i from 0 below (length tokens)
          when (and (/= i vpos) (%content-token-p (nth i tokens)))
            do (case (%case-of tokens i)
                 (:nom (unless nom (setf nom i)))
                 (:acc (unless acc (setf acc i)))))
    (values (or nom (let ((cs (%content-indices tokens 0 vpos))) (car (last cs))))
            (or acc (first (%content-indices tokens (1+ vpos) (length tokens)))))))

(defun %parse-sentence (tokens)
  "(values γεγονότα αναγνωρίστηκε-p): πλαίσιο πτώσεων SVO(G) — δράστης/θέμα
   κατά ΜΟΡΦΟΛΟΓΙΑ (άρθρο ονομαστικής/αιτιατικής) με θεσιακή εφεδρεία·
   κτήτορας (επόμενο περιεχόμενο μετά το θέμα)· ΑΡΝΗΣΗ ρητή (δεν εφευρίσκεται
   καταφατικό γεγονός για αρνημένη πράξη)."
  (let* ((vpos (position-if (lambda (tk)
                              (let ((l (known-lemma tk)))
                                (and l (assoc l *verb-frames* :test #'string=))))
                            tokens)))
    (if (null vpos)
        (values '() nil)
        (let* ((verb-lemma (known-lemma (nth vpos tokens)))
               (pred (cdr (assoc verb-lemma *verb-frames* :test #'string=)))
               (before (subseq tokens 0 vpos))
               (after  (subseq tokens (1+ vpos)))
               (negated (%negated-p before))
               (owner-i (%genitive-owner-index tokens vpos))
               (owner-tok (and owner-i (nth owner-i tokens)))
               (facts '()))
          (multiple-value-bind (agent-i theme-i0)
              (%role-indices tokens vpos before after)
            ;; ΚΕΦΑΛΗ ΝΡ: αν υπάρχει εμπρόθετη-ελεύθερη φράση αντικειμένου μετά το
            ;; ρήμα, το θέμα είναι η ΚΕΦΑΛΗ της (όχι το πρώτο επίθετο)· αλλιώς η
            ;; μορφολογική/θεσιακή θέση (πχ προ-ρηματικό «τον Α»).
            (multiple-value-bind (np-head np-mods np-idxs) (%post-verb-np tokens vpos)
             (declare (ignore np-idxs))
             ;; ΘΕΜΑ: προ-ρηματικό αιτιατικό = fronted αντικείμενο (OVS «Τον Α σκότωσε
             ;; ο Β») ⇒ κράτα το. Αλλιώς = η ΚΕΦΑΛΗ του ΠΡΩΤΟΥ post-verb NP (το άμεσο
             ;; αντικείμενο) — αγνοώντας μεταγενέστερα ΠΛΑΓΙΑ αιτιατικά (πχ «την
             ;; παράνομη ιδιοποίηση» μέσα στη φράση σκοπού). Τα επίθετα του NP → κλάσεις.
             (let* ((frontedp (and theme-i0 (< theme-i0 vpos)))
                    (theme-i (if frontedp theme-i0 (or np-head theme-i0)))
                    (np-mods (if (and (not frontedp) np-head) np-mods '())))
             (when (and agent-i theme-i)
              (let ((agent (%entity* tokens agent-i))
                    (theme (%entity* tokens theme-i))
                    (theme-tok (nth theme-i tokens)))
                (if negated
                    ;; ΑΡΝΗΣΗ: το μόνο γεγονός είναι ότι η πράξη ΔΕΝ έγινε —
                    ;; κανένα καταφατικό/παράγωγο (ξένο, δείκτες). Τίμια στάση.
                    (setf facts (list (list :άρνηση agent pred theme)))
                    (progn
                      (push (list :γεγονός agent pred theme) facts)
                      ;; κατηγορία θέματος → τροφοδοτεί τις Κατηγορίες (Barbara)
                      (let* ((tl (known-lemma theme-tok))
                             (class (and tl (cdr (assoc tl *noun-classes* :test #'string=)))))
                        (when class (push (list :γεγονός theme :είναι class) facts)))
                      ;; κτήτορας ≠ δράστης ⇒ ΞΕΝΟ (δογματική χαρτογράφηση)
                      (when (and owner-i
                                 (let ((ol (%entity* tokens owner-i)))
                                   (and (not (eq ol agent))
                                        (not (assoc (or (known-lemma owner-tok) "")
                                                    *markers* :test #'string=))
                                        (not (assoc (or (known-lemma owner-tok) "")
                                                    *verb-frames* :test #'string=)))))
                        (push (list :γεγονός theme :ανήκει-σε (%entity* tokens owner-i)) facts)
                        (push (list :γεγονός theme :είναι :ξένο) facts))
                      ;; ΕΠΙΘΕΤΑ της ονοματικής φράσης → κατηγορήματα κλάσης του θέματος
                      ;; («ξένα κινητά εργαλεία» ⇒ εργαλεία ∧ ξένο ∧ κινητό)
                      (dolist (mi np-mods)
                        (let* ((ml (known-lemma (nth mi tokens)))
                               (cls (and ml (cdr (assoc ml *adjectives* :test #'string=)))))
                          (when cls
                            (pushnew (list :γεγονός theme :είναι cls) facts :test #'equal))))
                      ;; δείκτες (σκοπός/τρόπος) οπουδήποτε → γεγονός ΔΡΑΣΤΗ
                      (dolist (tk tokens)
                        (let* ((l (known-lemma tk))
                               (m (and l (assoc l *markers* :test #'string=))))
                          (when m
                            (pushnew (list :γεγονός agent (second m) (third m)) facts
                                     :test #'equal))))
                      ;; ΠΟΛΥΛΕΚΤΙΚΟΙ όροι-τέχνης («νόμιμη άμυνα») → γεγονός ΔΡΑΣΤΗ,
                      ;; ανεξάρτητα από lemmatizer (τα concepts είναι φράσεις)
                      (dolist (f (%phrase-marker-facts tokens agent))
                        (pushnew f facts :test #'equal))))))))
            (values (nreverse facts) t))))))

(defparameter +definitional-markers+
  '("νοειται" "νοουνται" "θεωρειται" "θεωρουνται" "λογιζεται" "λογιζονται"
    "καλειται" "καλουνται" "ονομαζεται" "ονομαζονται")
  "Οι κλειστές ελληνικές ΟΡΙΣΤΙΚΕΣ διατυπώσεις του νόμου — η ΜΙΑ έδρα τους.")

(defun %def-entity (token)
  "Οντότητα ορισμού: λήμμα αν είναι γνωστό (ενικός, σωστός τόνος), αλλιώς η
   λέξη όπως στο κείμενο — ΔΗΛΩΜΕΝΑ ανεπιμέλητη· ο δημιουργός κρίνει στην
   έγκριση."
  (or (known-lemma token) (string-downcase token)))

(defun parse-definition (sentence term)
  "Από ΟΡΙΣΤΙΚΗ πρόταση νόμου («Γένος θεωρούνται (και) τα Είδη που…»):
   υποψήφια γεγονότα ταξινομίας (:γένος είδος γένος). Η δομή: το ΓΕΝΟΣ
   στην αντίθετη πλευρά του οριστικού ρήματος από το ΕΙΔΟΣ (τον όρο).
   ΔΗΛΩΜΕΝΟ ΟΡΙΟ: ονοματική φράση γένους ≤ 2 λέξεις περιεχομένου
   (προσδιορισμός+κεφαλή — γένος και διαφορά κατά τις Κατηγορίες)·
   επιπλέον δεσμός κεφαλής όταν η κεφαλή είναι γνωστό λήμμα.
   Επιστρέφει λίστα tuples με keywords — ΠΟΤΕ δεν υιοθετούνται χωρίς
   έγκριση του δημιουργού (Σ11)."
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
             ;; το γένος: η συστάδα λέξεων ΠΕΡΙΕΧΟΜΕΝΟΥ αμέσως δίπλα στο ρήμα,
             ;; στην αντίθετη πλευρά από τον όρο
             (genus-toks
               (if (> tpos vpos)
                   (let ((acc '()))   ; …Γ Γ ΡΗΜΑ … όρος → πίσω από το ρήμα
                     (loop for i downfrom (1- vpos) to 0
                           for tk = (nth i toks)
                           while (< (length acc) 2)
                           do (if (%content-token-p tk) (push tk acc) (return))
                           finally (return))
                     acc)
                   (let ((acc '()))   ; όρος … ΡΗΜΑ Γ Γ → μπροστά από το ρήμα
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
                 ;; Η ΔΙΑΦΟΡΑ: αναφορική «που ΡΗΜΑ ΥΠΟΚΕΙΜΕΝΟ» μετά τον όρο ⇒
                 ;; ο δεσμός γένους ισχύει ΥΠΟ ΟΡΟ (:γένος-όταν … κατηγόρημα τιμή).
                 ;; Κατηγόρημα: παθητικό σχήμα «-είται-από» από το λήμμα του
                 ;; ρήματος — ΔΗΛΩΜΕΝΑ σχηματικό· ο δημιουργός κρίνει στην έγκριση.
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
            ;; γένος και διαφορά: «ιδιωτικό-έγγραφο» ⊂ «έγγραφο» (αναλυτικός δεσμός)
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
  "Η ημερομηνία μιας πρότασης ως ISO «YYYY-MM-DD», ή nil. Μορφές: ISO,
   ΗΗ/ΜΜ/ΕΕΕΕ, ΗΗ-ΜΜ-ΕΕΕΕ, «ΗΗ Μηνός ΕΕΕΕ». ΔΗΛΩΜΕΝΟ όριο: όχι τελείες
   (10.01.2026) — η τελεία είναι όριο πρότασης. ΔΕΝ επικυρώνεται εδώ:
   την εγκυρότητα (2026-02-30;) την κρίνει ο ημερολογιακός λογισμός
   με το πιστοποιητικό του — μία έδρα επικύρωσης, όχι δύο."
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
  "(values γεγονότα μη-αναγνωσμένες-προτάσεις χρονολόγιο): κάθε πρόταση
   περνά από το πλαίσιο πτώσεων· ό,τι δεν αναγνωρίζεται ΔΗΛΩΝΕΤΑΙ. Το
   χρονολόγιο: (iso-ημερομηνία . πρόταση) για ΚΑΘΕ πρόταση με ημερομηνία —
   και τις αδιάβαστες (η χρονική θέση τους είναι γνώση, έστω κι αν η
   πράξη τους δεν διαβάστηκε ακόμη)."
  (let ((facts '()) (unparsed '()) (timeline '()))
    (dolist (s (%split-sentences text))
      (let ((d (%sentence-date s)))
        (when d (push (cons d s) timeline)))
      (multiple-value-bind (fs ok) (%parse-sentence (tokenize-greek s))
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
;;; «Όποιος ΡΗΜΑ [επίθετα…] ΟΥΣΙΑΣΤΙΚΟ … (με σκοπό να …) ΤΙΜΩΡΕΙΤΑΙ …»
;;; Το «όποιος» δένει καθολικό δράστη (?δράστης)· τα επίθετα της ονοματικής
;;; φράσης είναι κατηγορήματα του αντικειμένου (?πράγμα)· οι δείκτες σκοπού
;;; γεννούν γεγονός δράστη· το ρήμα κύρωσης δίνει την τροπικότητα.
;;; ΔΗΛΩΜΕΝΑ ΟΡΙΑ (α΄ κύμα): ένας δράστης/ένα αντικείμενο· λόγοι άρσης
;;; («εκτός αν…») ΔΕΝ διαβάζονται αυτόματα — δηλώνονται στον δημιουργό.

(defparameter +sanction-modality+
  '(("τιμωρειται" . :prohibition) ("τιμωρουνται" . :prohibition)
    ("υποχρεουται" . :obligation) ("υποχρεουνται" . :obligation)
    ("δικαιουται" . :permission)  ("δικαιουνται" . :permission))
  "Ρήμα κύρωσης → δεοντική τροπικότητα (κλειστή τάξη).")

(defun %strip-parentheticals (text)
  "Οι παρενθέσεις του νομοθέτη («ξένο (ολικά ή εν μέρει) κινητό») είναι
   παρεμβολές — αφαιρούνται ΔΗΛΩΜΕΝΑ πριν τη συντακτική ανάλυση (α΄ κύμα:
   δεν διαβάζονται, δεν σπάνε την ονοματική φράση)."
  (with-output-to-string (o)
    (let ((depth 0))
      (loop for ch across text
            do (cond ((char= ch #\() (incf depth))
                     ((char= ch #\)) (when (plusp depth) (decf depth)))
                     ((zerop depth) (write-char ch o)))))))

(defun parse-provision (text* &key heading)
  "(values spec|nil λόγος): SPEC = plist (:modality :antecedent :consequent
   :act :caveats) από τη σύνταξη «όποιος … κύρωση». Ό,τι δεν διαβάζεται,
   ΟΝΟΜΑΖΕΤΑΙ στον λόγο — ποτέ μισοδιαβασμένος κανόνας χωρίς δήλωση."
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
             ;; τρίτη τιμή: ο ΥΠΟΨΗΦΙΟΣ ρηματικός τύπος — ώστε η αυτο-μελέτη
             ;; να ΜΕΤΡΗΣΕΙ ποια ρήματα αξίζει να μάθει πρώτα
             (values nil "κανένα γνωστό ρήμα-πλαίσιο μετά το «όποιος» — χρειάζεται :frame στο πακέτο"
                     (loop for i from (1+ opos) below spos
                           for tk = (nth i toks)
                           when (%content-token-p tk)
                             return (normalize-greek tk)))
             (let ((cats '()) (head nil) (facts '()) (caveats '()))
               ;; ονοματική φράση αντικειμένου: επίθετα* + κεφαλή, έως δείκτη/κύρωση
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
               ;; δείκτες σκοπού/τρόπου σε ΟΛΟ το εύρος έως την κύρωση
               (loop for i from (1+ vpos) below spos
                     for l = (known-lemma (nth i toks))
                     for m = (and l (assoc l *markers* :test #'string=))
                     when m do (pushnew (list :γεγονός :?δράστης (second m) (third m))
                                        facts :test #'equal))
               ;; «εκτός αν» υπάρχει; ⇒ δηλωμένη εκκρεμότητα προς τον δημιουργό
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
  "Το όνομα της πράξης: το πρώτο λήμμα περιεχομένου του ΤΙΤΛΟΥ του άρθρου
   (πχ «Κλοπή»), αλλιώς από το κατηγόρημα του ρήματος."
  (or (and heading
           (loop for tk in (tokenize-greek heading)
                 for l = (known-lemma tk)
                 when (and l (content-lemma-p l)
                           (not (member (normalize-greek l) '("αρθρο") :test #'string=)))
                   return (intern (string-upcase l) :keyword)))
      (intern (string-upcase (format nil "πράξη-~A" pred)) :keyword)))
