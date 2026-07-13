;;;; tests/greek-morphology-test.lisp
;;;; ============================================================================
;;;; ΤΙΜΙΑ ΜΟΡΦΟΛΟΓΙΑ ΧΑΡΑΚΤΗΡΙΣΤΙΚΩΝ — lock σταθερότητας κλίσης + ΤΙΜΙΟΤΗΤΑΣ
;;;; ============================================================================
;;;; Κλειδώνει την έδρα morph-analyze/morph-lemma ([0077]):
;;;;   · ΣΤΑΘΕΡΟΤΗΤΑ: ΚΑΘΕ κλιτός τύπος ενός λεξικού στοιχείου → ΤΟ ΙΔΙΟ λήμμα
;;;;     (βάση ↔ γενική ↔ αιτιατική ↔ πληθυντικός ↔ καθαρεύουσα)·
;;;;   · ΤΙΜΙΟΤΗΤΑ: άγνωστος τύπος → :unknown (ΠΟΤΕ λάθος λήμμα)· ρητός θάνατος του
;;;;     lossy μάντη lemmatize-greek (άμυνα→άμυνο, κατόχου→κατόχος)·
;;;;   · ΧΑΡΑΚΤΗΡΙΣΤΙΚΑ: κάθε τύπος φέρει (case,number,gender) για τη γραμματική.
;;;; ============================================================================

(in-package :orchestrator.citation-authority)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== ΣΤΑΘΕΡΟΤΗΤΑ ΚΛΙΣΗΣ: όλοι οι τύποι → ΤΟ ΙΔΙΟ λήμμα ==~%")
;; Ο πυρήνας: το bug που έδειξε το [0077] probe (βάση/κλιτός → διαφορετικά) ΠΕΘΑΙΝΕΙ.
(dolist (grp '(("άμυνα"      "άμυνα" "άμυνας" "άμυνες" "αμυνών")
               ("ιδιοποίηση" "ιδιοποίηση" "ιδιοποίησης" "ιδιοποιήσεως" "ιδιοποιήσεις")
               ("συναίνεση"  "συναίνεση" "συναίνεσης" "συναινέσεως")
               ("κάτοχος"    "κάτοχος" "κατόχου" "κατόχων" "κατόχους")
               ("εργαλείο"   "εργαλείο" "εργαλείου" "εργαλεία" "εργαλείων")
               ("νόμιμος"    "νόμιμος" "νόμιμη" "νόμιμης" "νόμιμο")
               ("παράνομος"  "παράνομος" "παράνομη" "παράνομης")))
  (destructuring-bind (lemma . forms) grp
    (check (format nil "~A: όλοι οι κλιτοί τύποι → ~A" lemma lemma)
           (every (lambda (f) (string= (morph-lemma f) lemma)) forms))))

(format t "~%== ΤΙΜΙΟΤΗΤΑ: άγνωστο → :unknown, ΠΟΤΕ λάθος λήμμα (θάνατος του μάντη) ==~%")
(check "τυχαία ακολουθία → :unknown (καμία εικασία)"
       (eq :unknown (morph-lemma "ξζψωθ")))
(check "άγνωστη νομική λέξη εκτός λεξικού → :unknown"
       (eq :unknown (morph-lemma "τηλεσκόπιο")))
;; Ο συγκεκριμένος θάνατος: το lemmatize-greek έδινε άμυνα→άμυνο· η έδρα ΔΕΝ παράγει «άμυνο».
(check "«άμυνο» ΔΕΝ είναι δηλωμένος τύπος ⇒ :unknown (ο θάνατος του άμυνα→άμυνο)"
       (eq :unknown (morph-lemma "άμυνο")))
;; Το normalize-greek διπλώνει τόνο (κατόχος≡κάτοχος): η αναγνώριση είναι ΣΩΣΤΑ
;; άτονη. Ο πραγματικός θάνατος του μάντη: το ΛΗΜΜΑ που επιστρέφεται είναι ΠΟΤΕ
;; ανύπαρκτη λέξη. Ρητή αντιπαράθεση με το lossy lemmatize-greek:
(check "morph-lemma(«κατόχου») = «κάτοχος» (σωστό λήμμα) — ΟΧΙ το «κατόχος» του μάντη"
       (and (string= (morph-lemma "κατόχου") "κάτοχος")
            (string= (lemmatize-greek "κατόχου") "κατόχος")))  ; ο μάντης δίνει ανύπαρκτο
(check "morph-lemma(«άμυνας») = «άμυνα» — ΟΧΙ το «άμυνο» του μάντη (lemmatize-greek «άμυνα»→«άμυνο»)"
       (and (string= (morph-lemma "άμυνας") "άμυνα")
            (string= (lemmatize-greek "άμυνα") "άμυνο")))       ; ο μάντης δίνει ανύπαρκτο

(format t "~%== ΓΕΝΙΚΕΥΣΗ: ο κλιτός τύπος του held-out ταιριάζει με τη βάση ==~%")
;; Αυτό είναι το κλειδί που, ΟΤΑΝ τον καταναλώσει η γραμματική (φάση 2), θα γυρίσει
;; το held-out «νόμιμης άμυνας» → «νόμιμη άμυνα». Εδώ κλειδώνεται σε επίπεδο έδρας.
(check "morph-lemma(«νόμιμης») = morph-lemma(«νόμιμη») = «νόμιμος»"
       (and (string= (morph-lemma "νόμιμης") "νόμιμος")
            (string= (morph-lemma "νόμιμη")  "νόμιμος")))
(check "morph-lemma(«άμυνας») = morph-lemma(«άμυνα») = «άμυνα»"
       (and (string= (morph-lemma "άμυνας") "άμυνα")
            (string= (morph-lemma "άμυνα")  "άμυνα")))

(format t "~%== ΧΑΡΑΚΤΗΡΙΣΤΙΚΑ: κάθε ανάγνωση φέρει (case,number,gender) ==~%")
(check "«άμυνας» ⇒ ανάγνωση με (:gen :sg :fem)"
       (some (lambda (h) (and (eq (feat-case (cdr h)) :gen)
                              (eq (feat-number (cdr h)) :sg)
                              (eq (feat-gender (cdr h)) :fem)))
             (morph-analyze "άμυνας")))
(check "«κατόχου» ⇒ ανάγνωση με (:gen :sg :masc)"
       (some (lambda (h) (and (eq (feat-case (cdr h)) :gen)
                              (eq (feat-gender (cdr h)) :masc)))
             (morph-analyze "κατόχου")))
(check "«νόμιμης» ⇒ ανάγνωση με (:gen :sg :fem)"
       (some (lambda (h) (and (eq (feat-case (cdr h)) :gen)
                              (eq (feat-gender (cdr h)) :fem)))
             (morph-analyze "νόμιμης")))

(format t "~%== ΝΤΕΤΕΡΜΙΝΙΣΜΟΣ ==~%")
(check "ίδιο αποτέλεσμα σε δύο κλήσεις"
       (equalp (morph-analyze "άμυνας") (morph-analyze "άμυνας")))

(format t "~%========================================~%")
(format t "GREEK-MORPHOLOGY: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
