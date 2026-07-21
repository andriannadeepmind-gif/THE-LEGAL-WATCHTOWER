;;;; source/safe-read.lisp
;;;; ============================================================================
;;;; Η ΜΙΑ ΕΔΡΑ ΑΣΦΑΛΟΥΣ ΑΠΟΣΕΡΙΑΛΟΠΟΙΗΣΗΣ ΔΕΔΟΜΕΝΩΝ ([0094]/Phase 1)
;;;; ============================================================================
;;;;
;;;; ΜΙΑ έδρα για ΚΑΘΕ ανάγνωση data-only s-expressions. Κανένα bare `read`/
;;;; `read-from-string` σε data path εκτός από ΕΔΩ (η πύλη επανεισαγωγής το επιβάλλει).
;;;; Ο κίνδυνος εκτέλεσης κώδικα γίνεται ΔΟΜΙΚΑ αδύνατος, όχι φυλασσόμενος:
;;;;
;;;;   • *read-eval* NIL           — ο ΤΟΙΧΟΣ κατά RCE (#. δεν εκτελείται).
;;;;   • +data-readtable+          — ΟΛΙΚΗ απαγόρευση του `#` dispatch (ΟΧΙ ανά-subchar
;;;;                                 whitelist-of-denials· wholesale macro-char override
;;;;                                 ⇒ κάθε #-σύνταξη = error, ενώ `#` ΜΕΣΑ σε strings
;;;;                                 και απλές λίστες μένουν άθικτα)· + `` ` `` και `,`
;;;;                                 απαγορευμένα (quasiquote = code-template, όχι data).
;;;;   • όριο ΒΑΘΟΥΣ με linear pre-scan ΠΡΙΝ τον reader — το byte-cap ΔΕΝ φράζει βάθος
;;;;                                 (deep-nest ⇒ control-stack-exhausted). Δομικός φραγμός.
;;;;   • byte-cap                  — φράζει το ΕΡΓΟ (μέγεθος εισόδου).
;;;;   • *read-default-float-format* ΣΤΑΘΕΡΟ 'double-float — η μία κανονική μορφή όλων των
;;;;                                 data stores (καμία σιωπηλή double↔single απώλεια = hash drift).
;;;;   • *package* ΣΤΑΘΕΡΟ :keyword — ΚΑΝΕΝΑ arbitrary package/symbol (συνταγματικό όριο):
;;;;                                 data-only = keywords/strings/numbers/lists. Οι σημασιολογικές
;;;;                                 ικανότητες έχουν ΧΩΡΙΣΤΟΥΣ typed decoders πάνω από αυτό.
;;;;   • one-form EOF law          — ακριβώς ΕΝΑ top-level form· δεύτερο ⇒ :trailing.
;;;;   • resource-condition policy  — storage-condition ⇒ :resource-exhausted· άλλο ⇒ :unreadable.
;;;;   • ΜΗΔΕΝ global μεταβολή      — *readtable*/*package* ΜΟΝΟ dynamically bound (let), ποτέ setf.
;;;;
;;;; ΣΥΝΤΑΓΜΑΤΙΚΟ ΟΡΙΟ ([0094], εντολή δημιουργού): ΕΛΑΧΙΣΤΟ ΕΣΩΤΕΡΙΚΟ primitive — ΟΧΙ public
;;;; ingestion boundary, ΟΧΙ canonical transport, ΟΧΙ γενική persistence. ΑΠΑΓΟΡΕΥΕΤΑΙ: Internet/
;;;; HTML/PDF/OCR/LLM raw input· arbitrary packages/symbols· universal parser με αυξανόμενα flags·
;;;; νέο μη-versioned format· πέρασμα in-memory object untrusted→trusted· canonical write/publication.
;;;; Οι αριθμοί-scalar πάνε σε ξεχωριστό numeric parser· το journal κρατά τον δικό του tolerant loop.
;;;; Κάθε πραγματική ικανότητα (BPE/trace/component/journal) αποκτά ΔΙΚΟ της typed decoder πάνω από
;;;; αυτά τα primitives — αυτό ΔΕΝ γίνεται god-reader με σημασιολογικά flags.
;;;;
;;;; Δεν εξαρτάται από ΤΙΠΟΤΑ πλην :cl (καμία κυκλική εξάρτηση: σταθερά caps, path-ως-όρισμα,
;;;; μηδέν audit/time/spec). Φορτώνεται ΠΡΩΤΟ στο orchestrator-infrastructure.

(defpackage :orchestrator.safe-read
  (:use :cl)
  (:export #:read-data-file #:read-data-string #:read-data-file-sequence
           #:read-data-form #:data-to-string #:canonicalize-bool
           #:safe-read-error #:safe-read-error-why
           #:*max-data-bytes* #:*max-data-depth* #:*max-data-atoms*
           #:max-paren-depth #:prescan-depth-atoms))

(in-package :orchestrator.safe-read)

;;; ── Παράμετροι (σταθερές — ΚΑΜΙΑ εξάρτηση από config/spec: bootstrap paradox) ──

(defparameter *max-data-bytes* (* 64 1024 1024)
  "Ανώτατο μέγεθος εισόδου (bytes). Φράζει το ΕΡΓΟ ανάγνωσης. Resource limit· οι callers
   μπορούν να περάσουν αυστηρότερο :max-bytes ανά store.")

(defparameter *max-data-depth* 2000
  "Ανώτατο βάθος ένθεσης παρενθέσεων. Φράζει τη ΑΝΑΔΡΟΜΗ του reader ΠΡΙΝ αυτή συμβεί
   (deep-nest ⇒ control-stack-exhausted). Νόμιμα δεδομένα: βάθος ~10-50· 2000 = άφθονο
   περιθώριο, πολύ κάτω από το κατώφλι υπερχείλισης (~100k).")

(defparameter *max-data-atoms* 4000000
  "[audit#4 / re-review B-2] Ανώτατο πλήθος ATOMS (tokens) — ΑΝΩ ΦΡΑΓΜΑ των συμβόλων που
   ο reader θα intern-άρει. Το intern side-effect (keywords μένουν ΜΟΝΙΜΑ στο keyword
   package) φραζόταν ΜΟΝΟ από το byte-cap (~32M tokens σε 64MB) — σωρευτικά απεριόριστο.
   Τώρα ο linear pre-scan μετρά atoms ΠΡΙΝ τον reader· υπέρβαση ⇒ :too-many-atoms ⇒ ΚΑΝΕΝΑ
   intern (το read δεν τρέχει καν). Νόμιμα data stores: ~10²–10⁴ atoms· 4·10⁶ = άφθονο
   περιθώριο, με τους callers να περνούν αυστηρότερο :max-atoms ανά store.")

(define-condition safe-read-error (error)
  ((why :initarg :why :reader safe-read-error-why :initform "μη αναγνώσιμο"))
  (:report (lambda (c s) (format s "safe-read: ~A" (safe-read-error-why c)))))

;;; ── Ο data-only reader: ΟΛΙΚΗ απαγόρευση #, backquote, comma ──

(defun %deny (stream char)
  "Reader-macro που ΑΡΝΕΙΤΑΙ κάθε μη-data σύνταξη. Το μοτίβο κατασκευάζεται στο μήνυμα
   ώστε ΑΥΤΟ το αρχείο να μην φέρει το literal που ανιχνεύει."
  (declare (ignore stream))
  (error 'safe-read-error
         :why (format nil "reader-macro '~A' εκτός data-only υποσυνόλου (καμία #-σύνταξη/quasiquote)"
                      char)))

(defparameter +data-readtable+
  (let ((rt (copy-readtable nil)))
    ;; wholesale: το `#` ΠΑΝΤΑ σφάλλει ως macro char (non-terminating-p T ⇒ `#` μέσα
    ;; σε strings/tokens δεν επηρεάζεται). Καλύπτει #. #= ## #S #A #( #* #\ #: #' #+ #-
    ;; #B #O #X #R #C #P #| — ΟΛΑ — χωρίς enumeration (η enumeration ξεχνά ⇒ φρουρός).
    (set-macro-character #\# #'%deny t rt)
    ;; quasiquote/comma/quote: `(a ,b) και 'x ⇒ code-template, ΟΧΙ data. Απαγόρευση
    ;; (comma ήδη σφάλλει εκτός backquote· backquote/quote σιωπηλά ⇒ ρητή απαγόρευση).
    ;; [re-review adv2-F4] Το quote ΗΤΑΝ ζωντανό: 'x ⇒ (quote <recursive-read>), άρα ένα
    ;; run από N απανωτά «'» οδηγούσε τον reader N frames βαθιά ΕΝΩ ο pre-scan (που δεν
    ;; μετρά το quote) ανέφερε depth 0 ⇒ ο δηλωμένος «δομικός φραγμός βάθους» ΠΑΡΑΚΑΜΠΤΟΤΑΝ
    ;; (control-stack-exhausted, πιανόταν μόνο από το storage-condition backstop, όχι δομικά).
    ;; Τώρα το «'» σφάλλει ΑΜΕΣΩΣ ως macro-char (καμία αναδρομή)· το quote ήταν έτσι κι
    ;; αλλιώς μη-data (θα το απέρριπτε ο %data-only-p) — τώρα απορρίπτεται ΠΡΙΝ την αναδρομή.
    (set-macro-character #\` #'%deny nil rt)
    (set-macro-character #\, #'%deny nil rt)
    (set-macro-character #\' #'%deny nil rt)
    rt)
  "Data-only readtable: ό,τι δεν είναι απλό datum (list/keyword/string/number), αρνείται.")

(defvar +eof+ '#:safe-read-eof "Μοναδικό sentinel για EOF (eq-σύγκριση).")

;;; ── Δομικός φραγμός βάθους: linear pre-scan (string→max paren depth) ──

(defun prescan-depth-atoms (s)
  "ΕΝΑΣ linear pass ΠΡΙΝ τον reader: (values max-paren-depth atom-count). Σωστό state
   machine: αγνοεί παρενθέσεις/tokens μέσα σε \"strings\", ; line-comments, και μετά
   single \\ escape· τα |multi-escape| ανήκουν στο τρέχον symbol token.
     • max-paren-depth — φράζει την ΑΝΑΔΡΟΜΗ του reader δομικά.
     • atom-count — ΑΝΩ ΦΡΑΓΜΑ των tokens (άρα των πιθανών interned symbols): μετρά
       token-starts σε :normal (strings/comments/whitespace/quotes ΔΕΝ ξεκινούν token).
       Over-approximation (numbers/strings μετρώνται κι αυτά) — ασφαλές cap (μόνο νωρίτερη
       απόρριψη, ποτέ διαφυγή)."
  (let ((depth 0) (mx 0) (atoms 0) (i 0) (n (length s)) (state :normal) (in-token nil))
    (macrolet ((token-start ()
                 '(unless in-token (incf atoms) (setf in-token t))))
      (loop while (< i n) do
        (let ((c (char s i)))
          (ecase state
            (:normal
             (case c
               (#\" (setf in-token nil state :string))
               (#\; (setf in-token nil state :comment))
               (#\| (token-start) (setf state :multi))
               (#\\ (token-start) (incf i))               ; single-escape token char
               ((#\Space #\Tab #\Newline #\Return #\Page) (setf in-token nil))
               (#\( (setf in-token nil) (incf depth) (when (> depth mx) (setf mx depth)))
               (#\) (setf in-token nil) (when (> depth 0) (decf depth)))
               ((#\' #\` #\,) (setf in-token nil))        ; separators (απαγορευμένα στον reader)
               (t (token-start))))                        ; constituent ⇒ token
            (:string
             (case c (#\\ (incf i)) (#\" (setf state :normal))))
            (:comment
             (when (char= c #\Newline) (setf state :normal)))
            (:multi
             (case c (#\\ (incf i)) (#\| (setf state :normal))))))  ; symbol συνεχίζεται
        (incf i)))
    (values mx atoms)))

(defun max-paren-depth (s)
  "Μέγιστο βάθος ΕΝΘΕΣΗΣ παρενθέσεων στο S (πρώτη τιμή του prescan-depth-atoms)."
  (values (prescan-depth-atoms s)))

;;; ── Πυρήνας: το ΜΟΝΑΔΙΚΟ σημείο cl:read σε data path (keyword + double, σταθερά) ──

(defun %classify (c)
  "RESOURCE-CONDITION POLICY: storage-condition (μνήμη/στοίβα/χώρος) ⇒ :resource-exhausted·
   κάθε άλλη serious-condition ⇒ :unreadable."
  (if (typep c 'storage-condition) :resource-exhausted :unreadable))

(defmacro %with-data-env (&body body)
  "Εγκαθιστά ΤΟ data-only δυναμικό περιβάλλον (ΣΤΑΘΕΡΟ: keyword + double· καμία παράμετρος =
   κανένα semantic flag). ΜΟΝΟ dynamic binding (let) — μηδέν global μεταβολή. Εντός, ΜΟΝΟ το
   %read-one καλεί cl:read."
  `(let ((*read-eval* nil)
         (*readtable* +data-readtable+)
         (*read-default-float-format* 'double-float)
         (*package* (load-time-value (find-package :keyword))))
     ,@body))

(declaim (inline %read-one))
(defun %read-one (stream)
  "Το ΜΟΝΑΔΙΚΟ cl:read της αρχιτεκτονικής σε data path. Επιστρέφει form ή +eof+."
  (read stream nil +eof+))

;;; ── Δομικός φραγμός symbol-smuggling ([audit#4]): ΟΛΙΚΟΣ data-only έλεγχος ──

(defun %data-only-p (form)
  "T αν το FORM είναι ΑΜΙΓΩΣ data-only: κάθε atom ∈ {keyword, string, number, NIL, T},
   κάθε cons αναδρομικά data-only. ΑΠΟΡΡΙΠΤΕΙ ΟΠΟΙΟΔΗΠΟΤΕ ξένο σύμβολο (π.χ. CL-USER::FOO,
   SOMEPKG:BAR): αν και *package* :keyword δίνει keywords για bare tokens, ΡΗΤΑ
   package-qualified tokens (`pkg::sym`, `pkg:sym`) μπορούν να δείξουν/intern-άρουν σε
   ΥΠΑΡΧΟΝ package κατά το read. Αυτός ο ΟΛΙΚΟΣ (total) έλεγχος στο ΑΠΟΤΕΛΕΣΜΑ εγγυάται
   ΔΟΜΙΚΑ ότι κανένα τέτοιο σύμβολο δεν διαφεύγει στον caller — το data-only contract
   επιβάλλεται στην έξοδο, ΟΧΙ με εύθραυστο token pre-scan (που τα |multi-escape|+colon
   combos σπάνε). Το interning side-effect κατά το read είναι φραγμένο από το byte-cap
   (καμία απεριόριστη μνήμη) και ΑΔΡΑΝΕΣ (κανένα eval: *read-eval* NIL)."
  (typecase form
    (null    t)                 ; NIL (και η κενή λίστα)
    (keyword t)
    (symbol  (eq form t))       ; από τα ΜΗ-keyword σύμβολα ΜΟΝΟ το T επιτρέπεται
    (string  t)
    (number  t)
    (cons    (and (%data-only-p (car form)) (%data-only-p (cdr form))))
    (t       nil)))             ; ό,τι άλλο = fail-closed (δεν φτάνει εδώ υπό τη readtable)

(defun %utf8-byte-length (string)
  "Πλήθος UTF-8 BYTES του STRING (όχι χαρακτήρων) — ο byte-cap μετρά bytes, ίδια μονάδα
   με το file-length του αρχείου ([audit#5]: Unicode string μπορεί να έχει πολλαπλάσια
   bytes από χαρακτήρες). [re-review B-4] Άθροισμα ανά-char code-point width — ΧΩΡΙΣ
   allocation ενδιάμεσου octet vector (το παλιό string-to-octets δέσμευε ολόκληρο buffer
   μόνο για το length· εδώ ο byte-cap ελέγχεται με σταθερή μνήμη)."
  (let ((n 0))
    (declare (type unsigned-byte n))
    (loop for ch across string
          for c = (char-code ch)
          do (incf n (cond ((< c #x80) 1) ((< c #x800) 2) ((< c #x10000) 3) (t 4))))
    n))

;;; ── Δημόσιο API: ΕΛΑΧΙΣΤΑ primitives (καμία σημασιολογική παράμετρος) ──

(defun read-data-form (stream)
  "Διάβασε ΕΝΑ top-level form από ανοιχτό STREAM (streaming primitive — για tolerant resync
   loops όπως το journal). (values form status), status ∈ {:ok :eof :unreadable
   :resource-exhausted}. Σε :unreadable αφήνει το stream χρησιμοποιήσιμο (ο caller κάνει
   read-line resync). ΣΗΜΕΙΩΣΗ: εδώ το βάθος φράζεται από το backstop (storage-condition),
   όχι pre-scan — τα ΜΗ-έμπιστα-εξωτερικά ΟΛΟΚΛΗΡΑ αρχεία περνούν από read-data-file/-string
   (pre-scanned)· το streaming primitive αφορά self-written journals."
  (%with-data-env
    (handler-case
        (let ((form (%read-one stream)))
          (if (eq form +eof+) (values nil :eof) (values form :ok)))
      (safe-read-error () (values nil :unreadable))
      (storage-condition (c) (values nil (%classify c)))
      (serious-condition () (values nil :unreadable)))))

(defun %decode-one (content max-depth max-atoms)
  "One-form EOF law πάνω σε ΟΛΟΚΛΗΡΟ string (μετά byte-cap). (values form status), status ∈
   {:ok :empty :trailing :too-deep :too-many-atoms :unreadable :disallowed-symbol :resource-exhausted}."
  (multiple-value-bind (depth atoms) (prescan-depth-atoms content)
    (when (> depth max-depth)  (return-from %decode-one (values nil :too-deep)))
    (when (> atoms max-atoms) (return-from %decode-one (values nil :too-many-atoms))))
  (%with-data-env
    (handler-case
        (with-input-from-string (s content)
          (let ((form (%read-one s)))
            (cond ((eq form +eof+) (values nil :empty))
                  ((not (eq (%read-one s) +eof+)) (values form :trailing))
                  ((not (%data-only-p form)) (values nil :disallowed-symbol))
                  (t (values form :ok)))))
      (safe-read-error () (values nil :unreadable))
      (storage-condition (c) (values nil (%classify c)))
      (serious-condition () (values nil :unreadable)))))

(defun %decode-sequence (content max-depth max-atoms)
  "ΟΛΑ τα top-level forms (all-or-error· ΟΧΙ resync — αυτό είναι policy του journal). (values
   list status), status ∈ {:ok :too-deep :too-many-atoms :unreadable :disallowed-symbol :resource-exhausted}."
  (multiple-value-bind (depth atoms) (prescan-depth-atoms content)
    (when (> depth max-depth)  (return-from %decode-sequence (values nil :too-deep)))
    (when (> atoms max-atoms) (return-from %decode-sequence (values nil :too-many-atoms))))
  (%with-data-env
    (handler-case
        (with-input-from-string (s content)
          (let ((forms '()))
            (loop for form = (%read-one s)
                  until (eq form +eof+)
                  do (push form forms))
            (let ((all (nreverse forms)))
              (if (every #'%data-only-p all)
                  (values all :ok)
                  (values nil :disallowed-symbol)))))
      (safe-read-error () (values nil :unreadable))
      (storage-condition (c) (values nil (%classify c)))
      (serious-condition () (values nil :unreadable)))))

(defun %slurp (path max-bytes)
  "Διάβασε το PATH ως UTF-8 string, με byte-cap ΠΡΙΝ την ανάγνωση.
   (values content status): :absent, :too-large, :unreadable, :resource-exhausted, :present."
  (unless (probe-file path) (return-from %slurp (values nil :absent)))
  (let ((size (ignore-errors
               (with-open-file (s path :element-type '(unsigned-byte 8))
                 (file-length s)))))
    (when (and size (> size max-bytes))
      (return-from %slurp (values nil :too-large)))
    (handler-case
        (with-open-file (s path :external-format :utf-8)
          (let* ((len (or (file-length s) 0))
                 (buf (make-string len))
                 (n (read-sequence buf s)))
            (values (if (= n len) buf (subseq buf 0 n)) :present)))
      (storage-condition (c) (values nil (%classify c)))
      (serious-condition () (values nil :unreadable)))))

(defun read-data-file (path &key (max-bytes *max-data-bytes*) (max-depth *max-data-depth*)
                                 (max-atoms *max-data-atoms*))
  "Διάβασε ΕΝΑ top-level data form από αρχείο PATH. (values form status), status ∈
   {:ok :empty :trailing :too-large :too-deep :too-many-atoms :unreadable :disallowed-symbol :resource-exhausted}.
   Απόν αρχείο ⇒ (values NIL :empty). Μη-έμπιστο εξωτερικό: pre-scanned βάθος+atoms + byte-cap +
   ΟΛΙΚΟΣ data-only έλεγχος (:disallowed-symbol σε ξένο package-qualified σύμβολο)."
  (multiple-value-bind (content st) (%slurp path max-bytes)
    (case st
      (:absent    (values nil :empty))
      (:too-large (values nil :too-large))
      (:unreadable (values nil :unreadable))
      (:resource-exhausted (values nil :resource-exhausted))
      (t (%decode-one content max-depth max-atoms)))))

(defun read-data-string (string &key (max-bytes *max-data-bytes*) (max-depth *max-data-depth*)
                                     (max-atoms *max-data-atoms*))
  "Διάβασε ΕΝΑ top-level data form από STRING. Ίδιες εγγυήσεις/status με read-data-file.
   [audit#5] Το byte-cap μετρά UTF-8 BYTES (όχι χαρακτήρες) — ΙΔΙΑ μονάδα με το file-length
   του read-data-file· ένα Unicode string μπορεί να καταλαμβάνει πολλαπλάσια bytes."
  (if (> (%utf8-byte-length string) max-bytes)
      (values nil :too-large)
      (%decode-one string max-depth max-atoms)))

(defun read-data-file-sequence (path &key (max-bytes *max-data-bytes*) (max-depth *max-data-depth*)
                                          (max-atoms *max-data-atoms*))
  "Διάβασε ΟΛΑ τα top-level data forms ενός αρχείου (all-or-error). (values list status), status ∈
   {:ok :empty :too-large :too-deep :too-many-atoms :unreadable :disallowed-symbol :resource-exhausted}."
  (multiple-value-bind (content st) (%slurp path max-bytes)
    (case st
      (:absent    (values nil :empty))
      (:too-large (values nil :too-large))
      (:unreadable (values nil :unreadable))
      (:resource-exhausted (values nil :resource-exhausted))
      (t (%decode-sequence content max-depth max-atoms)))))

;;; ── Η ΜΙΑ έδρα DATA-ONLY ΕΓΓΡΑΦΗΣ (συμμετρική της ανάγνωσης) ──

(defun data-to-string (form &key (max-bytes *max-data-bytes*))
  "Canonical DATA-ONLY serialization: FORM → string που το read-data-string ξαναδιαβάζει
   ΑΚΕΡΑΙΟ. Η ΜΙΑ έδρα εγγραφής, συμμετρική της ΜΙΑΣ έδρας ανάγνωσης — κάθε persistence
   writer (trace/AST/BPE) περνά από ΕΔΩ, ώστε το «τι γράφεται» να είναι δομικά ό,τι «μπορεί
   να διαβαστεί». Εγγυήσεις:
     • %data-only-p ΠΡΙΝ την εγγραφή — fail-closed: ΠΟΤΕ δεν γράφεται μη-data-only form
       (κανένα constructor symbol/package-qualified που ο reader θα απέρριπτε)·
     • *print-readably* NIL — ΚΡΙΣΙΜΟ: specialized (simple-array base-char) strings (π.χ.
       από format-παραγόμενα ids) τυπώνονται ως «#A(…)» array-literals υπό readable printing,
       που η +data-readtable+ (#-deny) ΑΠΟΡΡΙΠΤΕΙ ⇒ round-trip έσπαγε (:unreadable)· εδώ
       τυπώνονται ως απλά \"…\" strings·
     • keyword package + double-float — ΙΔΙΑ κανονική μορφή με τον reader (καμία drift)·
     • όχι pretty/circle — ντετερμινιστικό, χωρίς #N= sharing markers·
     • byte-cap στο ΑΠΟΤΕΛΕΣΜΑ (ίδιο όριο με την ανάγνωση)."
  (unless (%data-only-p form)
    (error 'safe-read-error :why
           "data-to-string: μη data-only form (μόνο keywords/strings/numbers/lists/t/nil)"))
  (let ((s (with-output-to-string (out)
             (with-standard-io-syntax
               (let ((*package* (load-time-value (find-package :keyword)))
                     (*print-readably* nil)
                     (*print-pretty* nil)
                     (*print-circle* nil)
                     (*read-default-float-format* 'double-float))
                 (prin1 form out))))))
    (when (> (%utf8-byte-length s) max-bytes)
      (error 'safe-read-error :why "data-to-string: υπέρβαση byte-cap"))
    s))

;;; ── Boolean canonicalization (ΜΙΑ έδρα· από %ebg-canon-bool) ──

(defun canonicalize-bool (v)
  "ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ boolean αμέσως μετά το read: :t/t ⇒ t· :nil/nil ⇒ nil (και τα δύο
   έγκυρα)· ΟΤΙΔΗΠΟΤΕ ΑΛΛΟ ⇒ (values nil nil). ΚΡΙΣΙΜΟ υπό *package* :keyword όπου bare
   nil ⇒ :nil (truthy) — ο consumer καλεί αυτό για να μη γίνει silent-boolean bug."
  (cond ((or (eq v t) (eq v :t))    (values t t))
        ((or (null v) (eq v :nil))  (values nil t))
        (t                          (values nil nil))))
