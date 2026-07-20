;;;; source/safe-read.lisp
;;;; ============================================================================
;;;; Η ΜΙΑ ΕΔΡΑ ΑΣΦΑΛΟΥΣ ΑΠΟΣΕΡΙΑΛΟΠΟΙΗΣΗΣ ΔΕΔΟΜΕΝΩΝ ([0094]/Phase 1)
;;;; ============================================================================
;;;;
;;;; ΜΙΑ έδρα για ΚΑΘΕ ανάγνωση εξωτερικών/μη-έμπιστων s-expressions. Κανένα bare
;;;; `read`/`read-from-string` σε data path εκτός από ΕΔΩ (η πύλη επανεισαγωγής το
;;;; επιβάλλει). Ο κίνδυνος εκτέλεσης κώδικα γίνεται ΔΟΜΙΚΑ αδύνατος, όχι φυλασσόμενος:
;;;;
;;;;   • *read-eval* NIL           — το ΤΟΙΧΟΣ κατά RCE (#. δεν εκτελείται).
;;;;   • +data-readtable+          — ΟΛΙΚΗ απαγόρευση του `#` dispatch (ΟΧΙ ανά-subchar
;;;;                                 whitelist-of-denials· wholesale macro-char override
;;;;                                 ⇒ κάθε #-σύνταξη = error, ενώ `#` ΜΕΣΑ σε strings
;;;;                                 και απλές λίστες μένουν άθικτα)· + `` ` `` και `,`
;;;;                                 απαγορευμένα (quasiquote = code-template, όχι data).
;;;;   • όριο ΒΑΘΟΥΣ με linear pre-scan ΠΡΙΝ τον reader — το byte-cap ΔΕΝ φράζει βάθος
;;;;                                 (deep-nest ⇒ control-stack-exhausted). Δομικός φραγμός.
;;;;   • byte-cap                  — φράζει το ΕΡΓΟ (μέγεθος εισόδου).
;;;;   • *read-default-float-format* παραμετρικό (default double) — καμία σιωπηλή απώλεια
;;;;                                 ακρίβειας (double↔single ⇒ hash mismatch = υποβιβασμός).
;;;;   • *package* παραμετρικό (default :keyword) — διατηρεί την ΑΚΡΙΒΩΣ ίδια συμπεριφορά
;;;;                                 κάθε υπάρχοντος reader (καμία σιωπηλή reinterning).
;;;;   • one-form EOF law          — ακριβώς ΕΝΑ top-level form· δεύτερο ⇒ :trailing.
;;;;   • resource-condition policy  — storage-condition ⇒ :resource-exhausted· άλλο ⇒ :unreadable.
;;;;
;;;; Δεν εξαρτάται από ΤΙΠΟΤΑ πλην :cl (καμία κυκλική εξάρτηση: σταθερά caps, path-ως-όρισμα,
;;;; μηδέν audit/time/spec). Φορτώνεται ΠΡΩΤΟ στο orchestrator-infrastructure.

(defpackage :orchestrator.safe-read
  (:use :cl)
  (:export #:read-data-file #:read-data-string #:read-data-file-sequence
           #:read-data-form #:canonicalize-bool
           #:safe-read-error #:safe-read-error-why
           #:*max-data-bytes* #:*max-data-depth* #:max-paren-depth))

(in-package :orchestrator.safe-read)

;;; ── Παράμετροι (σταθερές — ΚΑΜΙΑ εξάρτηση από config/spec: bootstrap paradox) ──

(defparameter *max-data-bytes* (* 64 1024 1024)
  "Ανώτατο μέγεθος εισόδου (bytes). Φράζει το ΕΡΓΟ ανάγνωσης. Οι callers μπορούν να
   περάσουν μικρότερο/μεγαλύτερο :max-bytes ανά store.")

(defparameter *max-data-depth* 2000
  "Ανώτατο βάθος ένθεσης παρενθέσεων. Φράζει τη ΑΝΑΔΡΟΜΗ του reader ΠΡΙΝ αυτή συμβεί
   (deep-nest ⇒ control-stack-exhausted). Νόμιμα δεδομένα: βάθος ~10-50· 2000 = άφθονο
   περιθώριο, πολύ κάτω από το κατώφλι υπερχείλισης (~100k).")

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
    ;; quasiquote/comma: `(a ,b) ⇒ code-template, ΟΧΙ data. Απαγόρευση (comma ήδη
    ;; σφάλλει εκτός backquote· backquote σιωπηλό ⇒ ρητή απαγόρευση).
    (set-macro-character #\` #'%deny nil rt)
    (set-macro-character #\, #'%deny nil rt)
    rt)
  "Data-only readtable: ό,τι δεν είναι απλό datum (list/keyword/string/number), αρνείται.")

(defvar +eof+ '#:safe-read-eof "Μοναδικό sentinel για EOF (eq-σύγκριση).")

;;; ── Δομικός φραγμός βάθους: linear pre-scan (string→max paren depth) ──

(defun max-paren-depth (s)
  "Μέγιστο βάθος ΕΝΘΕΣΗΣ παρενθέσεων στο S, με σωστό state machine: αγνοεί παρενθέσεις
   μέσα σε \"strings\", ; line-comments, |multi-escape| symbols, και μετά single \\ escape.
   Τρέχει ΠΡΙΝ τον reader — φράζει την αναδρομή δομικά (όχι με catch storage-condition)."
  (let ((depth 0) (mx 0) (i 0) (n (length s)) (state :normal))
    (loop while (< i n) do
      (let ((c (char s i)))
        (ecase state
          (:normal
           (case c
             (#\" (setf state :string))
             (#\; (setf state :comment))
             (#\| (setf state :multi))
             (#\\ (incf i))                    ; single-escape: προσπέρασε τον επόμενο
             (#\( (incf depth) (when (> depth mx) (setf mx depth)))
             (#\) (when (> depth 0) (decf depth)))))
          (:string
           (case c (#\\ (incf i)) (#\" (setf state :normal))))
          (:comment
           (when (char= c #\Newline) (setf state :normal)))
          (:multi
           (case c (#\\ (incf i)) (#\| (setf state :normal))))))
      (incf i))
    mx))

;;; ── Πυρήνας: το ΜΟΝΑΔΙΚΟ σημείο cl:read σε data path ──

(defun %classify (c)
  "RESOURCE-CONDITION POLICY: storage-condition (μνήμη/στοίβα/χώρος) ⇒ :resource-exhausted·
   κάθε άλλη serious-condition ⇒ :unreadable."
  (if (typep c 'storage-condition) :resource-exhausted :unreadable))

(defun %resolve-package (package)
  (etypecase package
    (null *package*)                            ; :package NIL ⇒ κράτα το package του caller
    ((or string symbol keyword)
     (or (find-package package)
         (error 'safe-read-error :why (format nil "άγνωστο package ~S" package))))
    (package package)))

(defmacro %with-data-env ((float-format package) &body body)
  "Εγκαθιστά ΤΟ data-only δυναμικό περιβάλλον· εντός του, ΜΟΝΟ το %read-one καλεί cl:read."
  `(let ((*read-eval* nil)
         (*readtable* +data-readtable+)
         (*read-default-float-format* ,float-format)
         (*package* (%resolve-package ,package)))
     ,@body))

(declaim (inline %read-one))
(defun %read-one (stream)
  "Το ΜΟΝΑΔΙΚΟ cl:read της αρχιτεκτονικής σε data path. Επιστρέφει form ή +eof+."
  (read stream nil +eof+))

;;; ── Δημόσιο API (ΜΙΑ έδρα· παραμετρικό όπου η συμπεριφορά νόμιμα διαφέρει) ──

(defun read-data-form (stream &key (float-format 'double-float) (package :keyword))
  "Διάβασε ΕΝΑ top-level form από ανοιχτό STREAM (streaming primitive — για resync loops
   όπως το journal %load-lines). (values form status), status ∈ {:ok :eof :unreadable
   :resource-exhausted}. Σε :unreadable αφήνει το stream χρησιμοποιήσιμο (ο caller κάνει
   read-line resync). ΣΗΜΕΙΩΣΗ: το βάθος εδώ φράζεται από το backstop (storage-condition),
   όχι pre-scan — τα ΜΗ-έμπιστα-εξωτερικά ολόκληρα αρχεία περνούν από read-data-file/-string
   (pre-scanned)· το streaming primitive αφορά self-written journals."
  (%with-data-env (float-format package)
    (handler-case
        (let ((form (%read-one stream)))
          (if (eq form +eof+) (values nil :eof) (values form :ok)))
      (safe-read-error () (values nil :unreadable))
      (storage-condition (c) (values nil (%classify c)))
      (serious-condition () (values nil :unreadable)))))

(defun %decode-one (content float-format package max-depth)
  "One-form EOF law πάνω σε ΟΛΟΚΛΗΡΟ string (μετά byte-cap). (values form status),
   status ∈ {:ok :empty :trailing :too-deep :unreadable :resource-exhausted}."
  (when (> (max-paren-depth content) max-depth)
    (return-from %decode-one (values nil :too-deep)))
  (%with-data-env (float-format package)
    (handler-case
        (with-input-from-string (s content)
          (let ((form (%read-one s)))
            (cond ((eq form +eof+) (values nil :empty))
                  ((eq (%read-one s) +eof+) (values form :ok))
                  (t (values form :trailing)))))
      (safe-read-error () (values nil :unreadable))
      (storage-condition (c) (values nil (%classify c)))
      (serious-condition () (values nil :unreadable)))))

(defun %decode-sequence (content float-format package max-depth)
  "ΟΛΑ τα top-level forms (all-or-error· ΟΧΙ resync — αυτό είναι policy του journal).
   (values list status), status ∈ {:ok :too-deep :unreadable :resource-exhausted}."
  (when (> (max-paren-depth content) max-depth)
    (return-from %decode-sequence (values nil :too-deep)))
  (%with-data-env (float-format package)
    (handler-case
        (with-input-from-string (s content)
          (let ((forms '()))
            (loop for form = (%read-one s)
                  until (eq form +eof+)
                  do (push form forms))
            (values (nreverse forms) :ok)))
      (safe-read-error () (values nil :unreadable))
      (storage-condition (c) (values nil (%classify c)))
      (serious-condition () (values nil :unreadable)))))

(defun %slurp (path max-bytes)
  "Διάβασε το PATH ως UTF-8 string, με byte-cap ΠΡΙΝ την ανάγνωση.
   (values content status): :absent (δεν υπάρχει), :too-large, :unreadable, ή :present."
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

(defun read-data-file (path &key (float-format 'double-float) (package :keyword)
                                 (max-bytes *max-data-bytes*) (max-depth *max-data-depth*))
  "Διάβασε ΕΝΑ top-level data form από αρχείο PATH. (values form status), status ∈
   {:ok :empty :trailing :too-large :too-deep :unreadable :resource-exhausted}.
   Απόν αρχείο ⇒ (values NIL :empty). Μη-έμπιστο εξωτερικό: pre-scanned βάθος + byte-cap."
  (multiple-value-bind (content st) (%slurp path max-bytes)
    (case st
      (:absent    (values nil :empty))
      (:too-large (values nil :too-large))
      (:unreadable (values nil :unreadable))
      (:resource-exhausted (values nil :resource-exhausted))
      (t (%decode-one content float-format package max-depth)))))

(defun read-data-string (string &key (float-format 'double-float) (package :keyword)
                                     (max-bytes *max-data-bytes*) (max-depth *max-data-depth*))
  "Διάβασε ΕΝΑ top-level data form από STRING. Ίδιες εγγυήσεις/status με read-data-file."
  (if (> (length string) max-bytes)
      (values nil :too-large)
      (%decode-one string float-format package max-depth)))

(defun read-data-file-sequence (path &key (float-format 'double-float) (package :keyword)
                                          (max-bytes *max-data-bytes*) (max-depth *max-data-depth*))
  "Διάβασε ΟΛΑ τα top-level data forms ενός αρχείου (all-or-error). (values list status),
   status ∈ {:ok :empty :too-large :too-deep :unreadable :resource-exhausted}."
  (multiple-value-bind (content st) (%slurp path max-bytes)
    (case st
      (:absent    (values nil :empty))
      (:too-large (values nil :too-large))
      (:unreadable (values nil :unreadable))
      (:resource-exhausted (values nil :resource-exhausted))
      (t (%decode-sequence content float-format package max-depth)))))

;;; ── Boolean canonicalization (ΜΙΑ έδρα· από %ebg-canon-bool) ──

(defun canonicalize-bool (v)
  "ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ boolean αμέσως μετά το read: :t/t ⇒ t· :nil/nil ⇒ nil (και τα δύο
   έγκυρα)· ΟΤΙΔΗΠΟΤΕ ΑΛΛΟ ⇒ (values nil nil). ΚΡΙΣΙΜΟ υπό *package* :keyword όπου bare
   nil ⇒ :nil (truthy) — ο consumer καλεί αυτό για να μη γίνει silent-boolean bug."
  (cond ((or (eq v t) (eq v :t))    (values t t))
        ((or (null v) (eq v :nil))  (values nil t))
        (t                          (values nil nil))))
