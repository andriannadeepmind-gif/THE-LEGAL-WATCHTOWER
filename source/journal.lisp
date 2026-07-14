;;;; source/journal.lisp
;;;; ============================================================================
;;;; ΤΟ ΕΝΑ ΙΔΙΩΜΑ ΗΜΕΡΟΛΟΓΙΟΥ — append-only sexp-γραμμές, μία υλοποίηση
;;;; ============================================================================
;;;;
;;;; Τρεις υποδομές (βιογραφία, προτάσεις, επεισόδια) γράφουν append-only
;;;; ημερολόγια με το ΙΔΙΟ σχήμα: ένα plist ανά γραμμή, ασφαλής ανάγνωση,
;;;; keyword package, ISO χρόνος, SHA-256 ταυτότητες. Εδώ είναι η ΜΙΑ έδρα τους.
;;;;
;;;; ΦΑΣΗ 0 — ορθότητα υπό ταυτοχρονία, ΕΔΩ και πουθενά αλλού (καμία κλειδαριά
;;;; σκόρπια στους καλούντες):
;;;;   • ΕΝΑΣ συγγραφέας ανά ημερολόγιο: αναδρομικό mutex ανά path — το ζεύγος
;;;;     «διάβασε-ουρά + γράψε-επόμενο» είναι ΑΤΟΜΙΚΗ πράξη (chained-append),
;;;;     αλλιώς δύο νήματα γράφουν το ίδιο :prev και η αλυσίδα SHA-256 σπάει.
;;;;   • Η ουρά της αλυσίδας κρατιέται ΣΤΗ ΜΝΗΜΗ (cache ανά path) — όχι πλήρης
;;;;     επανανάγνωση του αρχείου σε κάθε εγγραφή.
;;;;   • ΑΝΘΕΚΤΙΚΟΤΗΤΑ: fsync μετά από κάθε εγγραφή· κολοβή ουρά (crash στη μέση
;;;;     γραμμής) ΔΕΝ ρίχνει την ανάγνωση — κρατιέται το έγκυρο πρόθεμα και η
;;;;     ατέλεια ΔΗΛΩΝΕΤΑΙ (ποτέ σιωπηλά).
;;;;   • WRITE-FILE-ATOMIC: tmp + rename(2) — καμία «μισο-γραμμένη» κατάσταση.

(defpackage :orchestrator.journal
  (:use :cl)
  (:export #:iso-now #:sha256-hex #:append-line #:read-lines
           #:chained-append #:write-file-atomic #:with-journal-lock
           #:replica-p
           ;; [0086] Persistence Receipt — η μηχανική διάκριση «γράφτηκε;»
           #:receipt-durability #:receipt-verified-p #:durable-p
           ;; [0086+] Η ΜΙΑ έδρα άρνησης εγγραφής + προ-εγγραφική εγκυρότητα
           #:not-durable #:not-durable-receipt #:not-durable-context
           #:require-durable! #:unserializable-record))

(in-package :orchestrator.journal)

(defun iso-now ()
  "Χρόνος ISO-8601 σε CANONICAL UTC (κατάληξη Z, δευτερόλεπτο) — το ΕΝΑ ρολόι
   των ημερολογίων. [0088 Φ5 Υ1]: ποτέ ζώνη-εξαρτώμενος τοπικός χρόνος σε
   transaction-time πεδία — τα recorded δεν επιτρέπεται να αλλάζουν νόημα με
   μετακίνηση του μηχανήματος."
  (multiple-value-bind (sec min hour day mon year)
      (decode-universal-time (get-universal-time) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
            year mon day hour min sec)))

(defun sha256-hex (string)
  "SHA-256 του STRING (UTF-8) σε hex — η ΜΙΑ ταυτότητα περιεχομένου."
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence
    :sha256 (sb-ext:string-to-octets string :external-format :utf-8))))

;;; ── Ο ΕΝΑΣ ΣΥΓΓΡΑΦΕΑΣ ανά ημερολόγιο ──

(defvar *locks* (make-hash-table :test 'equal :synchronized t)
  "namestring → αναδρομικό mutex. Ένα κλείδωμα ανά ημερολόγιο, μία έδρα.")

(defun %lock-of (path)
  (let ((key (namestring path)))
    (or (gethash key *locks*)
        ;; οι δύο πράξεις είναι ασφαλείς: το table είναι synchronized και η
        ;; χειρότερη κούρσα φτιάχνει δύο mutexes στιγμιαία — κερδίζει το τελευταίο
        ;; setf ΠΡΙΝ οποιαδήποτε χρήση για εγγραφή (η εγγραφή περνά από gethash ξανά)
        (sb-ext:with-locked-hash-table (*locks*)
          (or (gethash key *locks*)
              (setf (gethash key *locks*)
                    (sb-thread:make-mutex :name key)))))))

(defmacro with-journal-lock ((path) &body body)
  "Σειριοποίηση πάνω στο ημερολόγιο PATH — αναδρομική (φωλιάζει με ασφάλεια)."
  `(sb-thread:with-recursive-lock ((%lock-of ,path)) ,@body))

;;; ── ΑΝΤΙΓΡΑΦΟ ΑΝΑΓΝΩΣΗΣ (Φάση 6) ──
;;; LAWMAX_REPLICA=1 ⇒ τα ημερολόγια γίνονται ΕΦΗΜΕΡΑ: κάθε append ενημερώνει
;;; την cache στη μνήμη (όλες οι ικανότητες — μνήμη, προτάσεις, βιογραφία —
;;; λειτουργούν κανονικά ΜΕΣΑ στη ζωή της διεργασίας) αλλά ΔΕΝ αγγίζει τον
;;; δίσκο. Έτσι Ν stateless αντίγραφα εξυπηρετούν αναγνώσεις πίσω από
;;; οποιονδήποτε εξισορροπητή, με ΕΝΑΝ μοναδικό συγγραφέα-αυθεντία — καμία
;;; διχάλα αλήθειας στα αρχεία, δηλωμένη λειτουργία κι όχι κρυφή.

(defvar *ephemeral*
  (let ((v (uiop:getenv "LAWMAX_REPLICA")))
    (and v (plusp (length v)) (not (string= v "0"))))
  "Τ ⇒ αντίγραφο ανάγνωσης: append μόνο στη μνήμη, ποτέ στον δίσκο.")

(defun replica-p ()
  "Είναι αυτή η διεργασία ΑΝΤΙΓΡΑΦΟ ΑΝΑΓΝΩΣΗΣ; (LAWMAX_REPLICA=1)"
  *ephemeral*)

;;; ── CACHE ΓΡΑΜΜΩΝ (Φάση 1): το αρχείο διαβάζεται ΜΙΑ φορά ανά διεργασία ──
;;; Ο έλεγχος μέτρησε 1,37s/εγγραφή στα 100k γεγονότα με το «ξαναδιάβασε όλο
;;; το αρχείο ανά πράξη». Εδώ πεθαίνει το μοτίβο: η λίστα γραμμών ζει στη μνήμη
;;; (χτίζεται μία φορά, μεγαλώνει Ο(1) στο append με ουρά-δείκτη), το αρχείο
;;; μένει η ΑΥΘΕΝΤΙΚΗ append-only πηγή. Εξωτερική αλλαγή του αρχείου (πχ git
;;; checkout) ανιχνεύεται από file-write-date και η cache ξαναχτίζεται — ποτέ
;;; μπαγιάτικη αλήθεια σιωπηλά.

(defstruct (jcache (:constructor %make-jcache)) head tail count fwd fsize)

(defvar *cache* (make-hash-table :test 'equal :synchronized t)
  "namestring → jcache (γραμμές στη μνήμη). Ενημερώνεται ΜΟΝΟ υπό το κλείδωμα
   του ημερολογίου — ο ένας συγγραφέας εγγυάται τη συνέπειά της.")

(defun %fsync (stream)
  (ignore-errors (finish-output stream))
  (ignore-errors (sb-posix:fsync (sb-sys:fd-stream-fd stream))))

(defun %load-lines (path)
  "Φόρτωσε τις γραμμές του PATH από τον δίσκο. [0086+] ΑΝΘΕΚΤΙΚΗ ανάγνωση ΑΝΑ
   ΓΡΑΜΜΗ (μία φόρμα ανά γραμμή εκ κατασκευής): κακή/κολοβή γραμμή ΔΗΛΩΝΕΤΑΙ
   και ΠΡΟΣΠΕΡΝΙΕΤΑΙ — οι ΕΠΟΜΕΝΕΣ έγκυρες γραμμές ΔΕΝ χάνονται (θάνατος της
   «μαύρης τρύπας» του κριτή: το παλιό stream-read σταματούσε στην πρώτη κακή
   φόρμα και έκρυβε ό,τι ακολουθούσε)."
  (when (probe-file path)
    (with-open-file (s path :external-format :utf-8)
      (let ((*read-eval* nil)
            (*read-default-float-format* 'double-float)
            (*package* (find-package :keyword))
            (forms '()) (bad 0))
        ;; stream-READ (οι φόρμες μπορεί να είναι ΠΟΛΥΓΡΑΜΜΕΣ — strings με newlines)
        ;; με ΕΠΑΝΑΣΥΓΧΡΟΝΙΣΜΟ: σφάλμα ⇒ προσπέρασε ως το επόμενο όριο γραμμής
        ;; και συνέχισε. Κακή/κολοβή εγγραφή ΔΗΛΩΝΕΤΑΙ, οι επόμενες ΔΕΝ χάνονται.
        (loop
          (multiple-value-bind (form err)
              (handler-case (values (read s nil '%%eof) nil)
                (error (e) (values nil e)))
            (cond (err (incf bad)
                       (unless (read-line s nil nil) (return)))   ; resync ή τέλος
                  ((eq form '%%eof) (return))
                  (t (push form forms)))))
        (when (plusp bad)
          (format *error-output*
                  "~&⚠ ημερολόγιο ~A: ~D μη αναγνώσιμες εγγραφές ΠΡΟΣΠΕΡΑΣΤΗΚΑΝ (δηλωμένα) — ~D έγκυρες κρατήθηκαν~%"
                  (file-namestring path) bad (length forms)))
        (nreverse forms)))))

(defun %cache-of (path)
  "Η ζωντανή cache του ημερολογίου — φορτώνεται/ξαναχτίζεται όταν χρειάζεται.
   Καλείται ΠΑΝΤΑ υπό το κλείδωμα του ημερολογίου."
  (let* ((key (namestring path))
         (fwd (and (probe-file path) (file-write-date path)))
         (fsize (and fwd (ignore-errors (sb-posix:stat-size (sb-posix:stat (namestring path))))))
         (c (gethash key *cache*)))
    (if (and c (eql (jcache-fwd c) fwd) (eql (jcache-fsize c) fsize))
        c
        (let* ((lines (%load-lines path))
               (new (%make-jcache :head lines :tail (last lines)
                                  :count (length lines) :fwd fwd :fsize fsize)))
          (setf (gethash key *cache*) new)
          new))))

;;; ── [0086] PERSISTENCE RECEIPT — η ΜΗΧΑΝΙΚΗ διάκριση «αποθηκεύτηκε;» ──
;;; Η επιστροφή τιμής ΔΕΝ σημαίνει «γράφτηκε». Κάθε append επιστρέφει (values
;;; plist receipt) όπου receipt = plist με :durability ∈ {:durable,
;;; :ephemeral-replica, :degraded-memory-only, :failed-verification} +
;;; :content-hash + :readback-verified + :path + :at. Οι ΘΕΣΜΙΚΟΙ συγγραφείς
;;; (προτάσεις, υιοθετήσεις) καλούν με :verify t (φρέσκια επανανάγνωση από τον
;;; δίσκο, όχι cache) και ΑΡΝΟΥΝΤΑΙ id χωρίς :durable — οι hot-path συγγραφείς
;;; (επεισόδια) πληρώνουν μόνο το φθηνό receipt.

(defun receipt-durability (receipt) (getf receipt :durability))
(defun receipt-verified-p (receipt) (getf receipt :readback-verified))
(defun durable-p (receipt)
  "Τ ⇔ η εγγραφή είναι ΣΤΟΝ ΔΙΣΚΟ (fsynced) — η μόνη έννοια «αποθηκεύτηκε»."
  (eq (getf receipt :durability) :durable))

(define-condition unserializable-record (error)
  ((datum :initarg :datum :reader unserializable-datum)
   (path :initarg :path :reader unserializable-path))
  (:report (lambda (c s)
             (format s "ΜΗ ΣΕΙΡΙΟΠΟΙΗΣΙΜΗ εγγραφή για το ημερολόγιο ~A: το plist ~
                        δεν επιβιώνει read-back (~S). [0086+] Η γραμμή-δηλητήριο ~
                        ΔΕΝ γράφεται ΠΟΤΕ — ο έλεγχος γίνεται ΠΡΙΝ αγγίξει τον δίσκο."
                     (file-namestring (unserializable-path c))
                     (unserializable-datum c)))))

(define-condition not-durable (error)
  ((receipt :initarg :receipt :reader not-durable-receipt)
   (context :initarg :context :reader not-durable-context))
  (:report (lambda (c s)
             (format s "ΘΕΣΜΙΚΗ ΕΓΓΡΑΦΗ (~A) ΧΩΡΙΣ ΔΙΑΡΚΕΙΑ: το ημερολόγιο δεν ~
                        επιβεβαίωσε αποθήκευση (receipt: ~S). Ταυτότητα χωρίς durable ~
                        εγγραφή ΔΕΝ εκδίδεται ([0086] Persistence Receipt)."
                     (not-durable-context c) (not-durable-receipt c)))))

(defun require-durable! (receipt context)
  "Η ΜΙΑ επιβολή του νόμου «id ⟺ durable»: σφάλμα NOT-DURABLE εκτός αν το receipt
   είναι :durable ή δηλωμένο :ephemeral-replica. Καταναλωτές: προτάσεις,
   υιοθετήσεις, πολιτικές, βιογραφία — κάθε ΘΕΣΜΙΚΟΣ συγγραφέας."
  (unless (or (durable-p receipt)
              (eq (receipt-durability receipt) :ephemeral-replica))
    (error 'not-durable :receipt receipt :context context))
  receipt)

(defun %validate-serializable (line plist path)
  "[0086+] ΠΡΟ-ΕΓΓΡΑΦΙΚΟΣ έλεγχος: η γραμμή ΞΑΝΑΔΙΑΒΑΖΕΤΑΙ από τη ΜΝΗΜΗ και
   πρέπει να δώσει ισοδύναμη φόρμα — αλλιώς UNSERIALIZABLE-RECORD ΠΡΙΝ αγγιχτεί
   ο δίσκος. Η κλάση «γραμμή-δηλητήριο στο append-only ledger» πεθαίνει δομικά."
  (handler-case
      (let ((*read-eval* nil)
            (*read-default-float-format* 'double-float)
            (*package* (find-package :keyword)))
        (read-from-string line))
    (error () (error 'unserializable-record :datum plist :path path))))

(defun append-line (path plist &key verify)
  "Πρόσθεσε ΜΙΑ γραμμή-plist στο PATH — υπό το κλείδωμα του ημερολογίου, με
   fsync. Επιστρέφει (values plist receipt): το receipt φέρει τη ΜΗΧΑΝΙΚΗ
   αλήθεια της αποθήκευσης (ποτέ σιωπηλό «μάλλον γράφτηκε»). Με VERIFY, η
   εγγραφή επαληθεύεται με φρέσκια επανανάγνωση από τον δίσκο (read-back)."
  (with-journal-lock (path)
    (let* ((c (%cache-of path))
           (wrote nil)
           (line (let ((*package* (find-package :keyword))
                       (*print-readably* nil) (*print-escape* t)
                       (*print-pretty* nil) (*print-circle* nil))
                   (format nil "~S" plist)))
           (chash (sha256-hex line))
           (verified nil))
      ;; [0086+] ΠΡΙΝ τον δίσκο: γραμμή-δηλητήριο = αδύνατη (error εδώ, όχι ρύπανση)
      (%validate-serializable line plist path)
      ;; [0086+] Δεν υπάρχει ΜΟΝΙΜΟ *degraded* skip (εύρημα κριτή Γ1: παγιδευόταν
      ;; για πάντα): ΠΑΝΤΑ επιχειρούμε εγγραφή· transient/διορθωμένο FS ανακάμπτει.
      (unless *ephemeral*                  ; δηλωμένο αντίγραφο ανάγνωσης: μόνο μνήμη
        (handler-case
            (progn
              (ensure-directories-exist path)
              (with-open-file (s path :direction :output
                                 :if-exists :append :if-does-not-exist :create
                                 :external-format :utf-8)
                (write-string line s)
                (terpri s)
                (%fsync s))
              (setf wrote t)
              (when verify
                ;; [0086+] Επαλήθευση με ΜΕΛΟΣ, όχι με ΣΕΙΡΑ (εύρημα κριτή A1):
                ;; «η εγγραφή μου είναι durable ΜΕΣΑ στο ledger» ισχύει υπό ΚΑΘΕ
                ;; cross-process interleaving — δύο διεργασίες βρίσκουν η καθεμία
                ;; τη δική της γραμμή. Φρέσκια από δίσκο (όχι cache), EQUAL.
                (setf verified (and (member plist (%load-lines path) :test #'equal) t))))
          (unserializable-record (e) (error e))   ; ποτέ σιωπηλό — δεν είναι I/O
          (error (e)
            ;; ΤΙΜΙΑ ΥΠΟΒΑΘΜΙΣΗ (per-call, ΟΧΙ μόνιμη): read-only FS ⇒ εφήμερα,
            ;; αλλά η επόμενη κλήση ΞΑΝΑΔΟΚΙΜΑΖΕΙ (καμία μόνιμη παγίδα).
            (format *error-output*
                    "~&⚠ ημερολόγιο ~A: ΜΗ ΕΓΓΡΑΨΙΜΟ (~A) — αυτή η εγγραφή μένει ΕΦΗΜΕΡΗ στη μνήμη~%"
                    (file-namestring path) e))))
      ;; Ο(1) επέκταση cache — ΟΧΙ όταν το verification απέτυχε ([0086+]: ο δίσκος
      ;; είναι η αυθεντία· η cache δεν επιτρέπεται να δείχνει ό,τι δεν πιστοποιήθηκε)
      (unless (and wrote verify (not verified))
        (let ((cell (list plist)))
          (if (jcache-tail c)
              (setf (cdr (jcache-tail c)) cell)
              (setf (jcache-head c) cell))
          (setf (jcache-tail c) cell
                (jcache-count c) (1+ (jcache-count c)))
          (when wrote
            (setf (jcache-fwd c) (file-write-date path)
                  (jcache-fsize c) (ignore-errors
                                     (sb-posix:stat-size
                                      (sb-posix:stat (namestring path))))))))
      (values plist
              (list :durability (cond ((and wrote verify (not verified))
                                       :failed-verification)
                                      (wrote :durable)
                                      (*ephemeral* :ephemeral-replica)
                                      (t :degraded-memory-only))
                    :path (namestring path)
                    :content-hash chash
                    :readback-verified verified
                    :at (iso-now))))))

(defun chained-append (path build-fn &key verify)
  "Η ΑΤΟΜΙΚΗ πράξη της αλυσίδας: υπό το κλείδωμα, δες την ουρά (cache, Ο(1)),
   κάλεσε (BUILD-FN τελευταίο-plist|nil) → νέο plist, γράψε το. Δύο νήματα ΔΕΝ
   χτίζουν ποτέ πάνω στο ίδιο :prev/:seq. Επιστρέφει (values plist receipt)."
  (with-journal-lock (path)
    (append-line path (funcall build-fn (car (jcache-tail (%cache-of path))))
                 :verify verify)))

(defun read-lines (path)
  "Όλες οι γραμμές-plists του PATH, με τη σειρά τους — από τη ζωντανή cache
   (το αρχείο διαβάζεται μία φορά ανά διεργασία/αλλαγή). Η επιστρεφόμενη λίστα
   είναι ΜΟΝΟ-ΓΙΑ-ΑΝΑΓΝΩΣΗ: μοιράζεται δομή με την cache, που μεγαλώνει μόνο
   από την ουρά της (append-only) — οι αναγνώστες βλέπουν πάντα συνεπές πρόθεμα."
  (with-journal-lock (path)
    (jcache-head (%cache-of path))))

(defun write-file-atomic (path content)
  "Αντικατάσταση αρχείου ΑΤΟΜΙΚΑ: γράψε σε tmp στο ίδιο σύστημα αρχείων,
   fsync, rename(2). Crash σε οποιοδήποτε σημείο ⇒ ή η παλιά ή η νέα εκδοχή —
   ποτέ μισή, ποτέ άδεια."
  (let ((tmp (merge-pathnames (format nil "~A.tmp~D" (file-namestring path)
                                      (sb-unix:unix-getpid))
                              path)))
    (ensure-directories-exist path)
    (with-open-file (s tmp :direction :output :if-exists :supersede
                       :if-does-not-exist :create :external-format :utf-8)
      (write-string content s)
      (%fsync s))
    (sb-posix:rename (namestring tmp) (namestring path))
    path))
