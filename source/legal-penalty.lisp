;;;; source/legal-penalty.lisp
;;;; ============================================================================
;;;; ΠΟΙΝΙΚΗ ΒΑΡΥΤΗΤΑ — το μέτρο του «επιεικέστερου» (άρθρο 2 ΠΚ)
;;;; ============================================================================
;;;;
;;;; Το άρθρο 2 ΠΚ λέει «εφαρμόζεται ο επιεικέστερος» — αλλά «επιεικέστερος»
;;;; σημαίνει ΣΥΓΚΡΙΣΗ ΠΟΙΝΩΝ, κι αυτό λείπει από κάθε αυτόματο σύστημα. Εδώ
;;;; μπαίνει το μέτρο: το πλέγμα βαρύτητας των κυρίων ποινών του ΠΚ, ντετερμι-
;;;; νιστικά, ώστε η κρίση «ποια διάταξη είναι ηπιότερη» να βγαίνει ΜΕ ΛΟΓΟ
;;;; (ποια κατηγορία, ποιο εύρος) — όχι ως αδιαφανές νούμερο.
;;;;
;;;; Ιεραρχία κυρίων ποινών (ΠΚ άρθρα 50 επ.), βαρύτερη → ελαφρύτερη:
;;;;   ισόβια κάθειρξη · πρόσκαιρη κάθειρξη (5–20 έτη) · φυλάκιση (10 ημέρες–5 έτη)
;;;;   · παροχή κοινωφελούς εργασίας · χρηματική ποινή/πρόστιμο
;;;; Στην ΙΔΙΑ κατηγορία, ηπιότερη είναι η μικρότερη διάρκεια (ελάχιστο, μετά
;;;; μέγιστο). Οι δικαστικές αποφάσεις γράφουν τον αριθμό ΚΑΙ σε παρένθεση
;;;; («κάθειρξη είκοσι δύο (22) ετών»), οπότε το ψηφίο είναι η πρώτη πηγή· οι
;;;; ελληνικές λέξεις (και γενικής: «τριών», «δέκα») είναι το δίχτυ ασφαλείας.

(defpackage :orchestrator.penalty
  (:use :cl)
  (:export #:penalty #:penalty-p #:penalty-kind #:penalty-min-days #:penalty-max-days
           #:parse-penalty #:penalty-rank #:penalty-severity
           #:milder-penalty #:penalty->string))

(in-package :orchestrator.penalty)

(defstruct penalty
  "Μια κύρια ποινή: KIND ∈ {:isovia :katheirxi :fylakisi :koinofelis :xrimatiki
   :none}, και διάρκεια σε ΗΜΕΡΕΣ (MIN/MAX, NIL = απροσδιόριστο άκρο· η ισόβια
   δεν έχει διάρκεια)."
  (kind :none) (min-days nil) (max-days nil))

;;; ----------------------------------------------------------------------------
;;; Ελληνικοί αριθμοί ποινικού πλαισίου (ψηφίο πρώτα, λέξη ως δίχτυ)
;;; ----------------------------------------------------------------------------

(defparameter *units*
  '(("ένα" . 1) ("ένας" . 1) ("μία" . 1) ("μια" . 1) ("ενός" . 1)
    ("δύο" . 2) ("δυο" . 2) ("τρία" . 3) ("τρεις" . 3) ("τριών" . 3)
    ("τέσσερα" . 4) ("τέσσερις" . 4) ("τεσσάρων" . 4) ("πέντε" . 5)
    ("έξι" . 6) ("επτά" . 7) ("εφτά" . 7) ("οκτώ" . 8) ("οχτώ" . 8)
    ("εννέα" . 9) ("εννιά" . 9))
  "Μονάδες 1–9 (ονομαστική/γενική) — τα άκρα ποινικών πλαισίων.")

(defparameter *teens-tens*
  '(("δέκα" . 10) ("έντεκα" . 11) ("ένδεκα" . 11) ("δώδεκα" . 12)
    ("δεκατρία" . 13) ("δεκατέσσερα" . 14) ("δεκαπέντε" . 15) ("δεκαέξι" . 16)
    ("δεκαεπτά" . 17) ("δεκαεφτά" . 17) ("δεκαοκτώ" . 18) ("δεκαοχτώ" . 18)
    ("δεκαεννέα" . 19) ("δεκαεννιά" . 19)
    ("είκοσι" . 20) ("τριάντα" . 30) ("σαράντα" . 40) ("πενήντα" . 50))
  "10–19 και δεκάδες — καλύπτουν το εύρος των κυρίων ποινών (max 20 κάθειρξη).")

(defun %word->number (words)
  "WORDS: λίστα από πεζές ελληνικές λέξεις αριθμού (π.χ. (\"είκοσι\" \"δύο\")).
   Επιστρέφει τον ακέραιο, ή NIL. Χειρίζεται «είκοσι δύο», «δεκαπέντε», «τριών»."
  (let ((tens 0) (unit 0) (seen nil))
    (dolist (w words)
      (let ((tt (cdr (assoc w *teens-tens* :test #'string=)))
            (u  (cdr (assoc w *units* :test #'string=))))
        (cond (tt (setf tens (+ tens tt) seen t))
              (u  (setf unit (+ unit u) seen t)))))
    (when seen (+ tens unit))))

(defparameter *num-token* (cl-ppcre:create-scanner "[A-Za-zΑ-Ωα-ωΆ-Ώά-ώϊϋΐΰ]+"))

(defun %amount (snippet)
  "Ο αριθμός μέσα σε SNIPPET: ΠΡΩΤΑ ψηφίο σε παρένθεση «(22)» ή σκέτο, αλλιώς
   ελληνικές λέξεις. NIL αν δεν βρεθεί."
  (or (cl-ppcre:register-groups-bind (d) ("\\((\\d{1,4})\\)" snippet)
        (parse-integer d))
      (cl-ppcre:register-groups-bind (d) ("(\\d{1,4})" snippet)
        (parse-integer d))
      (%word->number
       (mapcar #'string-downcase
               (cl-ppcre:all-matches-as-strings *num-token* snippet)))))

;;; ----------------------------------------------------------------------------
;;; ΔΙΑΡΚΕΙΑ → ΗΜΕΡΕΣ  (έτος=365, μήνας=30, ημέρα=1 — μόνο για διάταξη)
;;; ----------------------------------------------------------------------------

(defun %unit-days (snippet)
  (cond ((cl-ppcre:scan "(?i)ετ(ών|ους|η)|χρόν" snippet) 365)
        ((cl-ppcre:scan "(?i)μήν|μηνών" snippet) 30)
        ((cl-ppcre:scan "(?i)ημ(ερών|έρα)" snippet) 1)
        (t 365)))                       ; κάθειρξη μετριέται πάντα σε έτη

(defun %bounds (snippet)
  "Επιστρέφει (values MIN-DAYS MAX-DAYS) από ένα απόσπασμα διάρκειας:
   «τουλάχιστον N» → (N . nil)· «έως/μέχρι N» → (nil . N)· «N έως M» → (N . M)·
   σκέτο «N» → (N . N). NIL/NIL όταν δεν υπάρχει αριθμός."
  (let ((ud (%unit-days snippet)))
    (multiple-value-bind (ms me rs re)
        (cl-ppcre:scan "(\\d{1,4}|[A-Za-zΑ-Ωα-ωΆ-Ώά-ώ ]+?)\\s*(έως|μέχρι|–|-)\\s*(\\d{1,4}|[Α-Ωα-ωΆ-Ώά-ώ]+)" snippet)
      (declare (ignore me))
      (if ms
          (values (let ((a (%amount (subseq snippet (aref rs 0) (aref re 0)))))
                    (and a (* a ud)))
                  (let ((b (%amount (subseq snippet (aref rs 2) (aref re 2)))))
                    (and b (* b ud))))
          (let ((n (%amount snippet)))
            (cond ((null n) (values nil nil))
                  ((cl-ppcre:scan "(?i)τουλάχιστον|άνω|πάνω" snippet) (values (* n ud) nil))
                  ((cl-ppcre:scan "(?i)έως|μέχρι|το πολύ|ανώτ" snippet) (values nil (* n ud)))
                  (t (values (* n ud) (* n ud)))))))))

;;; ----------------------------------------------------------------------------
;;; PARSE — ένα ποινικό απόσπασμα → δομημένη ποινή (με τα εκ του νόμου άκρα)
;;; ----------------------------------------------------------------------------

(defparameter +statutory+
  ;; ΠΚ: κάθειρξη 5–20 έτη· φυλάκιση 10 ημέρες–5 έτη — τα εκ του νόμου όρια όταν
  ;; το κείμενο δίνει μόνο το είδος («τιμωρείται με κάθειρξη»).
  `((:katheirxi ,(* 5 365) ,(* 20 365))
    (:fylakisi  10          ,(* 5 365))))

(defun parse-penalty (text)
  "Το κείμενο TEXT (μια ρήτρα ποινής) → δομημένη PENALTY. Αναγνωρίζει: ισόβια
   κάθειρξη, πρόσκαιρη κάθειρξη, φυλάκιση, παροχή κοινωφελούς εργασίας, χρηματική
   ποινή/πρόστιμο. Τα άκρα από το κείμενο· αν λείπουν, τα εκ του νόμου (ΠΚ).
   NIL αν καμία ποινή δεν αναγνωρίζεται."
  (let ((s text))
    (cond
      ((cl-ppcre:scan "(?i)ισόβι[ας].{0,15}κάθειρξη|ισόβια κάθειρξη" s)
       (make-penalty :kind :isovia))
      ((cl-ppcre:scan "(?i)κάθειρξη[ςι]?" s)
       (let ((tail (subseq s (nth-value 0 (cl-ppcre:scan "(?i)κάθειρξη[ςι]?" s)))))
         (multiple-value-bind (mn mx) (%bounds tail)
           (destructuring-bind (k lo hi) (assoc :katheirxi +statutory+)
             (declare (ignore k))
             (make-penalty :kind :katheirxi :min-days (or mn lo) :max-days (or mx hi))))))
      ((cl-ppcre:scan "(?i)φυλάκιση[ςι]?" s)
       (let ((tail (subseq s (nth-value 0 (cl-ppcre:scan "(?i)φυλάκιση[ςι]?" s)))))
         (multiple-value-bind (mn mx) (%bounds tail)
           (destructuring-bind (k lo hi) (assoc :fylakisi +statutory+)
             (declare (ignore k))
             (make-penalty :kind :fylakisi :min-days (or mn lo) :max-days (or mx hi))))))
      ((cl-ppcre:scan "(?i)κοινωφελ" s) (make-penalty :kind :koinofelis))
      ((cl-ppcre:scan "(?i)χρηματικ[ήής]{1,3} ποιν|πρόστιμο|χρηματικ[ήής]{1,3} .{0,10}ευρώ|ευρώ" s)
       (make-penalty :kind :xrimatiki))
      (t nil))))

;;; ----------------------------------------------------------------------------
;;; ΒΑΡΥΤΗΤΑ + ΣΥΓΚΡΙΣΗ (το «επιεικέστερος» του 2 ΠΚ)
;;; ----------------------------------------------------------------------------

(defun penalty-rank (p)
  "Κατηγορική βαρύτητα (μεγαλύτερο = βαρύτερο). Η κατηγορία υπερισχύει πάντα της
   διάρκειας: κάθειρξη 5 ετών είναι βαρύτερη από φυλάκιση 5 ετών (κακούργημα)."
  (ecase (penalty-kind p)
    (:isovia 5) (:katheirxi 4) (:fylakisi 3) (:koinofelis 2) (:xrimatiki 1) (:none 0)))

(defun penalty-severity (p)
  "Συγκρίσιμο κλειδί βαρύτητας: (κατηγορία, ελάχιστο, μέγιστο) σε ημέρες. Η
   ισόβια παίρνει άπειρο· άγνωστο άκρο → 0 (ευνοϊκότερη υπόθεση για το ελάχιστο)."
  (list (penalty-rank p)
        (or (penalty-min-days p) 0)
        (or (penalty-max-days p) most-positive-fixnum)))

(defun %sev< (a b)
  (loop for x in a for y in b
        do (cond ((< x y) (return t)) ((> x y) (return nil)))
        finally (return nil)))

(defun milder-penalty (a b)
  "Η ΗΠΙΟΤΕΡΗ των A, B (το μέτρο του «επιεικέστερου», άρθρο 2 ΠΚ). Επιστρέφει
   (values WHICH REASON) όπου WHICH ∈ {:a :b :equal} και REASON ∈
   {:different-category :shorter-range :equal} — ο ΛΟΓΟΣ, ώστε η κρίση να φέρει
   την αιτιολογία της, όχι σκέτο αποτέλεσμα."
  (let ((sa (penalty-severity a)) (sb (penalty-severity b)))
    (cond
      ((equal sa sb) (values :equal :equal))
      ((/= (first sa) (first sb))
       (values (if (< (first sa) (first sb)) :a :b) :different-category))
      ((%sev< sa sb) (values :a :shorter-range))
      (t (values :b :shorter-range)))))

(defun penalty->string (p)
  "Αναγνώσιμη φράση της ποινής — για τα δέντρα απόδειξης."
  (flet ((yr (d) (when d (/ d 365.0))))
    (ecase (penalty-kind p)
      (:isovia "ισόβια κάθειρξη")
      (:katheirxi (format nil "κάθειρξη ~@[~,1F–~]~@[~,1F ετών~]" (yr (penalty-min-days p)) (yr (penalty-max-days p))))
      (:fylakisi (let ((mn (penalty-min-days p)) (mx (penalty-max-days p)))
                   (format nil "φυλάκιση ~@[~A–~]~@[~A~]"
                           (and mn (if (< mn 365) (format nil "~D ημ." mn) (format nil "~,1F ετ." (/ mn 365.0))))
                           (and mx (if (< mx 365) (format nil "~D ημ." mx) (format nil "~,1F ετ." (/ mx 365.0)))))))
      (:koinofelis "παροχή κοινωφελούς εργασίας")
      (:xrimatiki "χρηματική ποινή")
      (:none "—"))))
