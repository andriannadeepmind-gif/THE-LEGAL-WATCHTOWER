;;;; source/legal-casegrammar.lisp
;;;; ============================================================================
;;;; Σ4β — ΓΡΑΜΜΑΤΙΚΗ ΣΥΣΤΑΤΙΚΩΝ (feature grammar): από ΑΦΗΓΗΣΗ σε γεγονότα
;;;; ============================================================================
;;;;
;;;; Η υπαγωγή (Σ4) δέχεται γεγονότα-tuples· εδώ χτίζεται η γέφυρα από τα φυσικά
;;;; ελληνικά. Η ανάθεση ρόλων ΔΕΝ γίνεται με ευρετικές (article-heuristics) ούτε με
;;;; exact-substring (MWE) — ΑΥΤΑ ΗΤΑΝ ΜΠΑΛΩΜΑΤΑ γύρω από την απουσία έδρας
;;;; «συστατικού». Εδώ: αναγνώριση ΟΝΟΜΑΤΙΚΩΝ ΦΡΑΣΕΩΝ ως ΣΥΣΤΑΤΙΚΑ με ΣΥΜΦΩΝΙΑ
;;;; πτώσης/αριθμού/γένους (μέσω της έδρας μορφολογίας-χαρακτηριστικών
;;;; orchestrator.citation-authority:morph-analyze). Η πτώση δίνει τον ρόλο δομικά:
;;;; ονομαστική=δράστης, αιτιατική=θέμα, γενική=κτήτορας. Η ουδέτερη αμφισημία
;;;; (το/τα = ονομ.=αιτ.) αίρεται με ΑΠΟΚΛΕΙΣΜΟ στην πρόταση (αν ο δράστης είναι
;;;; μονοσήμαντα ονομαστικός, το αμφίσημο ουδέτερο ΕΙΝΑΙ το αντικείμενο). Τα
;;;; αντικείμενα προθέσεων (PP) είναι ΠΛΑΓΙΑ, όχι πυρηνικά ορίσματα — έτσι το
;;;; μεταγενέστερο πλάγιο αιτιατικό ΔΕΝ κλέβει το θέμα ΔΟΜΙΚΑ. Οι νομικοί όροι-τέχνης
;;;; («νόμιμη άμυνα») είναι ΝΡ των οποίων η κεφαλή+επίθετα ταιριάζουν σε ΛΗΜΜΑΤΑ
;;;; (γενίκευση στην κλίση) — όχι σε επιφανειακή ακολουθία.
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
                #:surface-stem
                #:morph-analyze #:morph-lemma #:feat-case #:feat-number #:feat-gender
                #:+negators+)
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
  "λίστα ((head-lemma . sorted-adj-lemmas) pred value): ΝΟΜΙΚΟΙ ΟΡΟΙ-ΤΕΧΝΗΣ ως
   ΣΥΣΤΑΤΙΚΑ — «νόμιμη άμυνα» = ΝΡ με κεφαλή-λήμμα «άμυνα» + επίθετο-λήμμα «νόμιμος».
   Κλειδωμένο σε ΛΗΜΜΑΤΑ (μέσω morph-analyze) ⇒ ΓΕΝΙΚΕΥΕΙ στην κλίση: «νόμιμης
   άμυνας» ≡ «νόμιμη άμυνα». Αντικαθιστά το exact-substring MWE (που ΗΤΑΝ μπάλωμα:
   δεν γενίκευε, [0076] verify). Η άρνηση («χωρίς»/«δεν») ρέει από τη ΔΟΜΗ (PP
   αποκλεισμού / clause negation), όχι από ad-hoc look-back.")

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

(defun %split-clauses (sentence)
  "Τμήματα πρότασης στα κόμματα — ΚΑΘΕ κόμμα ορίζει όριο πρότασης/παρενθετικού
   (η κύρια SVO πρόταση + επιρρηματικές/μετοχικές «ενώ …», «δεν …»)."
  (let ((out '()) (start 0))
    (loop for i below (length sentence)
          when (char= (char sentence i) #\,)
            do (push (subseq sentence start i) out) (setf start (1+ i)))
    (push (subseq sentence start) out)
    (mapcar (lambda (s) (string-trim " " s)) (nreverse out))))

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
   αθώωση) — δομικά ένα PP που c-command-άρει τον όρο.")

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
  "normalize(άρθρο) → σύνολο πτώσεων. Τα ουδέτερα «το/τα» φέρουν {nom,acc}: η
   αμφισημία αίρεται δομικά στην πρόταση (αποκλεισμός), όχι με ευρετική.")

;;; ── Λεξική ταξινόμηση ──
(defun %morph-lemma (surface)
  "Λήμμα από τη μορφολογία-χαρακτηριστικών αν είναι μονοσήμαντο, αλλιώς από το
   λεξικό known-lemma, αλλιώς nil. ΓΙΑ ΤΑΙΡΙΑΣΜΑ (concepts/noun-class/adj) — ΟΧΙ για
   ονοματοδοσία (εκείνη μένει %entity*)."
  (let ((m (morph-lemma surface)))
    (if (stringp m) m (known-lemma surface))))

(defparameter *concept-adj-lemmas* '()
  "Cache: όλα τα επίθετα-λήμματα που εμφανίζονται σε *concepts* — ώστε να
   αναγνωρίζονται δομικά ως επίθετα ακόμη κι αν δεν φέρουν κατηγορία στο *adjectives*.")
(defun %refresh-concept-adjs ()
  (setf *concept-adj-lemmas*
        (remove-duplicates (loop for (key pred value) in *concepts* append (cdr key))
                           :test #'string=)))
(defun %adj-lemma-p (lemma)
  (and lemma (or (assoc lemma *adjectives* :test #'string=)
                 (member lemma *concept-adj-lemmas* :test #'string=))))

(defun %morph-cases (surface)
  "Σύνολο πιθανών πτώσεων του τύπου από τη μορφολογία, ή nil (άγνωστο)."
  (let ((rds (morph-analyze surface)))
    (when rds (remove-duplicates (mapcar (lambda (h) (feat-case (cdr h))) rds)))))

(defun %classify (surface)
  "Λεξικό cell: όλες οι λειτουργικές/λεξικές ιδιότητες του τύπου (context-free)."
  (let* ((n (normalize-greek surface))
         (art (gethash n *article-table*))
         (lem (%morph-lemma surface))
         (verb (and lem (cdr (assoc lem *verb-frames* :test #'string=))))
         (pos (cond ((%adj-lemma-p lem) :adj)
                    (verb :verb)
                    ((or (and lem (assoc lem *noun-classes* :test #'string=))
                         (%content-token-p surface)) :noun)
                    (t nil))))
    (list :surface surface :norm n :art art :lemma lem :pos pos :verb verb
          :prep (and (member n +prepositions+ :key #'normalize-greek :test #'string=) t)
          :negprep (and (member n +phrase-negators+ :key #'normalize-greek :test #'string=) t)
          :negpart (and (member n +negators+ :test #'string=) t)   ; ΜΙΑ έδρα άρνησης
          :cases (or art (%morph-cases surface)))))

;;; ── Ονοματική φράση ως ΣΥΣΤΑΤΙΚΟ (Det? Adj* Head) με ΣΥΜΦΩΝΙΑ πτώσης ──
(defstruct np head-index head-lemma adj-lemmas adj-classes cases start end oblique owner)

(defun %intersect-cases (a b) (if (and a b) (intersection a b) (or a b)))

(defun %parse-np (cells i)
  "(values np next-index) ή nil: Det? Adj* Head. Πτώση = ΤΟΜΗ των γνωστών συνόλων
   πτώσης (Det+επίθετα+κεφαλή) = ΣΥΜΦΩΝΙΑ. Head-index = απόλυτη θέση της κεφαλής.
   Το oblique το ορίζει ο καλών (%parse-nps) — ΜΙΑ πηγή αλήθειας."
  (let ((j i) (cases nil) (adjl '()) (adjc '()) (head-i nil) (found nil))
    (let ((c (nth j cells)))                                   ; Det
      (when (getf c :art) (setf cases (getf c :cases)) (incf j)))
    (loop for c = (nth j cells)                                ; Adj*
          while (and c (eq (getf c :pos) :adj))
          do (push (getf c :lemma) adjl)
             (let ((ac (cdr (assoc (getf c :lemma) *adjectives* :test #'string=))))
               (when ac (push ac adjc)))
             (setf cases (%intersect-cases cases (getf c :cases)))
             (incf j))
    (let ((c (nth j cells)))                                   ; Head (nominal)
      (when (and c (or (eq (getf c :pos) :noun)
                       (and (null (getf c :art)) (not (getf c :prep))
                            (not (getf c :verb)) (not (getf c :negpart))
                            (getf c :lemma))))
        (setf head-i j found t cases (%intersect-cases cases (getf c :cases)))
        (incf j)))
    (when found
      (values (make-np :head-index head-i :head-lemma (getf (nth head-i cells) :lemma)
                       :adj-lemmas (nreverse adjl) :adj-classes (nreverse adjc)
                       :cases (or cases '(:nom :acc :gen)) :start i :end j
                       :oblique nil :owner nil)
              j))))

(defun %parse-nps (cells)
  "Όλα τα NP: σήμανση oblique (αντικείμενο πρόθεσης) + σύνδεση κτήτορα (post-head
   γενική ΧΩΡΙΣ κυβερνώσα πρόθεση) στο προηγούμενο NP."
  (let ((nps '()) (i 0) (n (length cells)) (prep-before nil) (seen-prep nil))
    (loop while (< i n) for c = (nth i cells) do
      (cond
        ((getf c :prep) (setf prep-before (getf c :norm) seen-prep t) (incf i))
        (t (multiple-value-bind (np j) (%parse-np cells i)
             (cond
               (np
                ;; oblique = υπό πρόθεση ΚΑΙ όχι καθαρά ονομαστικό: το υποκείμενο
                ;; (ονομαστική) ΔΕΝ είναι ποτέ αντικείμενο πρόθεσης — «…με δόλο ο
                ;; δράστης» ⇒ ο δράστης πυρηνικός (OVS), όχι μέρος του PP.
                (setf (np-oblique np) (and seen-prep (not (equal (np-cases np) '(:nom)))))
                (if (and nps (null prep-before) (equal (np-cases np) '(:gen)))
                    (setf (np-owner (first nps)) np)     ; κτήτορας post-head, όχι PP
                    (push np nps))
                (setf prep-before nil i j))
               (t (setf prep-before nil i (1+ i))))))))
    (nreverse nps)))

;;; ── Ρόλοι από ΠΤΩΣΗ (μόνο πυρηνικά NP· δομική άρση ουδέτερης αμφισημίας) ──
(defun %pure (np cse) (equal (np-cases np) (list cse)))
(defun %ambiguous-na (np) (and (member :nom (np-cases np)) (member :acc (np-cases np))))
(defun %assign-roles (core-nps)
  "(values agent theme): agent = καθαρό nom (αλλιώς αμφίσημο)· theme = καθαρό acc
   (αλλιώς το εναπομείναν αμφίσημο). «ο δράστης»(nom)+«τα εργαλεία»(nom/acc) ⇒
   theme=εργαλεία ΔΟΜΙΚΑ (αποκλεισμός), χωρίς καμία θέση-ευρετική."
  (let* ((agent (or (find-if (lambda (x) (%pure x :nom)) core-nps)
                    (find-if #'%ambiguous-na core-nps)))
         (theme (or (find-if (lambda (x) (%pure x :acc)) core-nps)
                    (find-if (lambda (x) (and (not (eq x agent)) (%ambiguous-na x))) core-nps))))
    (values agent theme)))

;;; ── Άρνηση όρου (concept) από τη ΔΟΜΗ ──
(defun %clause-negated-p (cells) (some (lambda (c) (getf c :negpart)) cells))
(defun %np-term-negated (np cells)
  "Ο όρος αναιρείται αν (α) το NP είναι αντικείμενο neg-prep (χωρίς/δίχως) ή (β)
   υπάρχει δείκτης άρνησης ΠΡΙΝ το NP στην ΙΔΙΑ πρόταση (clause negation)."
  (let ((s (np-start np)))
    (or (and (> s 0) (getf (nth (1- s) cells) :negprep))
        (loop for k below s thereis (getf (nth k cells) :negpart)))))

(defun %concept-fact (np agent)
  "Γεγονός ΔΡΑΣΤΗ αν (κεφαλή-λήμμα . ταξιν-επίθετα-λήμματα) ταιριάζει concept."
  (let ((key (cons (np-head-lemma np) (sort (copy-list (np-adj-lemmas np)) #'string<))))
    (loop for (ckey pred value) in *concepts*
          when (equal ckey key) return (list :γεγονός agent pred value))))

;;; ── Ανάλυση ΠΡΟΤΑΣΗΣ: κάθε clause είναι μια ΚΑΤΗΓΟΡΗΣΗ (predication) ──
;;; ΤΟ ΜΟΝΤΕΛΟ (θάνατος 2 regressions ταυτόχρονα, χωρίς μπάλωμα):
;;;   · clause ΜΕ ρήμα-πλαίσιο = αυτοτελής κατήγορηση: δικό της SVO, δικός της
;;;     δράστης (own ονομαστική· αλλιώς pro-drop ο κύριος δράστης), δική της
;;;     πολικότητα. ⇒ «…, και ο συνεργός θανάτωσε …» ΚΡΑΤΑ και τη 2η πράξη
;;;     (το single-main-SVO την ΕΧΑΝΕ — regression που εισήχθη & πέθανε εδώ).
;;;   · clause ΧΩΡΙΣ ρήμα = ΠΡΟΣΔΙΟΡΙΣΜΟΣ (adjunct): markers/concepts του
;;;     προσαρτώνται στην ΚΥΒΕΡΝΩΣΑ κατήγορηση και ΚΛΗΡΟΝΟΜΟΥΝ την πολικότητά
;;;     της. ⇒ «δεν αφαίρεσε …, με σκοπό …» ΔΕΝ εφευρίσκει σκοπό (κύρια άρνηση)·
;;;     «αφαίρεσε …, με δόλο» ΚΡΑΤΑ τον δόλο. Η άρνηση ΟΡΟΥ (χωρίς/δεν εντός
;;;     ΤΗΣ clause του όρου) παραμένει επιπρόσθετα per-clause.
(defun %clause-derived (p agent negated facts)
  "Παράγωγα γεγονότα ΜΙΑΣ clause με δεδομένο δράστη+πολικότητα: markers (στον
   δράστη) + concepts (σε κάθε NP/owner), ΟΛΑ κατεσταλμένα αν NEGATED· τα concepts
   επιπλέον per-clause αν ο ΟΡΟΣ αναιρείται τοπικά. Επιστρέφει το επαυξημένο FACTS."
  (when (and agent (not negated))
    (let ((cells (getf p :cells)))
      (dolist (c cells)                                   ; markers → δράστης
        (let ((m (and (getf c :lemma) (assoc (getf c :lemma) *markers* :test #'string=))))
          (when m (pushnew (list :γεγονός agent (second m) (third m)) facts :test #'equal))))
      (dolist (np (append (getf p :nps)                   ; concepts → NP (+owners)
                          (remove nil (mapcar #'np-owner (getf p :nps)))))
        (unless (%np-term-negated np cells)
          (let ((cf (%concept-fact np agent)))
            (when cf (pushnew cf facts :test #'equal)))))))
  facts)

(defun %parse-sentence (sentence)
  "(values γεγονότα αναγνωρίστηκε-p): συστατική ανάλυση ανά clause. Κάθε clause με
   ρήμα-πλαίσιο = αυτοτελής SVO κατήγορηση (own/pro-drop δράστης, own πολικότητα)·
   οι verb-less προσδιορισμοί κληρονομούν δράστη+πολικότητα της κυβερνώσας."
  (%refresh-concept-adjs)
  (let* ((parsed (loop for cl in (%split-clauses sentence)
                       when (plusp (length cl))
                         collect (let* ((toks (tokenize-greek cl))
                                        (cells (mapcar #'%classify toks)))
                                   (list :tokens toks :cells cells
                                         :nps (%parse-nps cells)
                                         :vpos (position-if (lambda (c) (getf c :verb)) cells)))))
         (facts '())
         (main-agent nil) (main-neg nil))
    ;; ── ΚΥΡΙΑ κατήγορηση = η ΠΡΩΤΗ verb-clause: πηγή pro-drop + πολικότητα για
    ;;    προσδιορισμούς ΠΡΙΝ εμφανιστεί ρήμα (π.χ. «Σε βρασμό …, τον θανάτωσε …») ──
    (let ((first-vc (find-if (lambda (p) (getf p :vpos)) parsed)))
      (when first-vc
        (setf main-neg (%clause-negated-p (getf first-vc :cells)))
        (let ((core (remove-if (lambda (np) (or (np-oblique np) (equal (np-cases np) '(:gen))))
                               (getf first-vc :nps))))
          (multiple-value-bind (ag th) (%assign-roles core)
            (declare (ignore th))
            (when ag (setf main-agent (%entity* (getf first-vc :tokens) (np-head-index ag))))))))
    ;; ── Δεύτερο πέρασμα: κάθε clause στη σειρά, με τρέχον context (δράστης/πολικότητα) ──
    (let ((ctx-agent main-agent) (ctx-neg main-neg))
      (dolist (p parsed)
        (let ((tokens (getf p :tokens)) (cells (getf p :cells)) (vpos (getf p :vpos)))
          (if vpos
              ;; ── ΚΑΤΗΓΟΡΗΣΗ: SVO με δικό της δράστη + πολικότητα ──
              (let* ((pred (getf (nth vpos cells) :verb))
                     (negated (%clause-negated-p cells))
                     (core (remove-if (lambda (np) (or (np-oblique np) (equal (np-cases np) '(:gen))))
                                      (getf p :nps))))
                (multiple-value-bind (ag th) (%assign-roles core)
                  ;; pro-drop: αν η clause δεν έχει δική της ονομαστική, κληρονομεί τον
                  ;; ΤΡΕΧΟΝΤΑ δράστη (running agent — ξεκινά από τον κύριο) — ίδιο threading με [0079].
                  (let ((agent (if ag (%entity* tokens (np-head-index ag)) ctx-agent)))
                    (setf ctx-agent agent ctx-neg negated)   ; context για τους επόμενους adjuncts
                    (when (and agent th)
                      (let ((themek (%entity* tokens (np-head-index th))))
                        (if negated
                            (push (list :άρνηση agent pred themek) facts)  ; τίμια άρνηση
                            (progn
                              (push (list :γεγονός agent pred themek) facts)
                              (let ((hc (cdr (assoc (np-head-lemma th) *noun-classes* :test #'string=))))
                                (when hc (pushnew (list :γεγονός themek :είναι hc) facts :test #'equal)))
                              (dolist (ac (np-adj-classes th))
                                (pushnew (list :γεγονός themek :είναι ac) facts :test #'equal))
                              (when (np-owner th)
                                (let ((ok (%entity* tokens (np-head-index (np-owner th)))))
                                  (unless (eq ok agent)
                                    (pushnew (list :γεγονός themek :ανήκει-σε ok) facts :test #'equal)
                                    (pushnew (list :γεγονός themek :είναι :ξένο) facts :test #'equal))))))))
                    ;; markers/concepts ΤΗΣ ΙΔΙΑΣ clause → στον δράστη της (κατεσταλμένα αν αρνείται)
                    (setf facts (%clause-derived p agent negated facts)))))
              ;; ── ΠΡΟΣΔΙΟΡΙΣΜΟΣ (verb-less): κληρονομεί δράστη+πολικότητα της κυβερνώσας ──
              (setf facts (%clause-derived p ctx-agent ctx-neg facts))))))
    ;; αναγνωρίστηκε ⇔ υπάρχει clause με ρήμα-πλαίσιο (ίδια σημασιολογία με το [0079])
    (values (nreverse facts) (and (find-if (lambda (p) (getf p :vpos)) parsed) t))))

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
   γραμματική συστατικών· ό,τι δεν αναγνωρίζεται ΔΗΛΩΝΕΤΑΙ. Το χρονολόγιο:
   (iso-ημερομηνία . πρόταση) για ΚΑΘΕ πρόταση με ημερομηνία."
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
