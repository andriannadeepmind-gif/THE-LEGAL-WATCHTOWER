;;;; source/legal-decisions.lisp
;;;; ============================================================================
;;;; ΝΟΜΟΛΟΓΙΑ — the decisions corpus (Άρειος Πάγος, Εφετεία, …)
;;;; ============================================================================
;;;;
;;;; A court decision is a different corpus class from legislation: its identity
;;;; is (court, number, year) — carried by the FILENAME per the input/decisions
;;;; convention, so identity never depends on parsing — and its value lives in
;;;; three structured extractions:
;;;;
;;;;   • ΣΥΝΘΕΣΗ — the judges WITH THEIR ROLES (Πρόεδρος, Εισηγητής, μέλη).
;;;;     Stored structurally so per-judge analytics (τι εφαρμόζει/προτιμά ο
;;;;     καθένας) are a query over data, never a re-parse.
;;;;   • ΠΑΡΑΠΟΜΠΕΣ — the provisions the decision applies («άρθρο 187 παρ. 6
;;;;     ΠΚ», «άρθρο 42 παρ. 5 ν. 4557/2018»), each with its law tag, so they
;;;;     bind to the SERVED codes' citation graph.
;;;;   • ΧΡΟΝΙΚΗ ΑΓΚΥΡΩΣΗ (tempus regit actum) — the decision year against each
;;;;     cited article's per-article version date: cited article last modified
;;;;     BEFORE the decision ⇒ the court applied the very text served today,
;;;;     PROVABLY; modified after ⇒ flagged «τροποποιήθηκε μετά την απόφαση».
;;;;
;;;; Pure module: parses TEXT into a CLOS object and serializes it. Reading the
;;;; PDF (pdf-authority) and resolving law tags to corpora (configs) belong to
;;;; the caller — no I/O or config coupling here beyond the text itself.

(defpackage :orchestrator.decisions
  (:use :cl)
  (:export #:legal-decision #:decision-court #:decision-number #:decision-year
           #:decision-summary #:decision-chamber #:decision-judges #:decision-citations
           #:decision-body-text #:decision-source-file
           #:judge-entry #:judge-name #:judge-role #:judge-rapporteur-p
           #:citation-entry #:citation-law-tag #:citation-article #:citation-paragraph
           #:citation-tag-inferred-p #:decision-operative
           #:parse-decision-text #:decision->json-alist
           #:parse-act-date #:penal-decision-p
           #:decision-structure #:decision-ratio #:decision-stance #:ratio-stance
           #:decision-grounds
           #:+law-tag-corpus-map+ #:%fold
           ;; δηλωτική γραμματική — επεκτάσιμη από πακέτα γνώσης, ζωντανά
           #:rebuild-decision-scanners #:*ratio-openers* #:*ratio-verdict-words*
           #:*operative-verb-words* #:*narration-verb-words* #:*judged-subjects*))

(in-package :orchestrator.decisions)

;;; ----------------------------------------------------------------------------
;;; model
;;; ----------------------------------------------------------------------------

(defclass judge-entry ()
  ((name :initarg :name :reader judge-name)
   (role :initarg :role :reader judge-role
         :documentation "Ο ρόλος όπως τον γράφει η απόφαση (Πρόεδρος Εφετών,
          Εφέτης, Αρεοπαγίτης …), ονομαστικοποιημένος.")
   (rapporteur-p :initarg :rapporteur-p :initform nil :reader judge-rapporteur-p
                 :documentation "Τ όταν η απόφαση τον ορίζει Εισηγητή — το
                  πρόσωπο του οποίου η νομική προτίμηση αποτυπώνεται κατεξοχήν
                  στο σκεπτικό.")))

(defclass citation-entry ()
  ((law-tag :initarg :law-tag :reader citation-law-tag
            :documentation "Η ετικέτα του νομοθετήματος όπως παρατίθεται:
             \"ΠΚ\", \"ΚΠΔ\", \"ΑΚ\", \"ΚΠολΔ\", \"ΚΔΔ\", \"Σ\" ή \"ν. 4557/2018\".")
   (article :initarg :article :reader citation-article)
   (paragraph :initarg :paragraph :initform nil :reader citation-paragraph)
   (tag-inferred-p :initarg :tag-inferred-p :initform nil :reader citation-tag-inferred-p
                   :documentation "Τ όταν το νομοθέτημα ΔΕΝ γραφόταν δίπλα στο
                    άρθρο αλλά συνήχθη από τα συμφραζόμενα (ο κατάλογος «άρθρα
                    111, 112 και 113 του ΚΠΔ», ή το πλησιέστερο ρητό νομοθέτημα
                    της περιόδου). Η εξυπνάδα δηλώνει πότε συμπεραίνει.")))

(defclass legal-decision ()
  ((court :initarg :court :reader decision-court)
   (number :initarg :number :reader decision-number)
   (year :initarg :year :reader decision-year)
   (chamber :initarg :chamber :initform nil :reader decision-chamber
            :documentation "Το τμήμα (π.χ. «Ζ΄ Ποινικό Τμήμα» του ΑΠ), όταν
             η απόφαση το δηλώνει.")
   (summary :initarg :summary :initform nil :reader decision-summary)
   (judges :initarg :judges :initform '() :reader decision-judges)
   (citations :initarg :citations :initform '() :reader decision-citations)
   (operative :initarg :operative :initform '() :reader decision-operative
              :documentation "Τι ΕΚΡΙΝΕ η απόφαση: τα ρήματα του διατακτικού
               («ΓΙΑ ΤΟΥΣ ΛΟΓΟΥΣ ΑΥΤΟΥΣ … Απορρίπτει/Αναιρεί/…»), με την σειρά τους.")
   (body-text :initarg :body-text :reader decision-body-text)
   (source-file :initarg :source-file :reader decision-source-file)))

(defparameter +law-tag-corpus-map+
  '(("ΠΚ" . "poinikos") ("ΚΠΔ" . "kpoinikis") ("ΑΚ" . "astikos")
    ("ΚΠολΔ" . "kpolitikis") ("ΚΔΔ" . "kdioikitikis")
    ("Σ" . "syntagma") ("Συντ" . "syntagma"))
  "Παράθεση → served corpus id, for the tags that ARE our six codes. A tag
   outside this map (e.g. «ν. 4557/2018») is kept verbatim — a real external
   citation, not an error.")

;;; ----------------------------------------------------------------------------
;;; σύνθεση (judges with roles)
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ΤΑΥΤΙΣΗΣ — η λέξη είναι ΜΙΑ, όχι όσες οι γραφές της
;;; ----------------------------------------------------------------------------
;;;
;;; «ΣΥΝΗΛΘΕ», «Συνήλθε», «Συνηλθε» είναι η ίδια λέξη. Αντί η γραμματική να
;;; απαριθμεί γραφές (εύθραυστο — κάθε νέα παραλλαγή θα ήταν νέα τύφλωση),
;;; η ΤΑΥΤΙΣΗ γίνεται σε αναδίπλωση: πεζά, χωρίς τόνους/διαλυτικά, τελικό
;;; σίγμα→σ. Η αναδίπλωση είναι 1:1 ανά χαρακτήρα (ίδιο μήκος), άρα κάθε
;;; offset στο αναδιπλωμένο ισχύει ΑΥΤΟΥΣΙΟ στο πρωτότυπο — η γενίκευση
;;; της ταύτισης δεν θυσιάζει ποτέ την απόδειξη-στο-γράμμα. Τα πρότυπα
;;; γράφονται σε φυσικά ελληνικά και αναδιπλώνονται με την ΙΔΙΑ συνάρτηση,
;;; ώστε πρότυπο και κείμενο να ζουν εξ ορισμού στον ίδιο χώρο.

(defun %fold (s)
  "Same-length matching normalization: lowercase, accent/diaeresis-free,
   final sigma unified. 1:1 per character ⇒ offsets carry to the original."
  (map 'string
       (lambda (ch)
         (let ((c (char-downcase ch)))
           (case c
             ((#\ά) #\α) ((#\έ) #\ε) ((#\ή) #\η)
             ((#\ί #\ϊ #\ΐ) #\ι) ((#\ό) #\ο)
             ((#\ύ #\ϋ #\ΰ) #\υ) ((#\ώ) #\ω) ((#\ς) #\σ)
             (t c))))
       s))

(defun %folded-scanner (pattern &rest args)
  "Scanner που ταυτίζει σε αναδιπλωμένο κείμενο — το PATTERN γράφεται σε
   φυσικά ελληνικά και αναδιπλώνεται με την ίδια %FOLD (συνέπεια εξ ορισμού)."
  (apply #'cl-ppcre:create-scanner (%fold pattern) args))

(defparameter *composition-scanner*
  (%folded-scanner
   "(?s)(?:συγκροτήθηκε|αποτελούμεν[οη])\\s+από\\s+τ[οη][υν]ς?\\s+δικαστ[έή]ς?(?:\\s+της\\s+[^:\\n]{0,60}?σύνθεσης)?\\s*:?,?\\s*(.*?)(?:και\\s+τ[ηο][υνι]+ς?\\s+γραμματέ|γραμματέ|συνήλθε|συνεδρίασε)")
  "Το τμήμα σύνθεσης: από «Αποτελούμενο/Συγκροτήθηκε από τους Δικαστές …»
   έως την μνεία Γραμματέα ή την επόμενη πρόταση («Συνήλθε»/«Συνεδρίασε»).
   Ταυτίζει σε ΑΝΑΔΙΠΛΩΜΕΝΟ κείμενο — κεφαλαία/πεζά/τόνοι δεν είναι πλέον
   περιπτώσεις, είναι η ίδια λέξη (ΣΥΝΗΛΘΕ=Συνήλθε=Συνηλθε εξ ορισμού).
   Τρέχει με CL-PPCRE:SCAN σε (%FOLD text) και τα ΟΡΙΑ εφαρμόζονται στο
   πρωτότυπο — η γενίκευση δεν θυσιάζει την απόδειξη-στο-γράμμα.")

(defparameter *judge-roles*
  '(("Πρόεδρο Εφετών" "Πρόεδρος Εφετών" :single)
    ("Προεδρεύοντα Εφέτη" "Προεδρεύων Εφέτης" :single)
    ("Προεδρεύουσα Εφέτη" "Προεδρεύουσα Εφέτης" :single)
    ("Εφέτες" "Εφέτης" :plural)
    ("Εφέτη" "Εφέτης" :single)
    ("Αντιπρόεδρο του Αρείου Πάγου" "Αντιπρόεδρος του Αρείου Πάγου" :single)
    ("Αντιπρόεδρο Αρείου Πάγου" "Αντιπρόεδρος του Αρείου Πάγου" :single)
    ;; Ο/Η Πρόεδρος του ΑΠ που προεδρεύει σύνθεσης· ειδικό πρώτα, μετά σκέτο.
    ("Πρόεδρο του Αρείου Πάγου" "Πρόεδρος του Αρείου Πάγου" :single)
    ("Πρόεδρο Αρείου Πάγου" "Πρόεδρος του Αρείου Πάγου" :single)
    ("Αρεοπαγίτες" "Αρεοπαγίτης" :plural)
    ("Αρεοπαγίτη" "Αρεοπαγίτης" :single)
    ("Πρόεδρο Πρωτοδικών" "Πρόεδρος Πρωτοδικών" :single)
    ("Πρωτοδίκες" "Πρωτοδίκης" :plural)
    ("Πρωτοδίκη" "Πρωτοδίκης" :single)
    ("Πρόεδρο" "Πρόεδρος" :single))
  "(γραπτή-μορφή ονομαστική αριθμός): οι δικαστικοί τίτλοι όπως γράφονται στη
   σύνθεση. Ο ενικός τίτλος δένει στο ΤΕΛΕΥΤΑΙΟ εκκρεμές όνομα («Χ, Αντιπρόεδρο»)·
   ο πληθυντικός σε ΟΛΑ τα εκκρεμή («Α, Β, Γ και Δ, Αρεοπαγίτες» — η γραμματική
   του Αρείου Πάγου). Ειδικότεροι τίτλοι προηγούνται ώστε να ταιριάζουν πρώτοι.")

(defparameter *court-noise-words*
  '("Αρείου" "Πάγου" "Εφετών" "Πρωτοδικών" "Προέδρου" "Αντιπροέδρου")
  "Λέξεις ονομασίας δικαστηρίου/αξιώματος σε γενική: ένα «όνομα» αποτελούμενο
   ΜΟΝΟ από τέτοιες (π.χ. το «Αρείου Πάγου» της ρήτρας ορισμού «…πράξη του
   Προέδρου του Αρείου Πάγου») δεν είναι ποτέ δικαστής.")

(defun %judge-name-p (words)
  (and (>= (length words) 2)
       (notevery (lambda (w) (member w *court-noise-words* :test #'string=)) words)))

(defparameter *tabular-roles*
  '(("ΠΡΟΕΔΡΟΣ ΕΦΕΤΩΝ" "Πρόεδρος Εφετών" :plural)
    ("ΠΡΟΕΔΡΟΙ ΕΦΕΤΩΝ" "Πρόεδρος Εφετών" :plural)
    ("ΕΦΕΤΕΣ" "Εφέτης" :plural)
    ("ΕΦΕΤΗΣ" "Εφέτης" :single)
    ("ΑΡΕΟΠΑΓΙΤΕΣ" "Αρεοπαγίτης" :plural)
    ("ΑΡΕΟΠΑΓΙΤΗΣ" "Αρεοπαγίτης" :single)
    ("ΠΡΟΕΔΡΟΣ ΠΡΩΤΟΔΙΚΩΝ" "Πρόεδρος Πρωτοδικών" :plural)
    ("ΠΡΩΤΟΔΙΚΕΣ" "Πρωτοδίκης" :plural)
    ("ΠΡΩΤΟΔΙΚΗΣ" "Πρωτοδίκης" :single))
  "Οι ρόλοι της ΠΙΝΑΚΟΕΙΔΟΥΣ σύνθεσης (μορφή ιστοσελίδας Εφετείου Πειραιώς):
   ΚΕΦΑΛΑΙΑ γραμμή-ρόλος ΚΑΤΩ από το/τα ονόματα που αφορά.")

(defparameter *tabular-non-judges*
  '("ΕΙΣΑΓΓΕΛΕΑΣ" "ΑΝΤΕΙΣΑΓΓΕΛΕΑΣ" "ΓΡΑΜΜΑΤΕΑΣ")
  "Ρόλοι της σύνθεσης που ΔΕΝ είναι δικαστές — τα εκκρεμή ονόματά τους
   απορρίπτονται, δεν βαφτίζονται δικαστές.")

(defun %parse-judges-tabular (text)
  "Η ΔΕΥΤΕΡΗ διάλεκτος σύνθεσης — πίνακας «ΣΥΝΘΕΣΗ ΔΙΚΑΣΤΗΡΙΟΥ» (μορφή
   ιστοσελίδας δικαστηρίου): γραμμή-όνομα (Όνομα ΕΠΩΝΥΜΟ), από κάτω γραμμή-
   ρόλος σε ΚΕΦΑΛΑΙΑ που δένει στα προηγούμενα εκκρεμή ονόματα· ενδιάμεσα
   νομικές ρήτρες («νομίμως κληρωθείσα…») που αγνοούνται. Εισαγγελείς και
   Γραμματείς αναγνωρίζονται και ΑΠΟΡΡΙΠΤΟΝΤΑΙ. Σταματά στο τέλος του πίνακα."
  (let* ((start (cl-ppcre:scan "ΣΥΝΘΕΣΗ\\s+ΔΙΚΑΣΤ" text)))
    (when start
      (let* ((end (or (cl-ppcre:scan "ΚΑΤΗΓΟΡΟΥΜΕΝ|ΔΙΑΔΙΚ|ΠΕΡΙΛΗΨΗ|ΕΚΘΕΣΗ" text :start (+ start 30))
                      (min (length text) (+ start 3000))))
             (seg (subseq text start end))
             (pending '()) (out '()))
        (dolist (line (cl-ppcre:split "\\n" seg))
          (let ((line (string-trim " ,.·" (cl-ppcre:regex-replace-all "\\s+" line " "))))
            (cond
              ((zerop (length line)) nil)
              ;; ρόλος-μη-δικαστή: πέτα τα εκκρεμή ονόματα
              ((some (lambda (r) (search r line)) *tabular-non-judges*)
               (setf pending '()))
              ;; ρόλος δικαστή σε ΚΕΦΑΛΑΙΑ: δέσε τα εκκρεμή
              ((let ((role (find-if (lambda (r) (search (first r) line)) *tabular-roles*)))
                 (when role
                   (dolist (nm (reverse pending))
                     (push (make-instance 'judge-entry :name nm
                                          :role (second role) :rapporteur-p nil)
                           out))
                   (setf pending '())
                   t)))
              ;; γραμμή-όνομα: Κεφαλαιοπρώτο όνομα + ΚΕΦΑΛΑΙΟ επώνυμο (2-4 λέξεις)
              ((cl-ppcre:scan "^[Α-ΩΆ-Ώ][α-ωά-ώϊϋΐΰ]+(?:-[Α-ΩΆ-Ώ][α-ωά-ώϊϋΐΰ]+)?(?:\\s+[Α-ΩΆ-Ώ][α-ωά-ώϊϋΐΰ]+(?:-[Α-ΩΆ-Ώ][α-ωά-ώϊϋΐΰ]+)?)?\\s+[Α-ΩΆ-ΏΪΫ][Α-ΩΆ-ΏΪΫ-]+(?:\\s+[Α-ΩΆ-ΏΪΫ][Α-ΩΆ-ΏΪΫ-]+)?$" line)
               (push line pending))
              (t nil))))
        (nreverse out)))))

(defun %parse-judges (text)
  "Extract (name role rapporteur-p) from the composition segment by CHUNKING —
   the segment IS an enumeration, so its grammar is the list separators:
   chunks split on «,» και «και», each chunk carrying name and/or role and/or
   the «- Εισηγητή» mark. NAMES accumulate as pending; a SINGULAR role binds
   the last pending name; a PLURAL role binds ALL pending (η γραμματική του
   Αρείου Πάγου: «Α, Β, Γ και Δ, Αρεοπαγίτες»). Parentheticals are stripped
   first — τα πρόσωπά τους ρητώς ΔΕΝ μετέχουν (κωλυόμενα)."
  (multiple-value-bind (ms me rs re) (cl-ppcre:scan *composition-scanner* (%fold text))
    (declare (ignore me))
    ;; Δεύτερη διάλεκτος: αν λείπει η αφηγηματική σύνθεση («Συγκροτήθηκε…»),
    ;; δοκίμασε την πινακοειδή «ΣΥΝΘΕΣΗ ΔΙΚΑΣΤΗΡΙΟΥ» (μορφή ιστοσελίδας).
    (unless ms (return-from %parse-judges (or (%parse-judges-tabular text) '())))
    ;; τα όρια της αναδίπλωσης ισχύουν αυτούσια στο ΠΡΩΤΟΤΥΠΟ (1:1) — τα
    ;; ονόματα εξάγονται με την κανονική τους γραφή, όχι αναδιπλωμένα
    (let* ((seg (subseq text (aref rs 0) (aref re 0)))
           (seg (cl-ppcre:regex-replace-all "\\s+" seg " "))
           (seg (cl-ppcre:regex-replace-all "\\([^)]*\\)" seg " "))
           ;; η ρήτρα ορισμού «ο οποίος ορίσθηκε … » έως το επόμενο κόμμα-όριο
           (seg (cl-ppcre:regex-replace-all
                 ",?\\s*[οη] οποί[οα]ς? [^,]*" seg ""))
           (chunks (cl-ppcre:split "\\s*,\\s*|\\s+και\\s+" seg))
           (pending '()) (bound '()) (judges '()))
    (flet ((bind (role-entry names)
             (dolist (nm names)
               (let ((j (make-instance 'judge-entry
                                       :name (car nm)
                                       :role (second role-entry)
                                       :rapporteur-p (cdr nm))))
                 (push j judges) (setf bound j)))))
      (dolist (chunk chunks)
        (let* ((chunk (string-trim " :." chunk))
               ;; «Εισηγητή» (αρσ.) ΚΑΙ «Εισηγήτρια» (θηλ.) — η/ή· πολλές
               ;; δικαστές είναι γυναίκες, ο τύπος πρέπει να πιάνει και τα δύο.
               (rapp (and (cl-ppcre:scan "[–-]\\s*Εισηγ[ήη]τ" chunk) t))
               (chunk (cl-ppcre:regex-replace "\\s*[–-]\\s*Εισηγ[ήη]τ[^ ]*" chunk ""))
               (role (find-if (lambda (r)
                                (cl-ppcre:scan (format nil "(?:^|\\s)~A(?:[\\s.,]|$)" (first r))
                                               chunk))
                              *judge-roles*))
               (name-part (if role
                              (string-trim " " (cl-ppcre:regex-replace
                                                (first role) chunk ""))
                              chunk))
               (words (remove "" (cl-ppcre:split "\\s+" name-part) :test #'string=)))
          (when (and (%judge-name-p words)
                     (every (lambda (w) (upper-case-p (char w 0))) words))
            (push (cons (format nil "~{~A~^ ~}" words) nil) pending))
          (when rapp
            (cond (pending (setf (cdr (first pending)) t))
                  (bound (setf (slot-value bound 'rapporteur-p) t))))
          (when role
            (ecase (third role)
              (:single (when pending (bind role (list (pop pending)))))
              (:plural (bind role (reverse pending)) (setf pending '()))))))
      (nreverse judges)))))

(defparameter *chamber-scanner*
  (cl-ppcre:create-scanner
   "([Α-ΩA-Z]\\d?)['΄’]?\\s*(ΠΟΙΝΙΚΟ|ΠΟΛΙΤΙΚΟ|Ποινικό|Πολιτικό)\\s*(?:ΤΜΗΜΑ|Τμήμα)")
  "«Ζ΄ ΠΟΙΝΙΚΟ ΤΜΗΜΑ», «Α1΄ Πολιτικό Τμήμα» — μονό ή με ψηφίο (Α1/Β2), κεφαλαία ή
   με αρχικό κεφαλαίο, με λατινικό ομοιόγλυφο (Z/A/B…) όπως το γράφει το export.")

(defun %parse-chamber (text)
  ;; Η Ολομέλεια προηγείται: «ΤΟ ΔΙΚΑΣΤΗΡΙΟ ΤΟΥ ΑΡΕΙΟΥ ΠΑΓΟΥ ΣΕ ΤΑΚΤΙΚΗ/ΠΛΗΡΗ
  ;; ΟΛΟΜΕΛΕΙΑ» — αλλιώς ένα τυχαίο «Χ΄ Πολιτικό Τμήμα» αλλού στην σελίδα
  ;; (π.χ. σε παραπομπή) θα βαφτιζόταν τμήμα της απόφασης.
  (multiple-value-bind (m g)
      (cl-ppcre:scan-to-strings "ΑΡΕΙΟΥ\\s+ΠΑΓΟΥ\\s+ΣΕ\\s+(?:[Α-Ω]\\d?['’΄]?\\s+)?(ΤΑΚΤΙΚΗ|ΠΛΗΡΗ)\\s+ΟΛΟΜΕΛΕΙΑ" text)
    (when m
      (return-from %parse-chamber
        (if (string= (aref g 0) "ΠΛΗΡΗ") "Πλήρης Ολομέλεια" "Τακτική Ολομέλεια"))))
  (multiple-value-bind (m g) (cl-ppcre:scan-to-strings *chamber-scanner* text)
    (when m
      (format nil "~A΄ ~A Τμήμα"
              (map 'string (lambda (c) (case c (#\Z #\Ζ) (#\A #\Α) (#\B #\Β)
                                              (#\E #\Ε) (#\H #\Η) (t c)))
                   (string-right-trim "'΄’" (aref g 0)))
              (let ((w (aref g 1)))
                (cond ((or (string= w "ΠΟΙΝΙΚΟ") (string= w "Ποινικό")) "Ποινικό")
                      ((or (string= w "ΠΟΛΙΤΙΚΟ") (string= w "Πολιτικό")) "Πολιτικό")
                      (t w)))))))

;;; ----------------------------------------------------------------------------
;;; παραπομπές (provisions applied, with their law tag)
;;; ----------------------------------------------------------------------------

(defparameter +statute-tag-re+
  (concatenate 'string
   ;; Πιο ΕΙΔΙΚΟ πρώτα (η εναλλαγή δοκιμάζεται με την σειρά). Κάθε κώδικας ΚΑΙ
   ;; στην δοτισμένη μορφή (Π.Κ., Κ.Ποιν.Δ.) ΚΑΙ στην συμπαγή (ΠΚ, ΚΠοινΔ) —
   ;; τα πραγματικά κείμενα χρησιμοποιούν κυρίως την δοτισμένη. Οι νόμοι με
   ;; πεζό Ή ΚΕΦΑΛΑΙΟ Ν. Η %normalize-tag τα ανάγει όλα στο κανονικό tag.
   "Κ\\.?Ποιν\\.?Δ\\.?|ΚΠοινΔ|ΚΠΔ|"
   "Κ\\.?Πολ\\.?Δ\\.?|ΚΠολΔ|"
   "Κ\\.?Δ\\.?Δ\\.?|ΚΔΔ|"
   "Π\\.?Κ\\.?|"
   "Α\\.?Κ\\.?|"
   "Συντάγματος|Σύνταγμα|Συντ\\.?|Σ\\.|"
   "[νΝ]\\.?\\s*\\d{3,4}/\\d{4}")
  "ΜΙΑ γραμματική για κάθε ρητή μνεία νομοθετήματος — και οι δύο scanners κάτω
   την μοιράζονται (μηδέν διπλό regex). Δοτισμένες, συμπαγείς και κεφαλαία/πεζά.")

(defparameter *citation-scanner*
  (cl-ppcre:create-scanner
   (concatenate 'string
    "[άΆ]ρθρ(?:ου?|α|ων)\\s+(\\d+[Α-Ω]?(?:ΣΤ)?)\\s*(?:παρ\\.?\\s*(\\d+))?"
    "\\s*(?:εδ\\.?\\s*[α-ω΄']+\\s*)?(?:του\\s+|της\\s+)?(" +statute-tag-re+ ")?"))
  "«άρθρο 187 παρ. 6 Π.Κ.», «άρθρου 42 παρ.5 ν.4557/2018», «άρθρα 300 Α.Κ.».
   Ομάδες: αριθμός άρθρου, παράγραφος, ετικέτα νομοθετήματος (προαιρετική —
   συχνά κληρονομείται από τα συμφραζόμενα, οπότε μένει NIL).")

(defparameter *law-tag-scanner*
  (cl-ppcre:create-scanner
   (concatenate 'string "(?:του\\s+|της\\s+)?(" +statute-tag-re+ ")"))
  "Κάθε ρητή μνεία νομοθετήματος, με την θέση της — το πλέγμα συμφραζομένων
   από το οποίο κληρονομούν οι άδετες παραπομπές. Ίδια γραμματική με τον
   *citation-scanner* (+statute-tag-re+).")

(defun %normalize-tag (tag)
  "Ανάγει κάθε μορφή μνείας στο κανονικό tag (ΠΚ/ΚΠΔ/ΚΠολΔ/ΚΔΔ/ΑΚ/Σ) ώστε να
   λύνεται από το +law-tag-corpus-map+· οι εξωτερικοί νόμοι (ν. N/έτος) μένουν
   αυτούσιοι — πραγματική εξωτερική παραπομπή, ΟΧΙ λάθος, και ΔΕΝ μολύνουν άλλο
   κώδικα."
  (let* ((s  (string-trim " ." (cl-ppcre:regex-replace-all "\\s+" tag " ")))
         (nd (remove #\. s)))
    (cond
      ((string= nd "ΠΚ") "ΠΚ")
      ((member nd '("ΚΠοινΔ" "ΚΠΔ") :test #'string=) "ΚΠΔ")
      ((string= nd "ΚΠολΔ") "ΚΠολΔ")
      ((string= nd "ΚΔΔ") "ΚΔΔ")
      ((string= nd "ΑΚ") "ΑΚ")
      ((or (string= nd "Σ") (string= nd "Σύνταγμα")
           (and (>= (length nd) 4) (string= (subseq nd 0 4) "Συντ"))) "Σ")
      (t s))))

(defun %parse-citations (text)
  "All provision citations, with CONTEXTUAL statute resolution: an article
   whose statute is not written beside it inherits (α) τον κατάλογο «άρθρα
   111, 112 και 113 του ΚΠΔ» — το ρητό νομοθέτημα έως 60 χαρακτήρες ΜΠΡΟΣΤΑ,
   πριν από την επόμενη λέξη «άρθρ-» — αλλιώς (β) το πλησιέστερο ρητό
   νομοθέτημα έως 250 χαρακτήρες ΠΙΣΩ (η τρέχουσα συζήτηση). Οι συναγωγές
   σημαίνονται TAG-INFERRED-P — ρητό και συναγόμενο δεν συγχέονται ποτέ.
   Deduplicated on (tag, article, paragraph)."
  (let ((tag-positions '()))
    (cl-ppcre:do-scans (ms me rs re *law-tag-scanner* text)
      (push (cons ms (%normalize-tag (subseq text (aref rs 0) (aref re 0))))
            tag-positions))
    (setf tag-positions (nreverse tag-positions))
    (let ((seen (make-hash-table :test 'equal)) (out '()))
      (cl-ppcre:do-scans (ms me rs re *citation-scanner* text)
        (let* ((art (subseq text (aref rs 0) (aref re 0)))
               (par (and (aref rs 1) (subseq text (aref rs 1) (aref re 1))))
               (tag (and (aref rs 2) (%normalize-tag (subseq text (aref rs 2) (aref re 2)))))
               (inferred nil))
          (unless tag
            ;; (α) list scope: «… άρθρα 111, 112 και 113 του ΚΠΔ» — tag ahead,
            ;; before any new «άρθρ» opens a different citation
            (let* ((window-end (min (length text) (+ me 60)))
                   (window (subseq text me window-end))
                   (next-art (cl-ppcre:scan "[άΆ]ρθρ" window)))
              (multiple-value-bind (fs fe frs fre)
                  (cl-ppcre:scan *law-tag-scanner* window)
                (declare (ignore fe))
                (when (and fs (or (null next-art) (< fs next-art)))
                  (setf tag (%normalize-tag (subseq window (aref frs 0) (aref fre 0)))
                        inferred t))))
            ;; (β) nearest explicit statute up to 250 chars back — the running
            ;; discussion this bare article belongs to
            (unless tag
              (loop for (pos . tg) in tag-positions
                    while (< pos ms)
                    when (< (- ms pos) 250) do (setf tag tg inferred t))))
          (let ((key (list tag art par)))
            (unless (gethash key seen)
              (setf (gethash key seen) t)
              (push (make-instance 'citation-entry
                                   :law-tag tag :article art :paragraph par
                                   :tag-inferred-p inferred)
                    out)))))
      (nreverse out))))

;;; ----------------------------------------------------------------------------
;;; ΧΡΟΝΟΣ ΤΕΛΕΣΗΣ (tempus regit actum, στον σωστό άξονα)
;;; ----------------------------------------------------------------------------
;;;
;;; Το εφαρμοστέο ΟΥΣΙΑΣΤΙΚΟ δίκαιο δεν το ορίζει η ημερομηνία της απόφασης
;;; αλλά ο χρόνος τέλεσης της πράξης (και στο ποινικό, το άρθρο 2 ΠΚ: αν
;;; μεσολάβησε ηπιότερος νόμος έως την εκδίκαση, εφαρμόζεται ο επιεικέστερος).
;;; Ντετερμινιστική εξαγωγή: στα κείμενα του ΑΠ οι ημερομηνίες των ΠΡΑΓΜΑΤΙΚΩΝ
;;; περιστατικών γράφονται αριθμητικά ΜΕ πρόθεση («Στις 18-12-2010», «από
;;; 18-12-2010 έως 23-12-2010»), ενώ οι δικονομικές (συνεδρίαση, δημοσίευση)
;;; ολογράφως («18 Ιανουαρίου 2017») και οι αριθμοί εκθέσεων ΧΩΡΙΣ πρόθεση
;;; (« .../30-6-2015»). Η πρόθεση είναι το διακριτικό — όχι εικασία.

(defparameter *act-date-scanner*
  (cl-ppcre:create-scanner
   "(?:[Σσ]τις|[Tτ]ην|από|έως|μέχρι)\\s+(\\d{1,2})[-./](\\d{1,2})[-./]((?:19|20)\\d{2})")
  "Αριθμητική ημερομηνία ΜΕ πρόθεση — έτσι γράφονται τα πραγματικά περιστατικά.")

(defun parse-act-date (text decision-year)
  "Earliest fact-date in TEXT (prepositioned numeric dd-mm-yyyy, year strictly
   before DECISION-YEAR, within 30 years — the tempus anchor). Returns
   (values \"yyyy-mm-dd\" evidence-snippet) or NIL: όταν δεν αποδεικνύεται
   χρόνος τέλεσης, ΔΕΝ μαντεύουμε — οι ετυμηγορίες μένουν στον άξονα απόφασης."
  (let (best best-pos)
    (cl-ppcre:do-scans (ms me rs re *act-date-scanner* text)
      (let* ((d (parse-integer text :start (aref rs 0) :end (aref re 0)))
             (m (parse-integer text :start (aref rs 1) :end (aref re 1)))
             (y (parse-integer text :start (aref rs 2) :end (aref re 2)))
             (key (+ (* y 10000) (* m 100) d)))
        (when (and (< y decision-year) (>= y (- decision-year 30))
                   (<= 1 m 12) (<= 1 d 31)
                   (or (null best) (< key best)))
          (setf best key best-pos ms))))
    (when best
      (values (format nil "~4,'0D-~2,'0D-~2,'0D"
                      (floor best 10000) (mod (floor best 100) 100) (mod best 100))
              (let ((s (max 0 (- best-pos 30)))
                    (e (min (length text) (+ best-pos 50))))
                (cl-ppcre:regex-replace-all "\\s+" (subseq text s e) " "))))))

(defun penal-decision-p (d)
  "Ποινική υπόθεση; — από το τμήμα («Ζ΄ Ποινικό Τμήμα») ή το κείμενο. Ορίζει
   αν ισχύει ο κανόνας του άρθρου 2 ΠΚ (lex mitior) στην χρονική αγκύρωση."
  (let ((ch (decision-chamber d)))
    (or (and ch (cl-ppcre:scan "(?i)Ποινικ" ch))
        (cl-ppcre:scan "ΠΟΙΝΙΚ|Κ\\.?Ποιν\\.?Δ" (or (decision-body-text d) ""))
        nil)))

(defparameter *operative-scanner*
  ;; ο ΑΠ κλείνει με «ΓΙΑ ΤΟΥΣ ΛΟΓΟΥΣ ΑΥΤΟΥΣ», τα δικαστήρια ουσίας με
  ;; «ΔΙΑ ΤΑΥΤΑ» — αναδιπλωμένη ταύτιση: η γραφή δεν είναι πια περίπτωση
  (%folded-scanner "(?s)(?:για\\s+τους\\s+λόγους\\s+αυτούς|δια\\s+ταύτα)(.*)"))

(defvar *operative-verb-words*
  (list "απορρίπτει" "αναιρεί" "δέχεται" "παραπέμπει" "καταδικάζει" "επιβάλλει"
        "κηρύσσει" "αναβάλλει" "διατάσσει" "συνεκδικάζει" "ματαιώνει"
        "διορθώνει" "εξαφανίζει" "απέχει")
  "Τα ρήματα του διατακτικού — ΜΙΑ γραφή ανά ρήμα, όλες οι μορφές δια της
   αναδίπλωσης. Νέο ρήμα = μία λέξη (και μέσω πακέτου γνώσης, ζωντανά).")

(defvar *operative-verbs-scanner* nil
  "Χτίζεται από την λίστα — βλ. REBUILD-DECISION-SCANNERS.")

(defun %parse-operative (text)
  "Τα ρήματα του διατακτικού, με την σειρά τους — τι ΕΚΡΙΝΕ η απόφαση.
   Ταύτιση αναδιπλωμένα, εξαγωγή από το ΠΡΩΤΟΤΥΠΟ (ίδια όρια)."
  (let ((folded (%fold text)))
    (multiple-value-bind (ms me rs re) (cl-ppcre:scan *operative-scanner* folded)
      (declare (ignore me))
      (when ms
        (let ((tail-start (aref rs 0)) (tail-end (aref re 0)) (verbs '()))
          (cl-ppcre:do-scans (vs ve grs gre *operative-verbs-scanner* folded
                                 nil :start tail-start :end tail-end)
            (declare (ignore grs gre))
            (pushnew (string-capitalize (subseq text vs ve)) verbs :test #'string=))
          (nreverse verbs))))))

;;; ----------------------------------------------------------------------------
;;; περίληψη
;;; ----------------------------------------------------------------------------

(defun %parse-summary (text)
  "Η ΠΕΡΙΛΗΨΗ, όταν η απόφαση την προτάσσει: από την γραμμή «ΠΕΡΙΛΗΨΗ» έως το
   επόμενο δομικό όριο (αριθμός απόφασης / σύνθεση)."
  (multiple-value-bind (m g)
      (cl-ppcre:scan-to-strings
       (load-time-value
        (cl-ppcre:create-scanner
         "(?s)^\\s*ΠΕΡΙΛΗΨΗ\\s*$(.*?)(?=^\\s*(?:Αριθμός\\s+[Αα]πόφασης|ΤΡΙΜΕΛΕΣ|ΠΕΝΤΑΜΕΛΕΣ|ΜΟΝΟΜΕΛΕΣ|Αποτελούμεν|ΣΥΓΚΡΟΤΗΘΗΚΕ))"
         :multi-line-mode t))
       text)
    (when m
      (string-trim '(#\Space #\Newline #\Return)
                   (cl-ppcre:regex-replace-all "[ \\t]*\\n[ \\t]*" (aref g 0) " ")))))

;;; ----------------------------------------------------------------------------
;;; entry points
;;; ----------------------------------------------------------------------------


;;; ----------------------------------------------------------------------------
;;; ΑΝΑΤΟΜΙΑ (AST) — η απόφαση ως ΔΟΜΗ, όχι ως χυλός γραμμών
;;; ----------------------------------------------------------------------------
;;;
;;; Κάθε απόφαση του ΑΠ έχει σταθερή ανατομία με ρητούς δείκτες:
;;;   προμετωπίδα → διάδικοι («για να δικάσει…μεταξύ:») → ιστορικό δίκης
;;;   («Η ένδικη διαφορά άρχισε») → σκεπτικό («ΣΚΕΦΘΗΚΕ ΣΥΜΦΩΝΑ ΜΕ ΤΟ ΝΟΜΟ»)
;;;   → διατακτικό («ΓΙΑ ΤΟΥΣ ΛΟΓΟΥΣ ΑΥΤΟΥΣ»).
;;; Η δομή δίνει ΣΚΟΠΙΜΟΤΗΤΑ σε κάθε εξαγωγή: οι δικαστές ζουν στην προμετωπίδα,
;;; το ratio στο σκεπτικό, η κρίση στο διατακτικό. Τμήμα που δεν οριοθετείται
;;; μένει NIL — τίμια απουσία, ποτέ μάντεμα.

(defparameter *section-markers*
  ;; Οι δείκτες γράφονται σε φυσικά ελληνικά· η ταύτιση γίνεται αναδιπλωμένα,
  ;; οπότε «ΣΚΕΦΘΗΚΕ/Σκέφθηκε/σκεφθηκε» είναι εξ ορισμού ο ίδιος δείκτης.
  ;; Το «σκεφθηκε…νομο» κρατά ΚΕΦΑΛΑΙΑ σημασία μόνο ως θέση στο έγγραφο,
  ;; όχι ως γραφή — αυτό ακριβώς θέλει η ανθεκτική ανάγνωση.
  '((:parties   . "για\\s+να\\s+δικάσει|μεταξύ\\s*:")
    (:history   . "η\\s+ένδικη\\s+διαφορά\\s+άρχισε|με\\s+την\\s+ως\\s+άνω\\s+απόφασή?\\s+του")
    (:reasoning . "σκέφθηκε\\s+(?:σύμφωνα\\s+με|κατά)\\s+το\\s+νόμο|αφού\\s+μελέτησε\\s+τη\\s+δικογραφία")
    (:operative . "για\\s+τους\\s+λόγους\\s+αυτούς|δια\\s+ταύτα"))
  "Οι δείκτες έναρξης κάθε δομικού μέρους, με την σειρά της ανατομίας —
   ταυτίζονται σε αναδιπλωμένο κείμενο (%FOLD), τα όρια ισχύουν στο πρωτότυπο.")

(defun decision-structure (text)
  "Η ανατομία της απόφασης: alist (SECTION START END) σε ΑΥΞΟΥΣΑ σειρά, όπου
   START/END δείκτες μέσα στο TEXT. Το :header είναι πάντα [0, πρώτος δείκτης).
   Δείκτης που λείπει ⇒ το τμήμα απουσιάζει από το alist (τίμια)."
  (let* ((folded (%fold text))
         (marks (loop for (sec . rx) in *section-markers*
                      for pos = (cl-ppcre:scan (%fold rx) folded)
                      when pos collect (cons sec pos)))
         (marks (sort marks #'< :key #'cdr))
         (out '()))
    (push (list :header 0 (if marks (cdr (first marks)) (length text))) out)
    (loop for (this . rest) on marks
          do (push (list (car this) (cdr this)
                         (if rest (cdr (first rest)) (length text)))
                   out))
    (nreverse out)))

(defun %section-text (text structure section)
  (let ((e (assoc section structure)))
    (and e (subseq text (second e) (third e)))))

;;; Η γραμματική ως ΔΗΛΩΤΙΚΕΣ ΛΙΣΤΕΣ: οι scanners ξαναχτίζονται από αυτές
;;; (REBUILD-DECISION-SCANNERS), ώστε νέα γνώση — πακέτα :decision-grammar —
;;; να επεκτείνει την κατανόηση ΧΩΡΙΣ επαναμεταγλώττιση, και η σκιώδης
;;; εκτέλεση να δοκιμάζει υποψήφια γνώση με snapshot/restore αυτών των λιστών.

(defvar *ratio-openers*
  (list "κρίνοντας\\s+έτσι" "επομένως" "συνεπώς" "μετά\\s+ταύτα"
        "κατόπιν\\s+(?:τούτων|αυτών|των\\s+ανωτέρω)" "ενόψει\\s+(?:τούτων|αυτών)"
        "ως\\s+εκ\\s+τούτου" "κατ['’]\\s*ακολουθίαν?")
  "Οι εναρκτήρες της πρότασης-γέφυρας — φυσικά ελληνικά, αναδιπλωμένη ταύτιση.")

(defvar *ratio-verdict-words*
  (list "παραβίασε" "εσφαλμέν" "ορθώς" "αβάσιμ" "βάσιμ" "απαράδεκτ" "πρέπει\\s+να")
  "Οι λέξεις-κρίσεις που κλείνουν την γέφυρα.")

(defvar *ratio-scanner* nil
  "Χτίζεται από τις λίστες — βλ. REBUILD-DECISION-SCANNERS.")

(defun decision-ratio (text)
  "Το ratio decidendi όπως το ΛΕΕΙ η απόφαση: η τελευταία ΟΥΣΙΑΣΤΙΚΗ
   πρόταση-γέφυρα του σκεπτικού, verbatim — απόδειξη, όχι περίληψη. Η
   γέφυρα του παραδεκτού («παραδεκτή και πρέπει να ερευνηθεί») είναι
   δικονομικό προοίμιο, όχι ratio — προτιμάται η τελευταία γέφυρα που ΔΕΝ
   είναι τέτοια· μόνο αν δεν υπάρχει άλλη, μένει εκείνη. NIL όταν δεν
   βρίσκεται καμία — ποτέ κατασκευασμένο."
  (let* ((structure (decision-structure text))
         (reasoning (%section-text text structure :reasoning)))
    (when reasoning
      (let ((folded (%fold reasoning)) last last-substantive)
        (cl-ppcre:do-scans (ms me rs re *ratio-scanner* folded)
          (declare (ignore ms me))
          ;; όρια από την αναδίπλωση, κείμενο από το ΠΡΩΤΟΤΥΠΟ
          (let* ((hit (subseq reasoning (aref rs 0) (aref re 0))))
            (setf last hit)
            (unless (cl-ppcre:scan (%fold "παραδεκτή?\\s+και\\s+πρέπει\\s+να\\s+ερευνηθεί")
                                   (subseq folded (aref rs 0) (aref re 0)))
              (setf last-substantive hit))))
        (let ((chosen (or last-substantive last)))
          (and chosen (cl-ppcre:regex-replace-all "\\s+" chosen " ")))))))


(defun decision-stance (text)
  "Η ΘΕΣΗ της απόφασης, ντετερμινιστικά: ποιες διατάξεις κρίνει το ratio και
   με ποια φορά. Επιστρέφει λίστα plists (:tag T :article A :stance S) όπου
   S ∈ :upholds (ο λόγος βάσιμος/δεκτός — η ερμηνεία που ΔΕΧΕΤΑΙ το ratio)
     | :rejects (αβάσιμος/απορριπτέος — απορρίπτει την προσβολή της ερμηνείας).
   Πηγή: ΜΟΝΟ η πρόταση-γέφυρα (decision-ratio) — όχι όλος ο χυλός. NIL όταν
   δεν υπάρχει ratio ή δεν δηλώνει φορά — τίμια, ποτέ μάντεμα."
  (ratio-stance (decision-ratio text)))

(defun ratio-stance (ratio)
  "Η φορά+διατάξεις ΕΝΟΣ ratio (βλ. DECISION-STANCE) — δουλεύει και πάνω σε
   αποθηκευμένο ratio_evidence, ώστε η ανάλυση νομολογίας να μη ξαναπαρσάρει."
  (let ((ratio ratio))
    (when ratio
      (let ((stance (cond ((cl-ppcre:scan "παραβίασε|(?<![αΑ])βάσιμ|(?<![αΑ]παρά)δεκτός|πρέπει\\s+να\\s+γίνει\\s+δεκτ" ratio)
                           :upholds)
                          ((cl-ppcre:scan "αβάσιμ|απορριπτέ|απαράδεκτ" ratio)
                           :rejects))))
        (when stance
          (let ((out '()) (seen (make-hash-table :test 'equal)))
            (cl-ppcre:do-scans (ms me rs re *citation-scanner* ratio)
              (let ((art (subseq ratio (aref rs 0) (aref re 0)))
                    (tag (and (aref rs 2)
                              (%normalize-tag (subseq ratio (aref rs 2) (aref re 2))))))
                (let ((key (list tag art)))
                  (unless (gethash key seen)
                    (setf (gethash key seen) t)
                    (push (list :tag tag :article art :stance stance) out)))))
            (%drop-cassation-vehicles (nreverse out))))))))

(defparameter +cassation-vehicle-articles+
  '(("ΚΠολΔ" . ("559" "560")) ("ΚΠΔ" . ("510")))
  "Οι διατάξεις-ΟΧΗΜΑΤΑ της αναίρεσης: απαριθμούν τους λόγους αναιρέσεως
   (559/560 ΚΠολΔ, 510 ΚΠΔ) και μνημονεύονται σε ΚΑΘΕ ratio ως δικονομικό
   πλαίσιο («ο από τον αριθμό 1 του άρθρου 559 ΚΠολΔ λόγος»), όχι ως η
   διάταξη που το δικαστήριο ερμηνεύει. Η θέση της νομολογίας ανήκει στην
   ΟΥΣΙΑΣΤΙΚΗ διάταξη (π.χ. 281 ΑΚ) — αλλιώς κάθε απόφαση θα «έπαιρνε θέση»
   επί του 559 και ο χάρτης θα έδειχνε ψευδοαντιθέσεις.")

(defun %cassation-vehicle-p (stance-entry)
  (let ((arts (cdr (assoc (getf stance-entry :tag) +cassation-vehicle-articles+
                          :test #'equal))))
    (and arts (member (getf stance-entry :article) arts :test #'string=) t)))

(defun %drop-cassation-vehicles (stances)
  "Αφαίρεσε τα δικονομικά οχήματα από τις θέσεις — ΕΚΤΟΣ αν το ratio μιλά
   ΜΟΝΟ για αυτά (τότε πράγματι ερμηνεύει το ίδιο το 559/510 και μένουν)."
  (let ((substantive (remove-if #'%cassation-vehicle-p stances)))
    (or substantive stances)))

;;; ----------------------------------------------------------------------------
;;; ΛΟΓΟΙ ΑΝΑΙΡΕΣΕΩΣ — η μονάδα της κατανόησης σε βάθος
;;; ----------------------------------------------------------------------------
;;;
;;; Η απόφαση του ΑΠ ΕΙΝΑΙ μια ακολουθία κρίσεων επί λόγων: «ο από το άρθρο
;;; 510 παρ.1 στοιχ. Δ΄ ΚΠοινΔ λόγος αναιρέσεως … είναι αβάσιμος». Η γλώσσα
;;; είναι στερεότυπη — γραμματική, όχι μάντεμα. Κάθε κρίση εξάγεται ΜΕ την
;;; πρόταση-απόδειξη και τα offsets της· λόγος που δεν αναγνωρίζεται δεν
;;; εφευρίσκεται (τίμια απουσία), και η CLI τον καταγράφει στην μνήμη
;;; αναστοχασμού ώστε η γραμματική να επεκταθεί στοχευμένα.

(defparameter *ground-verdict-scanner*
  (cl-ppcre:create-scanner
   "απαράδεκτ|αβάσιμ|απορριπτέ|(?<![αΑ])βάσιμ|γίνει\\s+δεκτ|έγινε\\s+δεκτ")
  "Οι λέξεις-ετυμηγορίες μιας κρίσης επί λόγου. Το lookbehind κρατά το
   «βάσιμος» χωριστό από το «αβάσιμος».")

(defparameter *sentence-abbrevs* '("παρ" "στοιχ" "αριθ" "αρ" "ν" "Ν" "π.χ" "κλπ" "εδ"
                                   "Πολ" "Ποιν" "ΟλΑΠ" "Ολ")
  "Συντομογραφίες που τελειώνουν σε τελεία ΧΩΡΙΣ να κλείνουν πρόταση —
   μαζί με τα μεσαία τμήματα των εστιγμένων κωδίκων («Κ.Πολ.Δ.», «Κ.Ποιν.Δ.»)
   που αλλιώς θα έκοβαν την πρόταση στη μέση της παραπομπής.")

(defun %sentence-bounds (text pos)
  "Τα όρια της πρότασης που περιέχει το POS: πίσω/εμπρός έως τελεία που ΔΕΝ
   ανήκει σε συντομογραφία ούτε σε αριθμό («παρ. 1», «510 παρ.1»)."
  (flet ((sentence-dot-p (i)
           (and (char= (char text i) #\.)
                (or (>= (1+ i) (length text))
                    (not (digit-char-p (char text (1+ i)))))
                (let* ((ws (position-if-not #'alphanumericp text
                                            :end i :from-end t))
                       (word (subseq text (if ws (1+ ws) 0) i)))
                  (and (not (member word *sentence-abbrevs* :test #'string=))
                       ;; μονογράμματο «στοιχ. Δ.» ή αριθμός «παρ. 1.» δεν κλείνουν πρόταση
                       (not (= (length word) 1))
                       (not (and (plusp (length word))
                                 (every #'digit-char-p word))))))))
    (let ((start (loop for i from (1- pos) downto 0
                       when (sentence-dot-p i) return (1+ i)
                       finally (return 0)))
          (end (loop for i from pos below (length text)
                     when (sentence-dot-p i) return (1+ i)
                     finally (return (length text)))))
      (values start end))))

(defparameter *ground-ordinals*
  '(("πρώτ" . 1) ("δεύτερ" . 2) ("δευτέρ" . 2) ("τρίτ" . 3) ("τέταρτ" . 4)
    ("πέμπτ" . 5) ("έκτ" . 6) ("έβδομ" . 7) ("όγδο" . 8) ("ένατ" . 9) ("δέκατ" . 10)))

(defun %ground-ordinal (sentence)
  "Ο αριθμός του λόγου όταν η πρόταση τον δηλώνει («ο τρίτος λόγος…»)."
  (loop for (stem . n) in *ground-ordinals*
        when (cl-ppcre:scan (format nil "~A\\w*\\s+(?:και\\s+\\w+\\s+)?λόγ" stem) sentence)
          return n))

(defun %ground-vehicle (sentence)
  "Το δικονομικό όχημα του λόγου, όπως το γράφει η πρόταση:
   ποινικά «άρθρο 510 παρ.1 στοιχ. Δ΄ ΚΠοινΔ», πολιτικά «από τον αριθμό 1
   του άρθρου 559 ΚΠολΔ». NIL όταν η πρόταση δεν το δηλώνει."
  (multiple-value-bind (m g)
      (cl-ppcre:scan-to-strings
       "άρθρου?\\s*(\\d+)\\s*(?:παρ\\.?\\s*(\\d+))?\\s*(?:στοιχ\\.?\\s*([Α-ΩΪΫ]['΄’]?(?:\\s*(?:και|,)\\s*[Α-ΩΪΫ]['΄’]?)*))?\\s*(?:του\\s+)?(ΚΠοινΔ|Κ\\.?Ποιν\\.?Δ\\.?|ΚΠΔ|ΚΠολΔ|Κ\\.?Πολ\\.?Δ\\.?)"
       sentence)
    (cond
      ;; «άρθρο 559 αρ. 19 Κ.Πολ.Δ.» — ο αριθμός του ΛΟΓΟΥ προηγείται: αυτό
      ;; είναι το όχημα, όχι η παραπεμπτική διάταξη «(άρθρο 580 παρ. 3)» που
      ;; συχνά κλείνει την ίδια πρόταση.
      ((multiple-value-bind (m2 g2)
           (cl-ppcre:scan-to-strings
            "άρθρου?\\s*(\\d+)\\s*(?:αρ|αριθ|αριθμ)\\.?\\s*(\\d+)\\s*(?:του\\s+)?(ΚΠολΔ|Κ\\.?Πολ\\.?Δ\\.?|ΚΠοινΔ|Κ\\.?Ποιν\\.?Δ\\.?|ΚΠΔ)?"
            sentence)
         (when m2
           (format nil "~A ~A αρ.~A"
                   (if (aref g2 2) (%normalize-tag (aref g2 2)) "ΚΠολΔ")
                   (aref g2 0) (aref g2 1)))))
      (m (format nil "~A ~A~@[§~A~]~@[ στοιχ.~A~]"
                 (%normalize-tag (aref g 3)) (aref g 0) (aref g 1)
                 (and (aref g 2) (cl-ppcre:regex-replace-all "\\s+" (aref g 2) " "))))
      ;; «από τον αριθμό 1 του άρθρου 559 ΚΠολΔ» — η αντίστροφη σειρά
      ((multiple-value-bind (m3 g3)
           (cl-ppcre:scan-to-strings
            "αριθμ[όο]ν?\\s*(\\d+)[^.]{0,40}?άρθρου\\s*(\\d+)(?:[^.]{0,20}?(ΚΠολΔ|ΚΠοινΔ|ΚΠΔ))?"
            sentence)
         (when m3
           (format nil "~A ~A αρ.~A"
                   (if (aref g3 2) (%normalize-tag (aref g3 2)) "ΚΠολΔ")
                   (aref g3 1) (aref g3 0))))))))

(defun %ground-verdict (sentence)
  "Η φορά της κρίσης — με τη σειρά ειδικότητας ώστε το «αβάσιμος» να μην
   διαβαστεί ποτέ ως «βάσιμος»."
  (cond ((cl-ppcre:scan "απαράδεκτ" sentence) :inadmissible)
        ((cl-ppcre:scan "αβάσιμ|απορριπτέ|απορριφθεί" sentence) :unfounded)
        ((cl-ppcre:scan "(?<![αΑ])βάσιμ|γίνει\\s+δεκτ|έγινε\\s+δεκτ" sentence) :accepted)))

;;; Η ετυμηγορία έχει ΥΠΟΚΕΙΜΕΝΟ — ποιος κρίνεται: ο λόγος; η αίτηση; ή η
;;; αγωγή/έφεση (δηλαδή αφήγηση του ιστορικού, ΟΧΙ κρίση του ΑΠ); Αυτή η
;;; απόδοση είναι στοιχειώδης σύνταξη, όχι λεξιθηρία: το πλησιέστερο στο
;;; ρήμα-ετυμηγορία κρινόμενο αντικείμενο είναι το υποκείμενό της.
(defparameter *judged-subjects*
  '(("λόγ" . :ground) ("αιτίασ" . :ground) ("ισχυρισμ" . :ground)
    ("αίτησ" . :petition) ("ένδικο μέσο" . :petition)
    ("αγωγ" . :narration) ("ανταγωγ" . :narration) ("έφεσ" . :narration))
  "στέλεχος-υποκειμένου → τι κρίνεται. Τα στελέχη γράφονται φυσικά και
   ταυτίζονται αναδιπλωμένα. Αγωγή/έφεση κρίνονται από τα δικαστήρια της
   ουσίας — στο σκεπτικό του ΑΠ η ετυμηγορία τους είναι ΑΦΗΓΗΣΗ ιστορικού.")

(defvar *narration-verb-words*
  (list "απέρριψε" "δέχθηκε" "εδέχθη" "έκρινε" "εξαφάνισε" "επιδίκασε")
  "Ρήματα σε ΑΟΡΙΣΤΟ: ο ΑΠ αφηγείται τι ΕΚΑΝΕ το δικαστήριο της ουσίας.
   Η δική του κρίση μιλά σε ενεστώτα/δεοντικό — η γραμματική του χρόνου
   διακρίνει αφήγηση από κρίση, όπως στον άνθρωπο αναγνώστη.")

(defvar *narration-scanner* nil
  "Χτίζεται από την λίστα — βλ. REBUILD-DECISION-SCANNERS.")

(defun rebuild-decision-scanners ()
  "Ξαναχτίσε τους scanners από τις δηλωτικές λίστες — καλείται στη φόρτωση
   ΚΑΙ από τα πακέτα γνώσης (:decision-grammar) όταν η γνώση μεγαλώνει,
   ζωντανά, χωρίς επαναμεταγλώττιση."
  (setf *ratio-scanner*
        (%folded-scanner
         (format nil "(?s)((?:~{~A~^|~})[^.]{40,600}?(?:~{~A~^|~})[^.]*\\.)"
                 *ratio-openers* *ratio-verdict-words*))
        *operative-verbs-scanner*
        (%folded-scanner (format nil "(?:~{~A~^|~})" *operative-verb-words*))
        *narration-scanner*
        (%folded-scanner (format nil "~{~A~^|~}" *narration-verb-words*)))
  t)

(rebuild-decision-scanners)

(defun %verdict-subject (folded-sentence verdict-pos)
  "ΤΟ ΥΠΟΚΕΙΜΕΝΟ της ετυμηγορίας: το πλησιέστερο στο ρήμα-ετυμηγορία
   κρινόμενο αντικείμενο. NIL όταν δεν βρίσκεται κανένα."
  (let (best best-dist)
    (loop for (stem . type) in *judged-subjects*
          do (let ((fstem (%fold stem)) (start 0))
               (loop for pos = (search fstem folded-sentence :start2 start)
                     while pos
                     do (let ((d (abs (- pos verdict-pos))))
                          (when (or (null best-dist) (< d best-dist))
                            (setf best type best-dist d))
                          (setf start (1+ pos))))))
    best))

(defun %ground-kind (sentence)
  "ΤΙ ΕΙΔΟΥΣ πρόταση είναι — η διάκριση που κάνει ο νομικός αναγνώστης:
   :petition       — κρίση για την ΙΔΙΑ την αίτηση (παραδεκτό/τελική τύχη),
   :legal-premise  — η ΜΕΙΖΩΝ νομική σκέψη: ο ΑΠ εκθέτει αφηρημένα πότε
                     ιδρύεται/απορρίπτεται ο λόγος, τυπικά με σωρεία
                     παραπομπών «(ΑΠ 162/2020, ΟλΑΠ 6/2006)» — νομολογιακή
                     θεωρία, ΟΧΙ κρίση επί της παρούσας υπόθεσης,
   :ruling         — η ΥΠΑΓΩΓΗ: η κρίση επί του λόγου ΑΥΤΗΣ της υπόθεσης.
   Ντετερμινιστικά σήματα, ποτέ μάντεμα — ο,τιδήποτε χωρίς σήμα μείζονος
   είναι κρίση (η ασφαλής προεπιλογή για τον χάρτη θέσεων)."
  (cond ((cl-ppcre:scan
          ;; η ετυμηγορία πρέπει να ΑΦΟΡΑ την αίτηση («η αίτηση είναι
          ;; παραδεκτή / πρέπει να απορριφθεί»), όχι απλώς να την μνημονεύει
          "α[ιί]τηση[ςν]?\\s+(?:αναίρεσ\\w*|αναιρέσ\\w*)?,?\\s*(?:είναι\\s+παραδεκτή|πρέπει\\s+να\\s+απορριφθεί)|συνεπώς\\s+παραδεκτή"
          sentence)
         :petition)
        ((and (or (cl-ppcre:scan "\\(\\s*(?:Ολ\\.?\\s?ΑΠ|ΟλΑΠ|ΑΠ)\\s*\\d+/\\d{4}" sentence)
                  (cl-ppcre:scan "ιδρύεται|στοιχειοθετείται|θεμελιώνεται" sentence))
              (not (cl-ppcre:scan "Στην\\s+προκε[ίι]μενη|εν\\s+προκειμένω|λόγος\\s+αυτός" sentence)))
         :legal-premise)
        (t :ruling)))

(defun decision-grounds (text)
  "Οι κρίσεις επί των λόγων αναιρέσεως, με αγκύρωση: λίστα plists
   (:vehicle V :ordinal N :verdict :accepted|:unfounded|:inadmissible
    :excerpt S :start I :end J), με τα offsets στο ΠΛΗΡΕΣ κείμενο.
   Πηγή ΜΟΝΟ το σκεπτικό (η ανατομία δίνει σκοπιμότητα). Πρόταση χωρίς
   αναφορά σε λόγο δεν μετρά — το διατακτικό το καλύπτει το operative."
  (let* ((structure (decision-structure text))
         (entry (assoc :reasoning structure)))
    (when entry
      (let ((base (second entry))
            (reasoning (subseq text (second entry) (third entry)))
            (out '()) (seen (make-hash-table)))
        (cl-ppcre:do-scans (ms me rs re *ground-verdict-scanner* reasoning)
          (declare (ignore me rs re))
          (multiple-value-bind (s e) (%sentence-bounds reasoning ms)
            (unless (gethash s seen)
              (setf (gethash s seen) t)
              (let* ((sentence (subseq reasoning s e))
                     (sfold (%fold sentence))
                     (subject (%verdict-subject sfold (- ms s))))
                ;; ΣΥΝΤΑΞΗ, όχι λεξιθηρία: (α) η ετυμηγορία πρέπει να έχει
                ;; κρινόμενο υποκείμενο (λόγο/αίτηση) — αγωγή/έφεση σημαίνει
                ;; αφήγηση ιστορικού· (β) ρήμα σε αόριστο = ο ΑΠ αφηγείται τι
                ;; έκανε το δικαστήριο της ουσίας, ΔΕΝ κρίνει ο ίδιος.
                (when (and (member subject '(:ground :petition))
                           (not (and (cl-ppcre:scan *narration-scanner* sfold)
                                     (not (cl-ppcre:scan (%fold "πρέπει\\s+να|απορριπτέ|είναι\\s+(?:αβάσιμ|βάσιμ|απαράδεκτ|παραδεκτ)")
                                                         sfold)))))
                  (let ((verdict (%ground-verdict sentence)))
                    (when verdict
                      (push (list :vehicle (%ground-vehicle sentence)
                                  :ordinal (%ground-ordinal sentence)
                                  :kind (if (eq subject :petition)
                                            :petition
                                            (%ground-kind sentence))
                                  :verdict verdict
                                  :excerpt (let ((clean (string-trim " " (cl-ppcre:regex-replace-all "\\s+" sentence " "))))
                                             (if (> (length clean) 300)
                                                 (concatenate 'string "…" (subseq clean (- (length clean) 300)))
                                                 clean))
                                  :start (+ base s) :end (+ base e))
                            out))))))))
        (nreverse out)))))

(defun parse-decision-text (text &key court number year source-file)
  "Parse decision TEXT into a LEGAL-DECISION. COURT/NUMBER/YEAR come from the
   filename convention (identity never depends on parsing); the parsed
   «Αριθμός απόφασης N/YYYY» line cross-checks them — a mismatch is a
   hard error, not a warning, because a misfiled decision poisons analytics."
  (multiple-value-bind (m g)
      (cl-ppcre:scan-to-strings "Αριθμός\\s+[Αα]πόφασης\\s+(\\d+)\\s*/\\s*(\\d{4})" text)
    (when (and m number year)
      (unless (and (string= (aref g 0) (princ-to-string number))
                   (string= (aref g 1) (princ-to-string year)))
        (error "Η απόφαση δηλώνει ~A/~A αλλά το αρχείο ονομάζεται ~A/~A — λάθος αρχειοθέτηση"
               (aref g 0) (aref g 1) number year))))
  (make-instance 'legal-decision
                 :court court :number number :year year
                 :chamber (%parse-chamber text)
                 :summary (%parse-summary text)
                 :judges (%parse-judges text)
                 :citations (%parse-citations text)
                 :operative (%parse-operative text)
                 :body-text text
                 :source-file source-file))

(defun decision->json-alist (d &key citation-status)
  "Serialize D to the alist ARTICLES->JSON understands. CITATION-STATUS, when
   given, is a function (citation-entry) → plist with the temporal verdict
   (:corpus :exists :article-date :verdict) computed by the caller against the
   served codes — kept outside so this module stays pure."
  (list
   (cons "court" (decision-court d))
   (cons "number" (princ-to-string (decision-number d)))
   (cons "year" (princ-to-string (decision-year d)))
   (cons "chamber" (or (decision-chamber d) :null))
   (cons "summary" (or (decision-summary d) :null))
   (cons "judges"
         (mapcar (lambda (j)
                   (list (cons "name" (judge-name j))
                         (cons "role" (judge-role j))
                         (cons "rapporteur" (if (judge-rapporteur-p j) t :false))))
                 (decision-judges d)))
   (cons "operative" (or (decision-operative d) #()))
   ;; Η ΑΝΑΤΟΜΙΑ: κάθε δομικό μέρος με τα όριά του μέσα στο κείμενο — ώστε κάθε
   ;; μεταγενέστερη ανάλυση να ψάχνει στο ΣΩΣΤΟ μέρος, όχι στον χυλό.
   (cons "structure"
         (or (loop for (sec start end) in (decision-structure (decision-body-text d))
                   collect (list (cons "section" (string-downcase (symbol-name sec)))
                                 (cons "start" start) (cons "end" end)))
             #()))
   ;; Το ratio decidendi ΟΠΩΣ το λέει η απόφαση (verbatim) — απόδειξη, όχι περίληψη.
   (cons "ratio_evidence" (or (decision-ratio (decision-body-text d)) :null))
   ;; ΟΙ ΛΟΓΟΙ ΚΑΙ Η ΤΥΧΗ ΤΟΥΣ — η κατανόηση σε βάθος, κάθε κρίση με την
   ;; πρόταση-απόδειξη και τα offsets της μέσα στο κείμενο.
   (cons "grounds"
         (or (mapcar (lambda (gr)
                       (list (cons "vehicle" (or (getf gr :vehicle) :null))
                             (cons "ordinal" (or (getf gr :ordinal) :null))
                             (cons "kind" (string-downcase (symbol-name (getf gr :kind))))
                             (cons "verdict" (string-downcase (symbol-name (getf gr :verdict))))
                             (cons "excerpt" (getf gr :excerpt))
                             (cons "start" (getf gr :start))
                             (cons "end" (getf gr :end))))
                     (decision-grounds (decision-body-text d)))
             #()))
   (cons "citations"
         (mapcar (lambda (c)
                   (append
                    (list (cons "law" (or (citation-law-tag c) :null))
                          (cons "law_inferred" (if (citation-tag-inferred-p c) t :false))
                          (cons "article" (citation-article c))
                          (cons "paragraph" (or (citation-paragraph c) :null)))
                    (when citation-status (funcall citation-status c))))
                 (decision-citations d)))
   (cons "source_file" (princ-to-string (decision-source-file d)))))
