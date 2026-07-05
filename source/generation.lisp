;;;; source/generation.lisp
;;;; ============================================================================
;;;; Η ΓΕΝΕΣΗ ΛΟΓΟΥ — το σύστημα ΜΙΛΑΕΙ: συνθέτει, δεν ανασύρει
;;;; ============================================================================
;;;;
;;;; Ο καθρέφτης της κατανόησης. Όπως η κατανόηση πάει κείμενο → λήμματα →
;;;; έννοιες (ποτέ ταίριασμα γραμμάτων), η ομιλία πάει ΓΝΩΣΗ → δομή μηνύματος →
;;;; ελληνική πρόταση — ποτέ αποθηκευμένη φράση. Το ΠΕΡΙΕΧΟΜΕΝΟ έρχεται από τον
;;;; γράφο/τις αποδείξεις/τις μετρήσεις τη στιγμή της ερώτησης· η ΜΟΡΦΗ από
;;;; γραμματική: κλιτικά παραδείγματα, συμφωνία γένους/αριθμού/πτώσης, άρθρα,
;;;; αριθμητικά, τελικό-ν. Όλα ΚΛΕΙΣΤΕΣ κλάσεις της ελληνικής — πεπερασμένες,
;;;; τεκμηριωμένες, όχι λίστες απαντήσεων.
;;;;
;;;; ΕΝΑ ΛΕΞΙΚΟ, ΔΥΟ ΚΑΤΕΥΘΥΝΣΕΙΣ: το DEFINE-NOUN δηλώνει το παράδειγμα ΜΙΑ
;;;; φορά — η γένεση κλίνει από αυτό, ΚΑΙ οι μορφές του τροφοδοτούν αυτόματα
;;;; το λεξικό κατανόησης (add-lemma-forms). Ό,τι μαθαίνει να λέει, ήδη το
;;;; καταλαβαίνει — και αντίστροφα. Καμία δεύτερη γλωσσική αλήθεια.

(defpackage :orchestrator.generation
  (:use :cl)
  (:export #:define-noun #:np #:pp-se #:count-np #:vp #:sentence #:enumerate-clauses
           #:noun-form #:noun-gender #:*generation-lexicon*))

(in-package :orchestrator.generation)

;;; ============================================================================
;;; ΚΛΙΤΙΚΑ ΠΑΡΑΔΕΙΓΜΑΤΑ — οι κλειστές κλάσεις της ελληνικής ονοματικής κλίσης
;;; ============================================================================
;;; καταλήξεις ανά (πτώση × αριθμό): (nom-sg gen-sg acc-sg nom-pl gen-pl acc-pl)

;;; Κάθε κελί: (κατάληξη . θέμα-κλειδί)· :s = βασικό θέμα, :s2 = θέμα με
;;; ΚΑΤΕΒΑΣΜΕΝΟ τόνο (παραδοσιακή γραμματική: συζύγου, αποφάσεων, ανθρώπους) —
;;; η μετακίνηση του τόνου ΔΕΝ παραλείπεται.
(defparameter +declensions+
  '((:m-os . (("ος" . :s) ("ου" . :s2) ("ο" . :s) ("οι" . :s) ("ων" . :s2) ("ους" . :s2)))
    (:m-as . (("ας" . :s) ("α" . :s) ("α" . :s) ("ες" . :s) ("ων" . :s2) ("ες" . :s)))
    (:m-is . (("ής" . :s) ("ή" . :s) ("ή" . :s) ("ές" . :s) ("ών" . :s) ("ές" . :s)))
    (:f-a  . (("α" . :s) ("ας" . :s) ("α" . :s) ("ες" . :s) ("ων" . :s2) ("ες" . :s)))
    (:f-i  . (("η" . :s) ("ης" . :s) ("η" . :s) ("ες" . :s) ("ων" . :s2) ("ες" . :s)))
    (:f-si . (("η" . :s) ("ης" . :s) ("η" . :s) ("εις" . :s2) ("εων" . :s2) ("εις" . :s2)))
    (:n-o  . (("ο" . :s) ("ου" . :s2) ("ο" . :s) ("α" . :s) ("ων" . :s2) ("α" . :s)))
    (:n-i  . (("ί" . :s) ("ιού" . :s) ("ί" . :s) ("ιά" . :s) ("ιών" . :s) ("ιά" . :s)))
    (:n-ma . (("μα" . :s) ("ματος" . :s2) ("μα" . :s) ("ματα" . :s2) ("μάτων" . :s2) ("ματα" . :s2))))
  "Οι κλιτικές κλάσεις της ονοματικής κλίσης — κλειστό σύστημα της γλώσσας.
   Το γένος δηλώνεται χωριστά: η ίδια κλάση -ος κλίνει «ο δικηγόρος» ΚΑΙ «η σύζυγος».")

(defparameter *generation-lexicon* (make-hash-table :test 'equal)
  "λήμμα → plist (:gender :decl :stem :stem2) — η ΜΙΑ δήλωση κάθε λέξης.")

(defun define-noun (lemma gender decl stem &key stem2)
  "Δήλωσε ουσιαστικό ΜΙΑ φορά: κλίνεται για τη γένεση ΚΑΙ οι μορφές του
   τροφοδοτούν αυτόματα το λεξικό κατανόησης — μία γλωσσική αλήθεια, δύο
   κατευθύνσεις. STEM2: το θέμα με κατεβασμένο τόνο, όπου η παραδοσιακή
   γραμματική τον μετακινεί (σύζυγ-ος → συζύγ-ου, απόφασ-η → αποφάσ-εων)."
  (setf (gethash lemma *generation-lexicon*)
        (list :gender gender :decl decl :stem stem :stem2 (or stem2 stem)))
  ;; τροφοδότησε την ΚΑΤΑΝΟΗΣΗ με όλες τις μορφές που θα μπορεί να ΠΕΙ
  (orchestrator.citation-authority:add-lemma-forms
   lemma
   (loop for case in '(:nom :gen :acc)
         append (loop for number in '(:sg :pl)
                      collect (noun-form lemma case number))))
  lemma)

(defun noun-form (lemma case number)
  "Η μορφή του LEMMA στην πτώση CASE (:nom/:gen/:acc) και αριθμό NUMBER (:sg/:pl)."
  (let ((e (gethash lemma *generation-lexicon*)))
    (unless e (error "άγνωστο λήμμα στη γένεση: ~A — δήλωσέ το με DEFINE-NOUN" lemma))
    (let* ((cells (cdr (assoc (getf e :decl) +declensions+)))
           (idx (+ (ecase case (:nom 0) (:gen 1) (:acc 2))
                   (ecase number (:sg 0) (:pl 3))))
           (cell (nth idx cells))
           (stem (if (eq (cdr cell) :s2) (getf e :stem2) (getf e :stem))))
      (concatenate 'string stem (car cell)))))

(defun %gender (lemma)
  (getf (or (gethash lemma *generation-lexicon*)
            (error "άγνωστο λήμμα: ~A" lemma))
        :gender))

(defun noun-gender (lemma)
  "Το γένος του λήμματος, αν είναι δηλωμένο στη γένεση (αλλιώς nil)."
  (let ((e (gethash lemma *generation-lexicon*))) (and e (getf e :gender))))

;;; ── Άρθρα (κλειστός πίνακας) — Ο ΚΑΝΟΝΑΣ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ για το τελικό ν:
;;; στο «τον/την/στον/στην» το ν διατηρείται ΠΑΝΤΑ. Η πτώση του («στη σύζυγο»,
;;; «το δικηγόρο») είναι το νεοελληνικό λάθος που ο δημιουργός απορρίπτει ρητά —
;;; εδώ γράφεται η ορθή, πλήρης μορφή: στον δικηγόρο, στην σύζυγο, στο παιδί.

(defun %article (gender case number)
  (ecase gender
    (:m (ecase number
          (:sg (ecase case (:nom "ο") (:gen "του") (:acc "τον")))
          (:pl (ecase case (:nom "οι") (:gen "των") (:acc "τους")))))
    (:f (ecase number
          (:sg (ecase case (:nom "η") (:gen "της") (:acc "την")))
          (:pl (ecase case (:nom "οι") (:gen "των") (:acc "τις")))))
    (:n (ecase number
          (:sg (ecase case (:nom "το") (:gen "του") (:acc "το")))
          (:pl (ecase case (:nom "τα") (:gen "των") (:acc "τα")))))))

;;; ── Αριθμητικά με συμφωνία γένους (1, 3, 4 κλίνονται — κλειστός κανόνας) ──

(defun %numeral (n gender)
  (case n
    (1 (ecase gender (:m "ένας") (:f "μία") (:n "ένα")))
    (3 (ecase gender ((:m :f) "τρεις") (:n "τρία")))
    (4 (ecase gender ((:m :f) "τέσσερις") (:n "τέσσερα")))
    (t (format nil "~D" n))))

;;; ============================================================================
;;; ΠΡΑΓΜΑΤΩΣΗ — ονοματικές φράσεις, ρηματικές, προτάσεις
;;; ============================================================================

(defun np (lemma &key (case :nom) (number :sg) (definite t))
  "Ονοματική φράση με συμφωνία: (np \"νόμος\" :case :acc) → «τον νόμο»."
  (let ((noun (noun-form lemma case number)))
    (if definite
        (format nil "~A ~A" (%article (%gender lemma) case number) noun)
        noun)))

(defun pp-se (lemma &key (number :sg))
  "Εμπρόθετη «σε + αιτιατική» με συναίρεση — και το τελικό ν ΠΑΝΤΑ στη θέση του:
   (pp-se \"δικηγόρος\") → «στον δικηγόρο» · (pp-se \"σύζυγος\") → «στην σύζυγο» ·
   (pp-se \"παιδί\") → «στο παιδί»."
  (let* ((g (%gender lemma))
         (contr (ecase g
                  (:m (if (eq number :pl) "στους" "στον"))
                  (:f (if (eq number :pl) "στις" "στην"))
                  (:n (if (eq number :pl) "στα" "στο")))))
    (format nil "~A ~A" contr (noun-form lemma :acc number))))

(defun count-np (n lemma &key (case :nom))
  "Μετρημένη ΟΦ με πλήρη συμφωνία: (count-np 3 \"απόφαση\") → «τρεις αποφάσεις»,
   (count-np 1 \"άρθρο\") → «ένα άρθρο», (count-np 12 \"άρθρο\") → «12 άρθρα»."
  (let ((number (if (= n 1) :sg :pl)))
    (format nil "~A ~A" (%numeral n (%gender lemma)) (noun-form lemma case number))))

(defparameter +verbs-3+
  '(("παραπέμπω"    . ("παραπέμπει" . "παραπέμπουν"))
    ("εφαρμόζω"     . ("εφάρμοσε"   . "εφάρμοσαν"))
    ("ορίζω"        . ("ορίζει"     . "ορίζουν"))
    ("κατονομάζω"   . ("κατονομάζει" . "κατονομάζουν"))
    ("ρυθμίζω"      . ("ρυθμίζει"   . "ρυθμίζουν"))
    ("μνημονεύω"    . ("μνημονεύει" . "μνημονεύουν"))
    ("υπάρχω"       . ("υπάρχει"    . "υπάρχουν"))
    ("εκκρεμώ"      . ("εκκρεμεί"   . "εκκρεμούν"))
    ("περιλαμβάνω"  . ("περιλαμβάνει" . "περιλαμβάνουν")))
  "Γ' πρόσωπο (εν./πληθ.) των ρημάτων σύνθεσης — δηλωμένοι τύποι, όχι κανόνες.")

(defun vp (verb-lemma number)
  "Ρήμα γ' προσώπου σε συμφωνία αριθμού."
  (let ((v (cdr (assoc verb-lemma +verbs-3+ :test #'string=))))
    (unless v (error "άγνωστο ρήμα στη γένεση: ~A" verb-lemma))
    (if (eq number :pl) (cdr v) (car v))))

(defun sentence (&rest parts)
  "Πρόταση από μέρη (κενά ρυθμίζονται, κεφαλαίο πρώτο, τελεία στο τέλος)."
  (let ((s (string-trim " " (format nil "~{~@[~A ~]~}" parts))))
    (when (plusp (length s))
      (setf (char s 0) (char-upcase (char s 0))))
    (concatenate 'string (string-right-trim " " s) ".")))

(defun enumerate-clauses (clauses)
  "Σύνδεση προτάσεων-μελών με «και» πριν το τελευταίο: (α, β και γ)."
  (let ((cs (remove nil clauses)))
    (case (length cs)
      (0 nil)
      (1 (first cs))
      (t (format nil "~{~A~^, ~} και ~A"
                 (butlast cs) (car (last cs)))))))

;;; ── Ο πυρήνας του νομικού λεξιλογίου: ΜΙΑ δήλωση ανά λέξη, με τη μετακίνηση
;;; του τόνου δηλωμένη όπου τη θέλει η παραδοσιακή γραμματική ──
(define-noun "νόμος"     :m :m-os "νόμ")
(define-noun "δικηγόρος" :m :m-os "δικηγόρ")
(define-noun "σύζυγος"   :f :m-os "σύζυγ"   :stem2 "συζύγ")     ; η σύζυγος, της συζύγου
(define-noun "κώδικας"   :m :m-as "κώδικ"   :stem2 "κωδίκ")     ; των κωδίκων
(define-noun "κανόνας"   :m :m-as "κανόν")
(define-noun "δικαστής"  :m :m-is "δικαστ")
(define-noun "απόφαση"   :f :f-si "απόφασ"  :stem2 "αποφάσ")
(define-noun "διάταξη"   :f :f-si "διάταξ"  :stem2 "διατάξ")
(define-noun "πρόθεση"   :f :f-si "πρόθεσ"  :stem2 "προθέσ")
(define-noun "παραπομπή" :f :f-i  "παραπομπ")
(define-noun "άρθρο"     :n :n-o  "άρθρ")
(define-noun "έθιμο"     :n :n-o  "έθιμ"    :stem2 "εθίμ")      ; των εθίμων
(define-noun "δίκαιο"    :n :n-o  "δίκαι"   :stem2 "δικαί")     ; του δικαίου
(define-noun "επεισόδιο" :n :n-o  "επεισόδι" :stem2 "επεισοδί") ; των επεισοδίων
(define-noun "παιδί"     :n :n-i  "παιδ")

;;; ============================================================================
;;; ΤΟ ΛΕΞΙΛΟΓΙΟ ΩΣ ΓΝΩΣΗ (Φάση 4) — πακέτο :lexicon, όχι επαναμεταγλώττιση
;;; ============================================================================
;;;
;;; Νέο λεξιλόγιο = ΔΗΛΩΣΗ σε αρχείο (deployment/knowledge/*.sexp), υπό το ίδιο
;;; επιστημικό καθεστώς με τον νόμο (SHA ταυτότητα, ζωντανή φόρτωση, σκιώδης
;;; εκτέλεση). Εδώ είναι η πόρτα από την οποία θα περάσει και ολόκληρο
;;; μορφολογικό λεξικό (δεκάδες χιλιάδες λήμματα) — ίδιο σχήμα, καμία αλλαγή:
;;;   (:noun ΛΗΜΜΑ ΓΕΝΟΣ ΚΛΑΣΗ ΘΕΜΑ [ΘΕΜΑ2])  ⇒ define-noun: κλίνεται για τη
;;;       ΓΕΝΕΣΗ και όλες οι μορφές του τροφοδοτούν την ΚΑΤΑΝΟΗΣΗ (μία δήλωση,
;;;       δύο κατευθύνσεις)· το ΘΕΜΑ2 (κατεβασμένος τόνος) ΔΕΝ παραλείπεται.
;;;   (:lemma ΛΗΜΜΑ (ΜΟΡΦΕΣ…))  ⇒ add-lemma-forms: μόνο κατανόηση — για λέξεις
;;;       που δεν χωρούν στα κλιτικά πρότυπα (οξύτονα θηλυκά, -μα ουδέτερα,
;;;       ρήματα) οι μορφές δηλώνονται ΡΗΤΑ, ποτέ μισοσωστές.

(defun %lexicon-gen-snapshot ()
  (let ((copy (make-hash-table :test 'equal)))
    (maphash (lambda (k v) (setf (gethash k copy) v)) *generation-lexicon*)
    copy))

(defun %lexicon-gen-restore (snap)
  (clrhash *generation-lexicon*)
  (maphash (lambda (k v) (setf (gethash k *generation-lexicon*) v)) snap))

(orchestrator.knowledge-packs:define-knowledge-kind :lexicon
 :doc "Λεξιλόγιο: (:noun ΛΗΜΜΑ ΓΕΝΟΣ ΚΛΑΣΗ ΘΕΜΑ [ΘΕΜΑ2]) → γένεση+κατανόηση ·
 (:lemma ΛΗΜΜΑ (ΜΟΡΦΕΣ…)) → κατανόηση με ρητές μορφές."
 :install
 (lambda (entries)
   (dolist (e entries)
     (ecase (first e)
       (:noun (destructuring-bind (k lemma gender decl stem &optional stem2) e
                (declare (ignore k))
                (define-noun lemma gender decl stem :stem2 stem2)))
       (:lemma (destructuring-bind (k lemma forms) e
                 (declare (ignore k))
                 (orchestrator.citation-authority:add-lemma-forms lemma forms))))))
 :snapshot
 (lambda () (cons (%lexicon-gen-snapshot)
                  (orchestrator.citation-authority:lexicon-snapshot)))
 :restore
 (lambda (st)
   (%lexicon-gen-restore (car st))
   (orchestrator.citation-authority:lexicon-restore (cdr st))))
