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
           #:replica-p #:canon-sexp
           ;; [0086] Persistence Receipt — η μηχανική διάκριση «γράφτηκε;»
           #:receipt-durability #:receipt-verified-p #:durable-p
           ;; [0086+] Η ΜΙΑ έδρα άρνησης εγγραφής + προ-εγγραφική εγκυρότητα
           #:not-durable #:not-durable-receipt #:not-durable-context
           #:require-durable! #:unserializable-record
           ;; [RATCHET-2] Compare-and-append: η διχάλα αλυσίδας δομικά αδύνατη
           #:stale-chain-link #:stale-chain-path
           #:stale-chain-expected #:stale-chain-actual
           ;; [RATCHET-1] Τίμια durability: αποτυχία συγχρονισμού = ρητή, ποτέ :durable
           #:sync-failure #:sync-failure-path #:sync-failure-cause
           #:*fsync-fault*
           ;; [RATCHET-1] Μονοτονία transaction-time στην έδρα εγγραφής
           #:non-monotonic-transaction-time
           #:non-monotonic-path #:non-monotonic-prev-at #:non-monotonic-new-at
           #:*clock-override*))

(in-package :orchestrator.journal)

(defvar *clock-override* nil
  "[RATCHET-1] TEST-ONLY ένεση ρολογιού: string ISO-8601 ⇒ το iso-now την
   επιστρέφει αυτούσια (προσομοίωση οπισθοδρόμησης/παγώματος ρολογιού στα
   αρνητικά tests). ΠΟΤΕ δεν τίθεται σε παραγωγικό μονοπάτι.")

(defun iso-now ()
  "Χρόνος ISO-8601 σε CANONICAL UTC (κατάληξη Z, δευτερόλεπτο) — το ΕΝΑ ρολόι
   των ημερολογίων. [0088 Φ5 Υ1]: ποτέ ζώνη-εξαρτώμενος τοπικός χρόνος σε
   transaction-time πεδία — τα recorded δεν επιτρέπεται να αλλάζουν νόημα με
   μετακίνηση του μηχανήματος."
  (or *clock-override*
      (multiple-value-bind (sec min hour day mon year)
          (decode-universal-time (get-universal-time) 0)
        (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
                year mon day hour min sec))))

(defun canon-sexp (x &optional out)
  "[RATCHET-1] Η ΜΙΑ κανονική σειριοποίηση sexp ΤΙΜΩΝ του journal ιδιώματος —
   συνάρτηση της ΑΞΙΑΣ, ποτέ της αναπαράστασης (το prin1 τύπωνε non-simple
   strings ως #A(...) — η ταυτότητα δεν εξαρτάται από το αν ένα string είναι
   simple array). Επιτρεπτό πεδίο = ό,τι επιτρέπει το sexp journal: NIL,
   keyword, string, integer, λίστα αυτών. Οτιδήποτε άλλο ⇒ ΣΦΑΛΜΑ (fail-closed).
   Χωρίς OUT επιστρέφει string. Καταναλωτές: version-graph (%canon-sexp
   deleg.), memory (episode :hv 2 hashes). Μία έδρα — καμία δεύτερη παραλλαγή."
  (if (null out)
      (with-output-to-string (s) (canon-sexp x s))
      (etypecase x
        (null (write-string "NIL" out))
        (keyword (write-char #\: out) (write-string (symbol-name x) out))
        (string (write-char #\" out)
         (loop for c across x
               do (when (or (char= c #\") (char= c #\\)) (write-char #\\ out))
                  (write-char c out))
         (write-char #\" out))
        (integer (format out "~D" x))
        (cons (write-char #\( out)
         (loop for tail = x then (cdr tail)
               while (consp tail)
               do (canon-sexp (car tail) out)
                  (cond ((consp (cdr tail)) (write-char #\Space out))
                        ((cdr tail) (write-string " . " out) (canon-sexp (cdr tail) out))))
         (write-char #\) out)))))

(defun sha256-hex (string)
  "SHA-256 του STRING (UTF-8) σε hex — η ΜΙΑ ταυτότητα περιεχομένου."
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence
    :sha256 (sb-ext:string-to-octets string :external-format :utf-8))))

;;; ── Ο ΕΝΑΣ ΣΥΓΓΡΑΦΕΑΣ ανά ημερολόγιο ──
;;; [RATCHET-2] ΔΥΟ στρώματα, ΜΙΑ έδρα: (α) αναδρομικό thread-mutex (νήματα της
;;; ίδιας διεργασίας)· (β) flock(2) LOCK_EX σε <journal>.lock (ΔΙΕΡΓΑΣΙΕΣ).
;;; Το flock καλύπτει ΟΛΟΚΛΗΡΗ την πράξη «ανάγνωση ουράς → κατασκευή record →
;;; append → fsync → ενημέρωση cache» — ο single-writer είναι πλέον ΔΟΜΙΚΟΣ
;;; μεταξύ διεργασιών, όχι σύμβαση. Το κλείσιμο του fd απελευθερώνει το lock
;;; ακόμη και σε abnormal unwind. Βάθος ανά path ⇒ το φώλιασμα (chained-append
;;; → append-line) ΔΕΝ ξανα-παίρνει flock (νέο fd της ίδιας διεργασίας θα
;;; αυτο-μπλόκαρε — flock locks ανά open-file-description).

(defconstant +flock-ex+ 2 "flock(2) LOCK_EX")

(sb-alien:define-alien-routine ("flock" %flock-syscall) sb-alien:int
  (fd sb-alien:int) (operation sb-alien:int))

(defstruct (plock (:constructor %make-plock (mutex)))
  mutex (depth 0) (fd nil))

(defvar *locks* (make-hash-table :test 'equal :synchronized t)
  "namestring → plock {αναδρομικό mutex, flock βάθος, fd}. Μία έδρα.")

(defun %lock-of (path)
  (let ((key (namestring path)))
    (or (gethash key *locks*)
        ;; οι δύο πράξεις είναι ασφαλείς: το table είναι synchronized και η
        ;; χειρότερη κούρσα φτιάχνει δύο plocks στιγμιαία — κερδίζει το τελευταίο
        ;; setf ΠΡΙΝ οποιαδήποτε χρήση για εγγραφή (η εγγραφή περνά από gethash ξανά)
        (sb-ext:with-locked-hash-table (*locks*)
          (or (gethash key *locks*)
              (setf (gethash key *locks*)
                    (%make-plock (sb-thread:make-mutex :name key))))))))

(defun %call-with-file-lock (plock path fn)
  "flock(2) LOCK_EX στο <path>.lock γύρω από το FN — μόνο στο εξώτατο επίπεδο
   (depth 0→1). Καλείται ΠΑΝΤΑ υπό το thread-mutex του PLOCK, άρα depth/fd
   μεταλλάσσονται από ΕΝΑ νήμα τη φορά. EINTR ⇒ επανάληψη· άλλη αποτυχία
   flock ⇒ ΣΦΑΛΜΑ (fail-closed — ποτέ σιωπηλή εγγραφή χωρίς αποκλεισμό)."
  (if (plusp (plock-depth plock))
      (progn (incf (plock-depth plock))
             (unwind-protect (funcall fn) (decf (plock-depth plock))))
      (let* ((lockpath (concatenate 'string (namestring path) ".lock"))
             (fd (handler-case
                     (progn (ensure-directories-exist path)
                            (sb-posix:open lockpath
                                           (logior sb-posix:o-wronly sb-posix:o-creat)
                                           #o644))
                   (error () nil))))
        (if (null fd)
            ;; Ο κατάλογος ΔΕΝ είναι εγγράψιμος ⇒ ούτε το ημερολόγιο μπορεί να
            ;; γραφτεί. Ο αμοιβαίος αποκλεισμός είναι ΚΕΝΟΣ εδώ (δεν υπάρχει
            ;; εγγραφή να προστατευθεί) — ΔΕΝ υποβαθμίζεται καμία πραγματική
            ;; εγγύηση. Το σώμα προχωρά και η ΜΙΑ έδρα εγγραφής αναφέρει τίμια
            ;; :degraded-memory-only (το συμβόλαιο «id ⟺ durable» μένει άθικτο).
            (funcall fn)
            (unwind-protect
                 (progn
                   (loop for rc = (%flock-syscall fd +flock-ex+)
                         until (zerop rc)
                         do (let ((errno (sb-alien:get-errno)))
                              (unless (= errno sb-posix:eintr)
                                (error "flock(~A) απέτυχε: ~A"
                                       lockpath (sb-int:strerror errno)))))
                   (setf (plock-fd plock) fd (plock-depth plock) 1)
                   (funcall fn))
              (setf (plock-depth plock) 0 (plock-fd plock) nil)
              (sb-posix:close fd)))))) ; close(2) ⇒ το flock απελευθερώνεται

(defmacro with-journal-lock ((path) &body body)
  "Σειριοποίηση πάνω στο ημερολόγιο PATH — αναδρομική (φωλιάζει με ασφάλεια):
   thread-mutex + cross-process flock(2) [RATCHET-2]. Τα αντίγραφα ανάγνωσης
   (LAWMAX_REPLICA=1) δεν αγγίζουν δίσκο ⇒ μόνο thread-mutex."
  (let ((p (gensym "PATH")) (l (gensym "PLOCK")))
    `(let* ((,p ,path) (,l (%lock-of ,p)))
       (sb-thread:with-recursive-lock ((plock-mutex ,l))
         (if *ephemeral*
             (progn ,@body)
             (%call-with-file-lock ,l ,p (lambda () ,@body)))))))

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

;;; [RATCHET-1] ΤΙΜΙΟ fsync: ΚΑΝΕΝΑ σφάλμα finish-output/fsync(2) δεν
;;; καταπίνεται. Αποτυχία συγχρονισμού ⇒ SYNC-FAILURE — ο καλών αποφασίζει
;;; ρητά (append-line ⇒ receipt :sync-failed, ΠΟΤΕ :durable· write-file-atomic
;;; ⇒ το σφάλμα διαδίδεται). Το *fsync-fault* είναι ελεγχόμενη ένεση σφάλματος
;;; ΓΙΑ TESTS (το παραγωγικό μονοπάτι καλεί το πραγματικό fsync(2) — κανένα
;;; stub/mock στην παραγωγή).

(defvar *fsync-fault* nil
  "TEST-ONLY fault injection: non-NIL ⇒ το %fsync αποτυγχάνει ελεγχόμενα
   (SYNC-FAILURE) ΜΕΤΑ το finish-output, σαν να απέτυχε το fsync(2).
   ΠΟΤΕ δεν τίθεται σε παραγωγικό μονοπάτι.")

(define-condition sync-failure (error)
  ((path :initarg :path :initform nil :reader sync-failure-path)
   (cause :initarg :cause :initform nil :reader sync-failure-cause))
  (:report (lambda (c s)
             (format s "ΑΠΟΤΥΧΙΑ ΣΥΓΧΡΟΝΙΣΜΟΥ ΔΙΣΚΟΥ (fsync) στο ~A: ~A — ~
                        η εγγραφή ΔΕΝ λογίζεται durable/committed [RATCHET-1]."
                     (or (sync-failure-path c) "stream")
                     (or (sync-failure-cause c) "injected fault")))))

(defun %fsync (stream &optional path)
  "finish-output + fsync(2), fail-closed: οποιοδήποτε σφάλμα ⇒ SYNC-FAILURE
   (ποτέ σιωπηλό). Επιστρέφει T μόνο σε ΠΡΑΓΜΑΤΙΚΗ επιτυχία συγχρονισμού."
  (handler-case
      (progn
        (finish-output stream)
        (when *fsync-fault*
          (error "injected fsync fault (~A)" *fsync-fault*))
        (sb-posix:fsync (sb-sys:fd-stream-fd stream))
        t)
    (error (e) (error 'sync-failure :path (and path (namestring path)) :cause e))))

(defun %fsync-directory (path)
  "[RATCHET-1] fsync(2) του ΓΟΝΙΚΟΥ καταλόγου του PATH — το rename(2) γίνεται
   durable μόνο όταν συγχρονιστεί και η καταχώρηση καταλόγου. Fail-closed."
  (let ((dir (namestring (make-pathname :name nil :type nil :version nil
                                        :defaults path))))
    (handler-case
        (let ((fd (sb-posix:open dir sb-posix:o-rdonly)))
          (unwind-protect
               (progn (when *fsync-fault*
                        (error "injected fsync fault (~A)" *fsync-fault*))
                      (sb-posix:fsync fd)
                      t)
            (sb-posix:close fd)))
      (sync-failure (e) (error e))
      (error (e) (error 'sync-failure :path dir :cause e)))))

(define-condition non-monotonic-transaction-time (error)
  ((path :initarg :path :reader non-monotonic-path)
   (prev-at :initarg :prev-at :reader non-monotonic-prev-at)
   (new-at :initarg :new-at :reader non-monotonic-new-at))
  (:report (lambda (c s)
             (format s "ΜΗ-ΜΟΝΟΤΟΝΟ TRANSACTION-TIME στο ~A: νέο :at ~S < ~
                        τελευταίο committed :at ~S (οπισθοδρόμηση ρολογιού;) — ~
                        η εγγραφή ΑΠΟΡΡΙΠΤΕΤΑΙ fail-closed [RATCHET-4]· ~
                        κανένα epistemic snapshot δεν δηλητηριάζεται σιωπηλά."
                     (non-monotonic-path c)
                     (non-monotonic-new-at c)
                     (non-monotonic-prev-at c)))))

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

(defun %committed-at (cache)
  "[RATCHET-4] Το :at της ΤΕΛΕΥΤΑΙΑΣ committed γραμμής (ή NIL σε κενό
   ημερολόγιο) — η αναφορά μονοτονίας του transaction-time."
  (let ((tail (car (jcache-tail cache))))
    (and (listp tail) (getf tail :at))))

(defun %check-monotonic-at! (path cache plist)
  "[RATCHET-4] Ο κανόνας μονοτονίας στην ΕΔΡΑ ΕΓΓΡΑΦΗΣ: γραμμή με :at
   ΓΝΗΣΙΩΣ ΠΑΛΑΙΟΤΕΡΟ από το τελευταίο committed :at ΔΕΝ εισάγεται σιωπηλά —
   NON-MONOTONIC-TRANSACTION-TIME ΠΡΙΝ αγγίξει τον δίσκο. Ίσα :at επιτρέπονται
   (η κοκκίωση του iso-now είναι το δευτερόλεπτο· η σειρά δίνεται από το seq).
   Οι γραμμές είναι canonical UTC ISO-8601 σταθερού πλάτους ⇒ λεξικογραφική
   σύγκριση ≡ χρονολογική. Γραμμή ΧΩΡΙΣ :at δεν ελέγχεται εδώ (τα ημερολόγια
   που το απαιτούν το επιβάλλουν στο δικό τους σχήμα)."
  (let ((new (getf plist :at))
        (prev (%committed-at cache)))
    (when (and (stringp new) (stringp prev) (string< new prev))
      (error 'non-monotonic-transaction-time
             :path (namestring path) :prev-at prev :new-at new))))

(defun append-line (path plist &key verify)
  "Πρόσθεσε ΜΙΑ γραμμή-plist στο PATH — υπό το κλείδωμα του ημερολογίου, με
   fsync. Επιστρέφει (values plist receipt): το receipt φέρει τη ΜΗΧΑΝΙΚΗ
   αλήθεια της αποθήκευσης (ποτέ σιωπηλό «μάλλον γράφτηκε»). Με VERIFY, η
   εγγραφή επαληθεύεται με φρέσκια επανανάγνωση από τον δίσκο (read-back).

   [RATCHET-1] :durable ΜΟΝΟ μετά από ΠΡΑΓΜΑΤΙΚΑ επιτυχές fsync(2). Αποτυχία
   συγχρονισμού ⇒ :sync-failed (ΟΧΙ committed) με :sync-error στο receipt —
   τα bytes μπορεί να βρίσκονται στην page cache, αλλά ΔΕΝ δηλώνονται ποτέ
   αποθηκευμένα. [RATCHET-4] Οπισθοδρόμηση transaction-time ⇒ σφάλμα ΠΡΙΝ
   τον δίσκο."
  (with-journal-lock (path)
    (let* ((c (%cache-of path))
           (wrote nil)
           (synced nil)
           (sync-error nil)
           (line (let ((*package* (find-package :keyword))
                       (*print-readably* nil) (*print-escape* t)
                       (*print-pretty* nil) (*print-circle* nil))
                   (format nil "~S" plist)))
           (chash (sha256-hex line))
           (verified nil))
      ;; [0086+] ΠΡΙΝ τον δίσκο: γραμμή-δηλητήριο = αδύνατη (error εδώ, όχι ρύπανση)
      (%validate-serializable line plist path)
      ;; [RATCHET-4] ΠΡΙΝ τον δίσκο: οπισθοδρόμηση ρολογιού = fail-closed
      (%check-monotonic-at! path c plist)
      ;; [0086+] Δεν υπάρχει ΜΟΝΙΜΟ *degraded* skip (εύρημα κριτή Γ1: παγιδευόταν
      ;; για πάντα): ΠΑΝΤΑ επιχειρούμε εγγραφή· transient/διορθωμένο FS ανακάμπτει.
      (unless *ephemeral*                  ; δηλωμένο αντίγραφο ανάγνωσης: μόνο μνήμη
        (handler-case
            (progn
              (ensure-directories-exist path)
              ;; Το fsync γίνεται ΜΕΣΑ στο with-open-file: το σφάλμα του δεν
              ;; καταπίνεται, αλλά η ροή κλείνει κανονικά στο unwind.
              (handler-case
                  (with-open-file (s path :direction :output
                                     :if-exists :append :if-does-not-exist :create
                                     :external-format :utf-8)
                    (write-string line s)
                    (terpri s)
                    (setf wrote t)          ; τα bytes δόθηκαν στο ΛΣ
                    (%fsync s path)
                    (setf synced t))        ; ΚΑΙ συγχρονίστηκαν πραγματικά
                (sync-failure (e)
                  ;; [RATCHET-1] ΡΗΤΗ αποτυχία durability — ΟΧΙ committed.
                  (setf sync-error (princ-to-string e))
                  (format *error-output*
                          "~&✗ ημερολόγιο ~A: ΑΠΟΤΥΧΙΑ ΣΥΓΧΡΟΝΙΣΜΟΥ — η εγγραφή ΔΕΝ είναι durable (~A)~%"
                          (file-namestring path) e)))
              (when (and synced verify)
                ;; [0086+] Επαλήθευση με ΜΕΛΟΣ, όχι με ΣΕΙΡΑ (εύρημα κριτή A1):
                ;; «η εγγραφή μου είναι durable ΜΕΣΑ στο ledger» ισχύει υπό ΚΑΘΕ
                ;; cross-process interleaving — δύο διεργασίες βρίσκουν η καθεμία
                ;; τη δική της γραμμή. Φρέσκια από δίσκο (όχι cache), EQUAL.
                (setf verified (and (member plist (%load-lines path) :test #'equal) t))))
          (unserializable-record (e) (error e))   ; ποτέ σιωπηλό — δεν είναι I/O
          (non-monotonic-transaction-time (e) (error e))
          (error (e)
            ;; ΤΙΜΙΑ ΥΠΟΒΑΘΜΙΣΗ (per-call, ΟΧΙ μόνιμη): read-only FS ⇒ εφήμερα,
            ;; αλλά η επόμενη κλήση ΞΑΝΑΔΟΚΙΜΑΖΕΙ (καμία μόνιμη παγίδα).
            (format *error-output*
                    "~&⚠ ημερολόγιο ~A: ΜΗ ΕΓΓΡΑΨΙΜΟ (~A) — αυτή η εγγραφή μένει ΕΦΗΜΕΡΗ στη μνήμη~%"
                    (file-namestring path) e))))
      ;; Ο(1) επέκταση cache — ΟΧΙ όταν το verification απέτυχε ([0086+]: ο δίσκος
      ;; είναι η αυθεντία· η cache δεν επιτρέπεται να δείχνει ό,τι δεν πιστοποιήθηκε)
      ;; ΟΥΤΕ όταν ο συγχρονισμός απέτυχε ([RATCHET-1]: μη-durable γραμμή δεν
      ;; γίνεται ουρά της αλυσίδας — ο επόμενος συγγραφέας θα έχτιζε πάνω της).
      (unless (or (and synced verify (not verified))
                  (and wrote (not synced)))
        (let ((cell (list plist)))
          (if (jcache-tail c)
              (setf (cdr (jcache-tail c)) cell)
              (setf (jcache-head c) cell))
          (setf (jcache-tail c) cell
                (jcache-count c) (1+ (jcache-count c)))
          (when synced
            (setf (jcache-fwd c) (file-write-date path)
                  (jcache-fsize c) (ignore-errors
                                     (sb-posix:stat-size
                                      (sb-posix:stat (namestring path))))))))
      ;; [RATCHET-1] Ο δίσκος έγραψε bytes που ΔΕΝ συγχρονίστηκαν: η in-memory
      ;; cache θα ήταν πλέον ασύμφωνη με το αρχείο ⇒ ακυρώνεται (επόμενη
      ;; ανάγνωση ξαναχτίζει από τον δίσκο, καμία μπαγιάτικη ουρά).
      (when (and wrote (not synced))
        (remhash (namestring path) *cache*))
      (values plist
              (list :durability (cond ((and wrote (not synced)) :sync-failed)
                                      ((and synced verify (not verified))
                                       :failed-verification)
                                      (synced :durable)
                                      (*ephemeral* :ephemeral-replica)
                                      (t :degraded-memory-only))
                    :path (namestring path)
                    :content-hash chash
                    :readback-verified verified
                    :sync-error sync-error
                    :at (iso-now))))))

;;; ── [RATCHET-2] COMPARE-AND-APPEND: η διχάλα γίνεται ΔΟΜΙΚΑ αδύνατη ──
;;; Το κλείδωμα (thread + flock) δίνει ΑΜΟΙΒΑΙΟ ΑΠΟΚΛΕΙΣΜΟ. Δεν αρκεί: η ουρά
;;; πάνω στην οποία χτίζει ο συγγραφέας ερχόταν από cache που επικυρωνόταν
;;; ΕΥΡΕΤΙΚΑ (mtime+μέγεθος) — δηλαδή η ορθότητα της αλυσίδας στηριζόταν στο
;;; ότι η ευρετική δεν σφάλλει ΠΟΤΕ (φρουρός γύρω από λάθος σχήμα).
;;; Εδώ η κλάση πεθαίνει: πριν γραφτεί ΟΤΙΔΗΠΟΤΕ, ο δεσμός του νέου record
;;; αντιπαραβάλλεται με την ΠΡΑΓΜΑΤΙΚΗ τελευταία γραμμή ΤΟΥ ΑΡΧΕΙΟΥ (seek από
;;; το τέλος, O(1)). Ασυμφωνία ⇒ STALE-CHAIN-LINK, ποτέ σιωπηλή διχάλα —
;;; ανεξάρτητα από cache, ξένη διεργασία, ή σφάλμα στην ευρετική.
;;;
;;; ΔΗΛΩΜΕΝΟ ΑΝΩΤΕΡΟ (εκτός εγκεκριμένου εύρους, καταγράφεται): ξεχωριστή
;;; διεργασία-συγγραφέας που κρατά ΜΟΝΗ της το fd (process boundary ως
;;; capability) — εκεί ο δεύτερος συγγραφέας δεν υπάρχει καν ως δυνατότητα.

(define-condition stale-chain-link (error)
  ((path :initarg :path :reader stale-chain-path)
   (expected :initarg :expected :reader stale-chain-expected)
   (actual :initarg :actual :reader stale-chain-actual))
  (:report (lambda (c s)
             (format s "ΜΠΑΓΙΑΤΙΚΟΣ ΔΕΣΜΟΣ ΑΛΥΣΙΔΑΣ στο ~A: το record δείχνει ~
                        πίσω στο ~S ενώ η ΠΡΑΓΜΑΤΙΚΗ ουρά του αρχείου είναι ~S ~
                        — η εγγραφή ΑΠΟΡΡΙΠΤΕΤΑΙ [RATCHET-2]· καμία διχάλα ~
                        αλυσίδας δεν γράφεται ποτέ σιωπηλά."
                     (stale-chain-path c)
                     (stale-chain-expected c) (stale-chain-actual c)))))

(defun chained-append (path build-fn &key verify (back-link :prev) (identity :hash))
  "Η ΑΤΟΜΙΚΗ πράξη της αλυσίδας: υπό το κλείδωμα (thread + flock), δες την ουρά,
   κάλεσε (BUILD-FN ουρά|nil) → νέο plist, ΕΠΑΛΗΘΕΥΣΕ τον δεσμό του, γράψε το.
   Επιστρέφει (values plist receipt).

   [RATCHET-2] COMPARE-AND-APPEND: όταν ο καλών δηλώνει BACK-LINK, το πεδίο αυτό
   του νέου record ΠΡΕΠΕΙ να ισούται με το IDENTITY πεδίο της ουράς (ή με τον
   μηδενικό δείκτη σε κενό ημερολόγιο)· αλλιώς STALE-CHAIN-LINK ΠΡΙΝ γραφτεί
   οτιδήποτε. BACK-LINK NIL σημαίνει ΡΗΤΑ «ο builder επαληθεύει μόνος του τον
   δεσμό του» — το χρησιμοποιεί το version-graph, που κάνει τον αυστηρότερο
   έλεγχό του (version-chain-stale) πάνω στην ίδια ουρά.

   ΓΙΑΤΙ Η ΟΥΡΑ ΕΡΧΕΤΑΙ ΑΠΟ ΤΗΝ CACHE ΚΑΙ ΟΧΙ ΑΠΟ SEEK ΣΤΟ ΤΕΛΟΣ ΤΟΥ ΑΡΧΕΙΟΥ:
   ΕΝΑ RECORD ΔΕΝ ΕΙΝΑΙ ΜΙΑ ΦΥΣΙΚΗ ΓΡΑΜΜΗ. Το ~S τυπώνει τα strings με τους
   χαρακτήρες αλλαγής γραμμής ΑΥΤΟΥΣΙΟΥΣ, και τα records του version-graph
   φέρουν κείμενα άρθρων με πολλές γραμμές — γι' αυτό ο αναγνώστης (%load-lines)
   είναι form-aware (read + resync) και ΟΧΙ line-based. Ανάγνωση «τελευταίας
   γραμμής» με seek επιστρέφει ΘΡΑΥΣΜΑ (μετρημένο: ο builder του version-graph
   έπαιρνε τον ακέραιο 3 από αρίθμηση παραγράφου). Η ορθότητα της ουράς εδώ
   στηρίζεται σε: (i) flock ⇒ κάθε ξένη εγγραφή ολοκληρώθηκε ΠΡΙΝ πάρουμε το
   κλείδωμα· (ii) το ημερολόγιο είναι ΑΥΣΤΗΡΑ append-only ⇒ κάθε νέα εγγραφή
   ΜΕΓΑΛΩΝΕΙ το αρχείο· (iii) το %cache-of ξαναχτίζει όταν αλλάξει μέγεθος ή
   ώρα. Άρα η ουρά της cache υπό το κλείδωμα ΕΙΝΑΙ η ουρά του δίσκου· κάθε
   μη-append μετάλλαξη είναι αλλοίωση και πιάνεται από την επαλήθευση αλυσίδας."
  (with-journal-lock (path)
    (let* ((tail (car (jcache-tail (%cache-of path))))
           (record (funcall build-fn tail)))
      (when (and back-link (not *ephemeral*))
        (let ((expected (getf record back-link))
              (actual (if tail
                          (getf tail identity)
                          (make-string 64 :initial-element #\0))))
          (unless (equal expected actual)
            (error 'stale-chain-link :path (namestring path)
                                     :expected expected :actual actual))))
      (append-line path record :verify verify))))

(defun read-lines (path)
  "Όλες οι γραμμές-plists του PATH, με τη σειρά τους — από τη ζωντανή cache
   (το αρχείο διαβάζεται μία φορά ανά διεργασία/αλλαγή). Η επιστρεφόμενη λίστα
   είναι ΜΟΝΟ-ΓΙΑ-ΑΝΑΓΝΩΣΗ: μοιράζεται δομή με την cache, που μεγαλώνει μόνο
   από την ουρά της (append-only) — οι αναγνώστες βλέπουν πάντα συνεπές πρόθεμα."
  (with-journal-lock (path)
    (jcache-head (%cache-of path))))

(defun write-file-atomic (path content)
  "Αντικατάσταση αρχείου ΑΤΟΜΙΚΑ: γράψε σε tmp στο ίδιο σύστημα αρχείων,
   fsync, rename(2), fsync ΓΟΝΙΚΟΥ ΚΑΤΑΛΟΓΟΥ. Crash σε οποιοδήποτε σημείο ⇒
   ή η παλιά ή η νέα εκδοχή — ποτέ μισή, ποτέ άδεια.

   [RATCHET-1] Δύο διορθώσεις τιμιότητας: (α) αποτυχία fsync του tmp ⇒
   SYNC-FAILURE ΠΡΙΝ το rename (ποτέ δημοσίευση ασυγχρόνιστου περιεχομένου)·
   (β) μετά το rename συγχρονίζεται ΚΑΙ ο γονικός κατάλογος — αλλιώς το ίδιο
   το rename μπορεί να χαθεί σε crash, δηλαδή «ατομικό» χωρίς durability.
   Το tmp καθαρίζεται σε κάθε αποτυχία (κανένα ορφανό .tmpNNN)."
  (let ((tmp (merge-pathnames (format nil "~A.tmp~D" (file-namestring path)
                                      (sb-unix:unix-getpid))
                              path)))
    (ensure-directories-exist path)
    (unwind-protect
         (progn
           (with-open-file (s tmp :direction :output :if-exists :supersede
                              :if-does-not-exist :create :external-format :utf-8)
             (write-string content s)
             (%fsync s tmp))
           (sb-posix:rename (namestring tmp) (namestring path))
           (setf tmp nil)                       ; δημοσιεύθηκε — τίποτα να καθαριστεί
           (%fsync-directory path)
           path)
      (when tmp (ignore-errors (delete-file tmp))))))
