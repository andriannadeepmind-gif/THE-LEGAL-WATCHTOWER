;;;; tests/journal-integrity-test.lisp
;;;; ============================================================================
;;;; [RATCHET] ΑΚΕΡΑΙΟΤΗΤΑ ΗΜΕΡΟΛΟΓΙΟΥ — μόνιμοι ΑΡΝΗΤΙΚΟΙ μάρτυρες
;;;; ============================================================================
;;;; Κάθε έλεγχος εδώ σκοτώνει ΜΙΑ μετάλλαξη που ΕΠΙΒΙΩΝΕ πριν (καμία σουίτα
;;;; δεν την ασκούσε — το «45% επιβίωση» του ελέγχου μηχανής):
;;;;
;;;;   Α. fsync→no-op / αποτυχία fsync ⇒ ΠΟΤΕ :durable   [RATCHET-1]
;;;;   Β. δύο ΔΙΕΡΓΑΣΙΕΣ στο ίδιο journal ⇒ 0 χαμένα, 0 διπλά, αλυσίδα έγκυρη [RATCHET-2]
;;;;   Γ. αλλοίωση :text/:prev/:hash μεσαίου επεισοδίου ⇒ αποτυχία στην ΑΚΡΙΒΗ θέση [RATCHET-3]
;;;;   Δ. οπισθοδρόμηση transaction-time ⇒ fail-closed                    [RATCHET-4]
;;;;
;;;; ΚΑΝΕΝΑ SKIP→exit 0: απόν εργαλείο/αδύνατη εκτέλεση = ΑΠΟΤΥΧΙΑ (ο έλεγχος
;;;; μηχανής βρήκε 7 σουίτες που πρασίνιζαν σιωπηλά όταν έλειπε η έδρα τους).

(in-package :cl-user)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %tmpdir ()
  (let ((d (merge-pathnames (format nil "lawmax-journal-test-~D/"
                                    (sb-unix:unix-getpid))
                            #p"/tmp/")))
    (ensure-directories-exist d)
    d))

(defvar *tmp* (%tmpdir))
(defun %tmp (name) (merge-pathnames name *tmp*))

(defun %forget-cache (path)
  "Ξέχνα τη ζωντανή cache του ημερολογίου — μετά από ΑΠΕΥΘΕΙΑΣ επέμβαση στο
   αρχείο (οι έλεγχοι αλλοίωσης γράφουν εκτός της έδρας, όπως ο αντίπαλος)."
  (remhash (namestring path) orchestrator.journal::*cache*))

(defun %raw-lines (path)
  (with-open-file (s path :external-format :utf-8)
    (loop for l = (read-line s nil) while l collect l)))

(defun %write-raw-lines (path lines)
  (with-open-file (s path :direction :output :if-exists :supersede
                     :if-does-not-exist :create :external-format :utf-8)
    (dolist (l lines) (write-string l s) (terpri s))))

(defun %print-plist (plist)
  (let ((*package* (find-package :keyword))
        (*print-readably* nil) (*print-escape* t)
        (*print-pretty* nil) (*print-circle* nil))
    (format nil "~S" plist)))

(defun %parse-plist (line)
  (let ((*read-eval* nil) (*package* (find-package :keyword)))
    (read-from-string line)))

;;; ════════════════════════════════════════════════════════════════════════
(format t "~%== Α. ΤΙΜΙΟ DURABILITY: αποτυχία fsync ⇒ ΠΟΤΕ :durable [RATCHET-1] ==~%")
;;; ════════════════════════════════════════════════════════════════════════

(let ((p (%tmp "durability.sexp")))
  ;; Βάση: κανονική εγγραφή ΕΙΝΑΙ durable (αλλιώς ο επόμενος έλεγχος είναι κενός)
  (multiple-value-bind (plist receipt) (orchestrator.journal:append-line p '(:at "2026-01-01T00:00:00Z" :n 1))
    (declare (ignore plist))
    (check "βάση: υγιής εγγραφή ⇒ :durable"
           (eq (orchestrator.journal:receipt-durability receipt) :durable))
    (check "βάση: durable-p Τ" (orchestrator.journal:durable-p receipt)))

  ;; ΕΝΕΣΗ ΣΦΑΛΜΑΤΟΣ: το fsync αποτυγχάνει ελεγχόμενα
  (let ((orchestrator.journal:*fsync-fault* :test))
    (multiple-value-bind (plist receipt)
        (orchestrator.journal:append-line p '(:at "2026-01-01T00:00:01Z" :n 2))
      (declare (ignore plist))
      (check "fsync failure ⇒ durability = :sync-failed"
             (eq (orchestrator.journal:receipt-durability receipt) :sync-failed))
      (check "fsync failure ⇒ durable-p ΠΟΤΕ Τ"
             (not (orchestrator.journal:durable-p receipt)))
      (check "fsync failure ⇒ το receipt ΟΝΟΜΑΖΕΙ την αιτία (:sync-error)"
             (stringp (getf receipt :sync-error)))
      (check "fsync failure ⇒ ΘΕΣΜΙΚΟΣ συγγραφέας ΑΡΝΕΙΤΑΙ ταυτότητα (NOT-DURABLE)"
             (handler-case
                 (progn (orchestrator.journal:require-durable! receipt :test) nil)
               (orchestrator.journal:not-durable () t)))))

  ;; Η μη-συγχρονισμένη γραμμή ΔΕΝ γίνεται ουρά της αλυσίδας: ο επόμενος
  ;; συγγραφέας δεν χτίζει πάνω σε κάτι που δεν πιστοποιήθηκε.
  (check "μετά από αποτυχία συγχρονισμού, η ΕΠΟΜΕΝΗ εγγραφή είναι ξανά :durable"
         (multiple-value-bind (plist receipt)
             (orchestrator.journal:append-line p '(:at "2026-01-01T00:00:02Z" :n 3))
           (declare (ignore plist))
           (orchestrator.journal:durable-p receipt))))

;;; write-file-atomic: αποτυχία συγχρονισμού ⇒ ΣΦΑΛΜΑ, ποτέ σιωπηλή δημοσίευση
(let ((p (%tmp "atomic.txt")))
  (orchestrator.journal:write-file-atomic p "πρώτο")
  (check "write-file-atomic: βάση γράφει"
         (string= "πρώτο" (with-open-file (s p :external-format :utf-8)
                            (read-line s))))
  (let ((orchestrator.journal:*fsync-fault* :test))
    (check "write-file-atomic: αποτυχία fsync ⇒ SYNC-FAILURE (καμία σιωπηλή επιτυχία)"
           (handler-case (progn (orchestrator.journal:write-file-atomic p "δεύτερο") nil)
             (orchestrator.journal:sync-failure () t))))
  (check "write-file-atomic: το ΠΑΛΙΟ περιεχόμενο επιβιώνει άθικτο"
         (string= "πρώτο" (with-open-file (s p :external-format :utf-8)
                            (read-line s))))
  (check "write-file-atomic: κανένα ορφανό .tmp μετά την αποτυχία"
         (null (directory (merge-pathnames "*.tmp*" *tmp*)))))

;;; ════════════════════════════════════════════════════════════════════════
(format t "~%== Δ. ΜΟΝΟΤΟΝΙΑ TRANSACTION-TIME: οπισθοδρόμηση ρολογιού ⇒ fail-closed [RATCHET-4] ==~%")
;;; ════════════════════════════════════════════════════════════════════════

(let ((p (%tmp "monotonic.sexp")))
  (orchestrator.journal:append-line p '(:at "2026-05-10T12:00:00Z" :n 1))
  (check "ίδιο :at επιτρέπεται (κοκκίωση δευτερολέπτου — η σειρά δίνεται από το seq)"
         (multiple-value-bind (pl r) (orchestrator.journal:append-line p '(:at "2026-05-10T12:00:00Z" :n 2))
           (declare (ignore pl))
           (orchestrator.journal:durable-p r)))
  (check "μεταγενέστερο :at επιτρέπεται"
         (multiple-value-bind (pl r) (orchestrator.journal:append-line p '(:at "2026-05-10T12:00:05Z" :n 3))
           (declare (ignore pl))
           (orchestrator.journal:durable-p r)))
  (check "ΟΠΙΣΘΟΔΡΟΜΗΣΗ ρολογιού ⇒ NON-MONOTONIC-TRANSACTION-TIME (ποτέ σιωπηλή εισαγωγή)"
         (handler-case
             (progn (orchestrator.journal:append-line p '(:at "2026-05-10T11:59:59Z" :n 4)) nil)
           (orchestrator.journal:non-monotonic-transaction-time () t)))
  (check "η απορριφθείσα γραμμή ΔΕΝ άγγιξε τον δίσκο (3 γραμμές, όχι 4)"
         (= 3 (length (%raw-lines p))))
  ;; Προσομοίωση ΠΡΑΓΜΑΤΙΚΗΣ οπισθοδρόμησης του ρολογιού του συστήματος:
  ;; το iso-now (η ΜΙΑ πηγή χρόνου) γυρίζει πίσω — ο κανόνας πιάνει και αυτό.
  (let ((orchestrator.journal:*clock-override* "2026-05-10T10:00:00Z"))
    (check "clock rollback μέσω iso-now ⇒ fail-closed"
           (handler-case
               (progn (orchestrator.journal:chained-append
                       p (lambda (tail) (declare (ignore tail))
                           (list :at (orchestrator.journal:iso-now) :n 5)))
                      nil)
             (orchestrator.journal:non-monotonic-transaction-time () t))))
  (check "μετά την απόρριψη, το ημερολόγιο δέχεται ξανά κανονική εγγραφή"
         (multiple-value-bind (pl r) (orchestrator.journal:append-line p '(:at "2026-05-10T12:00:09Z" :n 6))
           (declare (ignore pl))
           (orchestrator.journal:durable-p r))))

;;; ════════════════════════════════════════════════════════════════════════
(format t "~%== Γ. ΕΠΑΛΗΘΕΥΣΗ ΑΛΥΣΙΔΑΣ ΕΠΕΙΣΟΔΙΩΝ: αλλοίωση ⇒ ΑΚΡΙΒΗΣ θέση [RATCHET-3] ==~%")
;;; ════════════════════════════════════════════════════════════════════════

(defun %fresh-episodes (n)
  "Καθαρό ρεύμα N επεισοδίων σε δικό του αρχείο· επιστρέφει το path."
  (let ((p (%tmp (format nil "episodes-~D.sexp" (random 1000000)))))
    (when (probe-file p) (delete-file p))
    (%forget-cache p)
    (let ((orchestrator.memory:*episodes-path* p))
      (dotimes (i n)
        (orchestrator.memory:record-episode
         :interaction (format nil "μαρτυρία ~D" i)
         :topic (list "νόμος") :props (list :i i))))
    p))

(defun %verify-at (path)
  (let ((orchestrator.memory:*episodes-path* path))
    (%forget-cache path)
    (multiple-value-list (orchestrator.memory:verify-episode-chain))))

(defun %tamper (path index mutate-fn)
  "Άλλαξε το INDEX-οστό (0-based) επεισόδιο με τη MUTATE-FN — απευθείας στο
   αρχείο, όπως θα έκανε ο αντίπαλος (εκτός της έδρας εγγραφής)."
  (let* ((lines (%raw-lines path))
         (plists (mapcar #'%parse-plist lines)))
    (setf (nth index plists) (funcall mutate-fn (nth index plists)))
    (%write-raw-lines path (mapcar #'%print-plist plists))
    (%forget-cache path)))

(let ((p (%fresh-episodes 5)))
  (destructuring-bind (ok n broken pos reason) (%verify-at p)
    (declare (ignore broken pos reason))
    (check "βάση: καθαρό ρεύμα 5 επεισοδίων ⇒ ΑΚΕΡΑΙΟ" ok)
    (check "βάση: μετρήθηκαν 5" (= n 5))))

;; Γ1 — αλλοίωση :text στο ΜΕΣΑΙΟ επεισόδιο (η μετάλλαξη που ΕΠΙΒΙΩΝΕ πριν)
(let ((p (%fresh-episodes 5)))
  (%tamper p 2 (lambda (e) (let ((c (copy-list e)))
                             (setf (getf c :text) "ΑΛΛΟΙΩΜΕΝΟ") c)))
  (destructuring-bind (ok n broken pos reason) (%verify-at p)
    (declare (ignore n))
    (check "Γ1 αλλοίωση :text ⇒ ΑΠΟΤΥΧΙΑ (πριν περνούσε ΠΡΑΣΙΝΗ)" (not ok))
    (check "Γ1 αιτία = :hash-mismatch" (eq reason :hash-mismatch))
    (check "Γ1 ΑΚΡΙΒΗΣ θέση = 3 (1-based)" (eql pos 3))
    (check "Γ1 αναφέρεται το ID του ελαττωματικού" (stringp broken))))

;; Γ2 — αλλοίωση :props (δεσμευμένο πεδίο, όχι μόνο το κείμενο)
(let ((p (%fresh-episodes 5)))
  (%tamper p 3 (lambda (e) (let ((c (copy-list e)))
                             (setf (getf c :props) (list :i 999)) c)))
  (destructuring-bind (ok n broken pos reason) (%verify-at p)
    (declare (ignore n broken))
    (check "Γ2 αλλοίωση :props ⇒ ΑΠΟΤΥΧΙΑ" (not ok))
    (check "Γ2 αιτία = :hash-mismatch" (eq reason :hash-mismatch))
    (check "Γ2 θέση = 4" (eql pos 4))))

;; Γ3 — αλλοίωση :prev (σπάσιμο του δεσμού αλυσίδας)
(let ((p (%fresh-episodes 5)))
  (%tamper p 2 (lambda (e) (let ((c (copy-list e)))
                             (setf (getf c :prev) (make-string 64 :initial-element #\a)) c)))
  (destructuring-bind (ok n broken pos reason) (%verify-at p)
    (declare (ignore n broken))
    (check "Γ3 αλλοίωση :prev ⇒ ΑΠΟΤΥΧΙΑ" (not ok))
    (check "Γ3 αιτία = :chain-break" (eq reason :chain-break))
    (check "Γ3 θέση = 3" (eql pos 3))))

;; Γ4 — αλλοίωση του ΙΔΙΟΥ του :hash (ο αντίπαλος «διορθώνει» τη σφραγίδα)
(let ((p (%fresh-episodes 5)))
  (%tamper p 1 (lambda (e) (let ((c (copy-list e)))
                             (setf (getf c :hash) (make-string 64 :initial-element #\b)) c)))
  (destructuring-bind (ok n broken pos reason) (%verify-at p)
    (declare (ignore n broken))
    (check "Γ4 αλλοίωση :hash ⇒ ΑΠΟΤΥΧΙΑ" (not ok))
    (check "Γ4 αιτία = :hash-mismatch" (eq reason :hash-mismatch))
    (check "Γ4 θέση = 2" (eql pos 2))))

;; Γ5 — αφαίρεση της σφραγίδας ⇒ μη επαληθεύσιμο, ΠΟΤΕ «ακέραιο»
(let ((p (%fresh-episodes 4)))
  (%tamper p 1 (lambda (e) (loop for (k v) on e by #'cddr
                                 unless (eq k :hash) append (list k v))))
  (destructuring-bind (ok n broken pos reason) (%verify-at p)
    (declare (ignore n broken pos))
    (check "Γ5 επεισόδιο ΧΩΡΙΣ :hash ⇒ ΑΠΟΤΥΧΙΑ (όχι σιωπηλή αποδοχή)" (not ok))
    (check "Γ5 αιτία = :missing-hash" (eq reason :missing-hash))))

;; Γ6 — υποβάθμιση σχήματος: αφαίρεση του :hv ώστε να πέσει στον legacy verifier
(let ((p (%fresh-episodes 4)))
  (%tamper p 2 (lambda (e) (loop for (k v) on e by #'cddr
                                 unless (eq k :hv) append (list k v))))
  (destructuring-bind (ok n broken pos reason) (%verify-at p)
    (declare (ignore n broken pos))
    (check "Γ6 αφαίρεση :hv (υποβάθμιση verifier) ⇒ ΑΠΟΤΥΧΙΑ" (not ok))
    (check "Γ6 αιτία = :hash-mismatch" (eq reason :hash-mismatch))))

;; Γ7 — η ΜΙΑ έδρα σειριοποίησης: το hash είναι συνάρτηση της ΑΞΙΑΣ, όχι της
;; αναπαράστασης (non-simple string ⇒ ίδιο hash — το ~S τύπωνε #A(...))
(check "Γ7 canon-sexp: non-simple string ≡ simple string (αξία, όχι αναπαράσταση)"
       (let* ((simple "αβγ")
              (adjustable (make-array 3 :element-type 'character
                                        :adjustable t :fill-pointer 3
                                        :initial-contents '(#\α #\β #\γ))))
         (string= (orchestrator.journal:canon-sexp (list :t simple))
                  (orchestrator.journal:canon-sexp (list :t adjustable)))))

;;; ════════════════════════════════════════════════════════════════════════
(format t "~%== Β. COMPARE-AND-APPEND: η διχάλα αλυσίδας ΔΟΜΙΚΑ αδύνατη [RATCHET-2] ==~%")
;;; ════════════════════════════════════════════════════════════════════════
;;; ΑΣΦΑΛΕΙΑ (ντετερμινιστικά, χωρίς κούρσα): κάθε record του οποίου ο δεσμός
;;; ΔΕΝ ταιριάζει με την ΠΡΑΓΜΑΤΙΚΗ ουρά του αρχείου ΑΠΟΡΡΙΠΤΕΤΑΙ. Αυτό δεν
;;; εξαρτάται από χρονισμό: είναι ιδιότητα της έδρας, άρα ελέγχεται κατ' ευθείαν.
;;; (Το κλείδωμα flock δίνει ΖΩΝΤΑΝΙΑ — ότι οι νόμιμοι συγγραφείς δεν
;;;  απορρίπτονται άδικα· αυτό ελέγχεται στο Β-E2E παρακάτω.)

(defun %chain-record (tail tag i)
  (let* ((prev (if tail (getf tail :hash) (make-string 64 :initial-element #\0)))
         (body (list :at "2026-06-01T00:00:00Z" :writer tag :i i :prev prev)))
    (append body (list :hash (orchestrator.journal:sha256-hex
                              (orchestrator.journal:canon-sexp body))))))

(let ((p (%tmp "cas.sexp")))
  (check "Β-S1 κενό ημερολόγιο: record με μηδενικό δείκτη ΓΙΝΕΤΑΙ δεκτό"
         (multiple-value-bind (pl r)
             (orchestrator.journal:chained-append
              p (lambda (tail) (%chain-record tail "a" 0)))
           (declare (ignore pl))
           (orchestrator.journal:durable-p r)))

  (check "Β-S2 κενό ημερολόγιο: record με ΑΥΘΑΙΡΕΤΟ δείκτη ΑΠΟΡΡΙΠΤΕΤΑΙ"
         (let ((q (%tmp "cas-empty.sexp")))
           (handler-case
               (progn (orchestrator.journal:chained-append
                       q (lambda (tail) (declare (ignore tail))
                           (%chain-record '(:hash "ff") "x" 0)))
                      nil)
             (orchestrator.journal:stale-chain-link () t))))

  ;; Ο ΠΥΡΗΝΑΣ: build-fn που αγνοεί την ουρά και χτίζει σε ΜΠΑΓΙΑΤΙΚΟ δεσμό —
  ;; ακριβώς ό,τι παράγει το TOCTOU παράθυρο δύο συγγραφέων.
  (let ((stale-tail (%parse-plist (car (last (%raw-lines p))))))
    (orchestrator.journal:chained-append p (lambda (tail) (%chain-record tail "a" 1)))
    (check "Β-S3 ΜΠΑΓΙΑΤΙΚΟΣ δεσμός (η ουρά προχώρησε) ⇒ STALE-CHAIN-LINK"
           (handler-case
               (progn (orchestrator.journal:chained-append
                       p (lambda (tail) (declare (ignore tail))
                           (%chain-record stale-tail "b" 0)))
                      nil)
             (orchestrator.journal:stale-chain-link () t)))
    (check "Β-S4 η απορριφθείσα εγγραφή ΔΕΝ άγγιξε τον δίσκο (2 γραμμές)"
           (= 2 (length (%raw-lines p))))
    (check "Β-S5 το σφάλμα ΟΝΟΜΑΖΕΙ αναμενόμενο ΚΑΙ πραγματικό δεσμό"
           (handler-case
               (progn (orchestrator.journal:chained-append
                       p (lambda (tail) (declare (ignore tail))
                           (%chain-record stale-tail "b" 1)))
                      nil)
             (orchestrator.journal:stale-chain-link (e)
               (and (stringp (orchestrator.journal:stale-chain-expected e))
                    (stringp (orchestrator.journal:stale-chain-actual e))
                    (not (equal (orchestrator.journal:stale-chain-expected e)
                                (orchestrator.journal:stale-chain-actual e))))))))

  ;; ΞΕΝΟΣ ΣΥΓΓΡΑΦΕΑΣ: κάποιος γράφει στο αρχείο εκτός της έδρας· η cache μας
  ;; είναι πλέον ψευδής. Ο έλεγχος γίνεται στον ΔΙΣΚΟ ⇒ καμία διχάλα.
  (let ((poisoned-tail (%parse-plist (car (last (%raw-lines p))))))
    (%write-raw-lines p (append (%raw-lines p)
                                (list (%print-plist
                                       (%chain-record poisoned-tail "ξένος" 0)))))
    (check "Β-S6 μετά από ΞΕΝΗ εγγραφή, χτίσιμο πάνω στην παλιά ουρά ⇒ ΑΠΟΡΡΙΨΗ"
           (handler-case
               (progn (orchestrator.journal:chained-append
                       p (lambda (tail) (declare (ignore tail))
                           (%chain-record poisoned-tail "c" 0)))
                      nil)
             (orchestrator.journal:stale-chain-link () t)))
    (check "Β-S7 χτίσιμο πάνω στην ΠΡΑΓΜΑΤΙΚΗ (ξένη) ουρά γίνεται δεκτό"
           (multiple-value-bind (pl r)
               (orchestrator.journal:chained-append
                p (lambda (tail) (%chain-record tail "c" 1)))
             (declare (ignore pl))
             (orchestrator.journal:durable-p r))))

  ;; Β-S8 ΠΟΛΥΓΡΑΜΜΟ RECORD: ένα record ΔΕΝ είναι μία φυσική γραμμή (το ~S
  ;; τυπώνει τα newlines αυτούσια μέσα στα strings). Ο δεσμός πρέπει να
  ;; επαληθεύεται σωστά ΚΑΙ όταν η ουρά εκτείνεται σε πολλές γραμμές — η
  ;; παραδοχή «τελευταία γραμμή = τελευταίο record» είναι ΛΑΘΟΣ γι' αυτό το
  ;; σχήμα (μετρημένο: ο builder έπαιρνε θραύσμα αντί record).
  (let ((q (%tmp "cas-multiline.sexp")))
    (orchestrator.journal:chained-append
     q (lambda (tail)
         (let* ((prev (if tail (getf tail :hash) (make-string 64 :initial-element #\0)))
                (body (list :at "2026-06-01T00:00:00Z"
                            :text (format nil "πρώτη γραμμή~%δεύτερη γραμμή~%τρίτη")
                            :prev prev)))
           (append body (list :hash (orchestrator.journal:sha256-hex
                                     (orchestrator.journal:canon-sexp body)))))))
    (check "Β-S8 πολύγραμμο record: η επόμενη εγγραφή δένει ΣΩΣΤΑ στην ουρά"
           (multiple-value-bind (pl r)
               (orchestrator.journal:chained-append
                q (lambda (tail)
                    (let* ((prev (getf tail :hash))
                           (body (list :at "2026-06-01T00:00:01Z" :text "δεύτερο" :prev prev)))
                      (append body (list :hash (orchestrator.journal:sha256-hex
                                                (orchestrator.journal:canon-sexp body)))))))
             (declare (ignore pl))
             (orchestrator.journal:durable-p r)))
    (check "Β-S8β μπαγιάτικος δεσμός ΜΕΤΑ από πολύγραμμο record ⇒ ΑΠΟΡΡΙΨΗ"
           (handler-case
               (progn (orchestrator.journal:chained-append
                       q (lambda (tail) (declare (ignore tail))
                           (%chain-record '(:hash "deadbeef") "x" 0)))
                      nil)
             (orchestrator.journal:stale-chain-link () t)))))

;;; ── ΖΩΝΤΑΝΙΑ: δύο ΠΡΑΓΜΑΤΙΚΕΣ διεργασίες, ένα ημερολόγιο ──
;;; Με φράγμα εκκίνησης ώστε να ΕΠΙΚΑΛΥΠΤΟΝΤΑΙ πραγματικά (χωρίς αυτό, ο χρόνος
;;; φόρτωσης κυριαρχεί και ο έλεγχος γίνεται κενός — μετρημένο).
;;; Απόδειξη ζωντάνιας: ΚΑΜΙΑ διεργασία δεν απορρίπτεται (exit 0) ΚΑΙ όλα τα
;;; records υπάρχουν — δηλαδή το flock σειριοποιεί αντί να αφήνει τις εγγραφές
;;; να συγκρούονται και να απορρίπτονται από το compare-and-append.
(format t "~%== Β-E2E. ΔΥΟ ΔΙΕΡΓΑΣΙΕΣ: ζωντάνια + 0 χαμένα + αλυσίδα έγκυρη ==~%")

(defparameter +writers+ 2)
(defparameter +per-writer+ 60)

(let* ((here (or *load-truename* *load-pathname*))
       (root (merge-pathnames "../" (make-pathname :directory (pathname-directory here))))
       (journal (%tmp "concurrent.sexp"))
       (child (%tmp "child-writer.lisp"))
       (go-file (%tmp "GO")))
  (with-open-file (s child :direction :output :if-exists :supersede
                     :if-does-not-exist :create :external-format :utf-8)
    (format s "(require :sb-posix)~%(require :asdf)~%")
    (format s "(asdf:initialize-source-registry '(:source-registry (:tree ~S) :inherit-configuration))~%"
            (namestring (merge-pathnames "third-party/" root)))
    (format s "(handler-bind ((warning #'muffle-warning)) (asdf:load-system :ironclad))~%")
    (format s "(handler-bind ((warning #'muffle-warning)) (load ~S))~%"
            (namestring (merge-pathnames "source/journal.lisp" root)))
    (format s "(defvar *tag* (second sb-ext:*posix-argv*))~%")
    (format s "(defvar *path* ~S)~%" (namestring journal))
    ;; φράγμα: δήλωσε ετοιμότητα, περίμενε το σήμα (με ΟΡΙΟ — ποτέ αιώνια αναμονή)
    (format s "(with-open-file (s (format nil ~S *tag*) :direction :output~%"
            (concatenate 'string (namestring *tmp*) "ready-~A"))
    (format s "                   :if-exists :supersede :if-does-not-exist :create)~%")
    (format s "  (write-string \"r\" s))~%")
    (format s "(let ((waited 0))~%")
    (format s "  (loop until (probe-file ~S)~%" (namestring go-file))
    (format s "        do (sleep 0.01) (incf waited)~%")
    (format s "           (when (> waited 6000) (sb-ext:exit :code 3))))~%")
    (format s "(dotimes (i ~D)~%" +per-writer+)
    (format s "  (funcall (intern \"CHAINED-APPEND\" \"ORCHESTRATOR.JOURNAL\") *path*~%")
    (format s "    (lambda (tail)~%")
    (format s "      (let* ((prev (if tail (getf tail :hash) (make-string 64 :initial-element #\\0)))~%")
    (format s "             (body (list :at \"2026-06-01T00:00:00Z\" :writer *tag* :i i :prev prev))~%")
    (format s "             (h (funcall (intern \"SHA256-HEX\" \"ORCHESTRATOR.JOURNAL\")~%")
    (format s "                  (funcall (intern \"CANON-SEXP\" \"ORCHESTRATOR.JOURNAL\") body))))~%")
    (format s "        (append body (list :hash h))))))~%")
    (format s "(sb-ext:exit :code 0)~%"))

  (let ((procs (loop for w below +writers+
                     collect (sb-ext:run-program "sbcl"
                                                 (list "--script" (namestring child)
                                                       (format nil "w~D" w))
                                                 :search t :wait nil
                                                 :output nil :error nil))))
    ;; περίμενε ετοιμότητα ΟΛΩΝ (με όριο), μετά δώσε το σήμα ⇒ πραγματική επικάλυψη
    (let ((waited 0) (ready nil))
      (loop until (or ready (> waited 6000))
            do (setf ready (loop for w below +writers+
                                 always (probe-file (%tmp (format nil "ready-w~D" w)))))
               (unless ready (sleep 0.01) (incf waited)))
      (check "Β-E2E0 και οι δύο διεργασίες έφτασαν στο φράγμα" ready))
    (with-open-file (s go-file :direction :output :if-exists :supersede
                       :if-does-not-exist :create)
      (write-string "go" s))
    (let ((codes (mapcar (lambda (p) (sb-ext:process-wait p) (sb-ext:process-exit-code p))
                         procs)))
      ;; ΚΑΝΕΝΑ SKIP: αποτυχία/απόρριψη παιδιού = ΑΠΟΤΥΧΙΑ, ποτέ «πράσινο»
      (check "Β-E2E1 ΖΩΝΤΑΝΙΑ: καμία διεργασία δεν απορρίφθηκε (exit 0)"
             (every (lambda (c) (eql c 0)) codes)))

    (%forget-cache journal)
    (let* ((lines (if (probe-file journal) (%raw-lines journal) '()))
           (plists (mapcar #'%parse-plist lines))
           (expected (* +writers+ +per-writer+))
           (keys (mapcar (lambda (e) (cons (getf e :writer) (getf e :i))) plists)))
      (check (format nil "Β-E2E2 ΚΑΝΕΝΑ ΧΑΜΕΝΟ record (~D = ~D×~D)" expected +writers+ +per-writer+)
             (= (length plists) expected))
      (check "Β-E2E3 ΚΑΝΕΝΑ ΔΙΠΛΟ record (μοναδικά writer×i)"
             (= (length (remove-duplicates keys :test #'equal)) (length keys)))
      (check "Β-E2E4 ΤΕΛΙΚΗ ΑΛΥΣΙΔΑ ΕΓΚΥΡΗ (κάθε :prev = :hash του προηγουμένου)"
             (let ((prev (make-string 64 :initial-element #\0)))
               (loop for e in plists
                     always (prog1 (equal (getf e :prev) prev)
                              (setf prev (getf e :hash))))))
      (check "Β-E2E5 κάθε :hash επαληθεύεται με ΕΠΑΝΥΠΟΛΟΓΙΣΜΟ"
             (loop for e in plists
                   always (equal (getf e :hash)
                                 (orchestrator.journal:sha256-hex
                                  (orchestrator.journal:canon-sexp
                                   (loop for (k v) on e by #'cddr
                                         unless (eq k :hash) append (list k v))))))))))

;;; ── καθαρισμός + ετυμηγορία ──
(ignore-errors
 (dolist (f (directory (merge-pathnames "*.*" *tmp*))) (ignore-errors (delete-file f)))
 (sb-posix:rmdir (namestring *tmp*)))

(format t "~%── journal-integrity: ~D passed, ~D failed ──~%" *pass* *fail*)
(sb-ext:exit :code (if (plusp *fail*) 1 0))
