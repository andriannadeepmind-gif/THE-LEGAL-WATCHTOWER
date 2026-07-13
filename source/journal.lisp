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
           #:receipt-durability #:receipt-verified-p #:durable-p))

(in-package :orchestrator.journal)

(defun iso-now ()
  "Τοπικός χρόνος ISO-8601 (δευτερόλεπτο) — το ΕΝΑ ρολόι των ημερολογίων."
  (multiple-value-bind (sec min hour day mon year) (get-decoded-time)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0D"
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

(defvar *degraded* (make-hash-table :test 'equal :synchronized t)
  "namestring → t για ημερολόγια που αποδείχθηκαν ΜΗ ΕΓΓΡΑΨΙΜΑ (πχ read-only
   mount στο container). Η αδυναμία εγγραφής ΔΗΛΩΝΕΤΑΙ μία φορά και το
   ημερολόγιο συνεχίζει ΕΦΗΜΕΡΑ στη μνήμη — η απάντηση στον χρήστη ΔΕΝ
   θυσιάζεται ποτέ επειδή ο δίσκος αρνείται τη μνήμη.")

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

(defstruct (jcache (:constructor %make-jcache)) head tail count fwd)

(defvar *cache* (make-hash-table :test 'equal :synchronized t)
  "namestring → jcache (γραμμές στη μνήμη). Ενημερώνεται ΜΟΝΟ υπό το κλείδωμα
   του ημερολογίου — ο ένας συγγραφέας εγγυάται τη συνέπειά της.")

(defun %fsync (stream)
  (ignore-errors (finish-output stream))
  (ignore-errors (sb-posix:fsync (sb-sys:fd-stream-fd stream))))

(defun %load-lines (path)
  "Φόρτωσε τις γραμμές του PATH από τον δίσκο. ΑΝΘΕΚΤΙΚΗ ανάγνωση: κολοβή ουρά
   (crash στη μέση εγγραφής) κρατά το έγκυρο πρόθεμα και ΔΗΛΩΝΕΤΑΙ."
  (when (probe-file path)
    (with-open-file (s path :external-format :utf-8)
      (let ((*read-eval* nil)
            (*read-default-float-format* 'double-float)
            (*package* (find-package :keyword))
            (forms '()))
        (handler-case
            (loop for form = (read s nil nil) while form
                  do (push form forms))
          (error (e)
            (format *error-output*
                    "~&⚠ ημερολόγιο ~A: κολοβή ουρά (~A) — κρατήθηκαν ~D έγκυρες εγγραφές~%"
                    (file-namestring path) (type-of e) (length forms))))
        (nreverse forms)))))

(defun %cache-of (path)
  "Η ζωντανή cache του ημερολογίου — φορτώνεται/ξαναχτίζεται όταν χρειάζεται.
   Καλείται ΠΑΝΤΑ υπό το κλείδωμα του ημερολογίου."
  (let* ((key (namestring path))
         (fwd (and (probe-file path) (file-write-date path)))
         (c (gethash key *cache*)))
    (if (and c (eql (jcache-fwd c) fwd))
        c
        (let* ((lines (%load-lines path))
               (new (%make-jcache :head lines :tail (last lines)
                                  :count (length lines) :fwd fwd)))
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

(defun %readback-last-form (path)
  "ΦΡΕΣΚΙΑ ανάγνωση της τελευταίας φόρμας του PATH από τον δίσκο — παρακάμπτει
   ΣΚΟΠΙΜΑ την cache (το verification δεν εμπιστεύεται ό,τι μόλις έγραψε)."
  (car (last (%load-lines path))))

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
      (unless (or *ephemeral*              ; αντίγραφο ανάγνωσης: μόνο μνήμη
                  (gethash (namestring path) *degraded*))
        (handler-case
            (progn
              (ensure-directories-exist path)
              (with-open-file (s path :direction :output
                                 :if-exists :append :if-does-not-exist :create
                                 :external-format :utf-8)
                (write-string line s)
                (terpri s)
                (%fsync s))
              (setf wrote t))
          (error (e)
            ;; ΤΙΜΙΑ ΥΠΟΒΑΘΜΙΣΗ: δήλωσε ΜΙΑ φορά, συνέχισε εφήμερα — η
            ;; απάντηση δεν πεθαίνει επειδή το σύστημα αρχείων είναι read-only
            (setf (gethash (namestring path) *degraded*) t)
            (format *error-output*
                    "~&⚠ ημερολόγιο ~A: ΜΗ ΕΓΓΡΑΨΙΜΟ (~A) — συνεχίζω ΕΦΗΜΕΡΑ στη μνήμη· η κατάσταση δεν θα επιβιώσει επανεκκίνησης~%"
                    (file-namestring path) e))))
      (when (and wrote verify)
        (setf verified (equalp (%readback-last-form path) plist)))
      ;; Ο(1) επέκταση της cache με ουρά-δείκτη + νέο αποτύπωμα αρχείου
      (let ((cell (list plist)))
        (if (jcache-tail c)
            (setf (cdr (jcache-tail c)) cell)
            (setf (jcache-head c) cell))
        (setf (jcache-tail c) cell
              (jcache-count c) (1+ (jcache-count c)))
        (when wrote
          (setf (jcache-fwd c) (file-write-date path))))
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
