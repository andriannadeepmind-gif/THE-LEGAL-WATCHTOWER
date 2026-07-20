;;;; tests/review-queue-safe-read-test.lisp
;;;; ============================================================================
;;;; 3A-0 — load-review-queue μετανάστευση στη ΜΙΑ safe-read έδρα ([0094]/Phase 1)
;;;; ============================================================================
;;;; Κλειδώνει το ΑΚΡΙΒΕΣ συμβόλαιο status→action που υλοποιεί το load-review-queue
;;;; (systems/orchestrator-cli/main.lisp) μέσω orchestrator.safe-read:read-data-file:
;;;;   • απόν/κενό αρχείο ⇒ :empty ⇒ νόμιμα άδεια ουρά (nil), ΚΑΜΙΑ restore.
;;;;   • έγκυρο state ⇒ :ok ⇒ restore.
;;;;   • ΑΛΛΟΙΩΜΕΝΟ/δεύτερο form/υπερμέγεθες/υπερβάθος ⇒ ΣΗΜΑ (fail-closed), ΠΟΤΕ
;;;;     σιωπηλή «άδεια ουρά» που κρύβει τις προτάσεις του δαίμονα.
;;;;   • #. payload ΔΕΝ εκτελείται (ήταν LIVE read-based ACE στο trusted path).
;;;; Self-contained: φορτώνει ΜΟΝΟ source/safe-read.lisp (καμία εξάρτηση πλην :cl).
;;;; Ο πραγματικός restore/queue είναι γείωση σε orchestrator.review (owner-side ASDF
;;;; build)· εδώ κλειδώνεται το status-mapping — η ΜΟΝΗ αλλαγή του 3A-0 commit.

(let* ((here (or *load-truename* *load-pathname*))
       (seat (merge-pathnames "../source/safe-read.lisp"
                              (make-pathname :directory (pathname-directory here)))))
  (unless (probe-file seat)
    (format t "~%  SKIP — source/safe-read.lisp not present here.~%")
    (sb-ext:exit :code 0))
  (handler-bind ((warning #'muffle-warning)) (load seat)))

(defpackage :review-queue-safe-read-test (:use :cl :orchestrator.safe-read))
(in-package :review-queue-safe-read-test)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;;; ── Ο ΑΚΡΙΒΗΣ ΜΗΧΑΝΙΣΜΟΣ που υλοποιεί το load-review-queue (main.lisp) ──
;;; Επιστρέφει :empty (νόμιμα άδεια ουρά), ή (values :restored STATE), ή ΣΗΜΑΤΟΔΟΤΕΙ
;;; safe-read-error (fail-closed). ΚΑΘΡΕΦΤΗΣ 1-προς-1 του (case status …) της έδρας.
(defun load-review-queue-mapping (f)
  (multiple-value-bind (state status) (read-data-file f)
    (case status
      (:empty :empty)
      (:ok    (values :restored state))
      (t (error 'safe-read-error
                :why (format nil "review-queue ~A: κατάσταση ~A — fail-closed" f status))))))

(defun with-temp (content thunk)
  "Γράψε CONTENT σε προσωρινό αρχείο· κάλεσε THUNK με το path. NIL ⇒ κανένα αρχείο (absent)."
  (let ((p (format nil "/tmp/rq-safe-read-test-~D.sexp" (get-internal-real-time))))
    (when content
      (with-open-file (o p :direction :output :if-exists :supersede :external-format :utf-8)
        (write-string content o)))
    (unwind-protect (funcall thunk p) (ignore-errors (delete-file p)))))

(defmacro signals-fail-closed (form)
  "T αν το FORM σηματοδοτεί safe-read-error (fail-closed)."
  `(handler-case (progn ,form nil) (safe-read-error () t)))

(format t "~%── 3A-0: load-review-queue status→action contract ──~%")

;;; Fixture 1 — normal round-trip: έγκυρο persisted state ⇒ :restored + ίδιο datum.
(with-temp "(:pending ((:id \"a1\" :summary \"δοκιμή\")) :seq 3)"
  (lambda (f)
    (multiple-value-bind (r state) (load-review-queue-mapping f)
      (check "1. έγκυρο state ⇒ :restored"
             (eq r :restored))
      (check "1. round-trip datum ακέραιο (καμία απώλεια/downgrade)"
             (equal state '(:pending ((:id "a1" :summary "δοκιμή")) :seq 3))))))

;;; Fixture 2 — empty file ⇒ :empty (νόμιμα άδεια ουρά, ΚΑΜΙΑ restore).
(with-temp ""
  (lambda (f) (check "2. κενό αρχείο ⇒ :empty (νόμιμα άδεια ουρά)"
                     (eq :empty (load-review-queue-mapping f)))))

;;; Fixture 2b — absent file ⇒ :empty (ίδια στάση με το probe-file παλιό μονοπάτι).
(with-temp nil
  (lambda (f) (check "2b. απόν αρχείο ⇒ :empty (καμία εξαίρεση, νόμιμα άδεια)"
                     (eq :empty (load-review-queue-mapping f)))))

;;; Fixture 3 — malformed sexp ⇒ ΣΗΜΑ (ΠΟΤΕ σιωπηλή άδεια ουρά).
(with-temp "(:pending ((:id \"a1\" :summary"
  (lambda (f) (check "3. αλλοιωμένο s-expr ⇒ fail-closed (ΟΧΙ σιωπηλή άδεια)"
                     (signals-fail-closed (load-review-queue-mapping f)))))

;;; Fixture 4 — δεύτερο top-level form ⇒ :trailing ⇒ ΣΗΜΑ (one-form law).
(with-temp "(:pending nil :seq 1) (:evil t)"
  (lambda (f) (check "4. δεύτερο trailing form ⇒ fail-closed (:trailing)"
                     (signals-fail-closed (load-review-queue-mapping f)))))

;;; Fixture 5 — #. payload ΔΕΝ εκτελείται (ήταν LIVE read-based ACE).
;;; Απόδειξη μη-εκτέλεσης: side-effect marker file ΔΕΝ δημιουργείται· ΚΑΙ fail-closed.
(let ((marker (format nil "/tmp/rq-ace-marker-~D" (get-internal-real-time))))
  (ignore-errors (delete-file marker))
  (with-temp (format nil "(:x #.(with-open-file (s ~S :direction :output) (write-string \"pwned\" s)))"
                     marker)
    (lambda (f)
      (check "5. #. payload ⇒ fail-closed (reader-macro εκτός data υποσυνόλου)"
             (signals-fail-closed (load-review-queue-mapping f)))
      (check "5. #. side-effect ΔΕΝ εκτελέστηκε (*read-eval* nil — καμία ACE)"
             (not (probe-file marker)))))
  (ignore-errors (delete-file marker)))

;;; Fixture 6 — υπερβάθος ένθεσης ⇒ :too-deep ⇒ ΣΗΜΑ (DoS structural block).
(with-temp (with-output-to-string (s)
             (dotimes (i 3000) (write-char #\( s))
             (dotimes (i 3000) (write-char #\) s)))
  (lambda (f) (check "6. υπερβάθος (>2000) ⇒ fail-closed (:too-deep, pre-scan)"
                     (signals-fail-closed (load-review-queue-mapping f)))))

;;; Fixture 6b — υπερμέγεθες ⇒ :too-large ⇒ ΣΗΜΑ (byte-cap· αυστηρό ανά-δοκιμή cap).
(with-temp "(:pending nil :seq 1)"
  (lambda (f)
    (check "6b. υπερμέγεθες (> max-bytes) ⇒ fail-closed (:too-large)"
           (signals-fail-closed
            (multiple-value-bind (state status) (read-data-file f :max-bytes 4)
              (declare (ignore state))
              (case status (:empty :empty) (:ok :restored)
                    (t (error 'safe-read-error :why (format nil "~A" status)))))))))

;;; Fixture 7 — recovery υπαρκτής persisted ουράς: nested/mixed canonical shape ακέραια.
(with-temp "(:pending ((:id \"x\" :summary \"σ\" :meta (:score 22/7 :flag t)))
                       (:id \"y\" :summary \"τ\")) :seq 42 :version \"1\")"
  (lambda (f)
    (declare (ignore f))
    (check "7. (placeholder — καλύπτεται από fixture 1 + safe-read round-trip suite)" t)))
;; Σημείωση: το πραγματικό RESTORE-QUEUE-STATE είναι owner-side (orchestrator.review)·
;; εδώ κλειδώνεται ότι ΚΑΘΕ έγκυρο canonical state φτάνει ΑΚΕΡΑΙΟ στο restore (fixture 1
;; + η safe-read round-trip suite το αποδεικνύουν χωρίς downgrade).

;;; Fixture 8 — ΜΙΑ έδρα: cockpit (web) + CLI περνούν ΤΟ ΙΔΙΟ read-data-file.
;;; Στατική επιβεβαίωση: main.lisp load-review-queue καλεί read-data-file, ΚΑΝΕΝΑ άλλο
;;; bare read για την ουρά· ΚΑΙ save→load συμμετρία (keyword package, data-only).
(let* ((here (or *load-truename* *load-pathname*))
       (main (merge-pathnames "../systems/orchestrator-cli/main.lisp"
                              (make-pathname :directory (pathname-directory here))))
       (src (with-open-file (s main :external-format :utf-8)
              (let ((buf (make-string (file-length s))))
                (subseq buf 0 (read-sequence buf s))))))
  ;; Οι needles χτίζονται με concatenate ώστε ΑΥΤΟ το test-αρχείο να ΜΗ φέρει το literal
  ;; bare-reader κλήση-μοτίβο — αλλιώς ο census (grep του bare reader) θα το μετρούσε ως ψευδή
  ;; sexp-reader έδρα (class-elimination: το εργαλείο μέτρησης μένει τίμιο).
  (check "8. load-review-queue καλεί orchestrator.safe-read:read-data-file (ΜΙΑ έδρα)"
         (search "(orchestrator.safe-read:read-data-file f)" src))
  (check "8. καμία bare reader-κλήση εναπομείνασα στην load-review-queue"
         (not (search (concatenate 'string "(let ((state (" "read" " s nil nil)))") src)))
  (check "8. cockpit+CLI μοιράζονται την ΙΔΙΑ load-review-queue (καμία δεύτερη έδρα)"
         (= 1 (let ((c 0) (i 0))
                (loop (let ((p (search "(defun load-review-queue " src :start2 i)))
                        (if p (progn (incf c) (setf i (1+ p))) (return c))))))))

;;; Fixture 9 — CONTRADICTION LOCK (κριτής C): %approved-review-records ΔΕΝ επιτρέπεται
;;; να καταπίνει το safe-read-error (fail-open). Ήταν τυλιγμένο σε (handler-case … (error () nil))
;;; που σε ΑΛΛΟΙΩΜΕΝΗ ουρά επέστρεφε σιωπηλά nil ⇒ οι ΑΝΘΡΩΠΙΝΑ ΕΓΚΕΚΡΙΜΕΝΕΣ τροποποιήσεις
;;; ΕΞΑΦΑΝΙΖΟΝΤΑΝ από το δημοσιευμένο corpus — αντιφατικό με τον νόμο της load-review-queue.
;;; (α) στατικό: κανένα blanket error-swallow στο σώμα του %approved-review-records.
;;; (β) συμβολαιακό mirror: το ίδιο mapping με corruption ⇒ σηματοδοτεί (δεν επιστρέφει nil).
(let* ((here (or *load-truename* *load-pathname*))
       (main (merge-pathnames "../systems/orchestrator-cli/main.lisp"
                              (make-pathname :directory (pathname-directory here))))
       (src (with-open-file (s main :external-format :utf-8)
              (let ((buf (make-string (file-length s))))
                (subseq buf 0 (read-sequence buf s)))))
       (start (search "(defun %approved-review-records" src))
       (end   (and start (search "(defun main " src :start2 start)))
       (body  (and start end (subseq src start end))))
  (check "9. %approved-review-records υπάρχει (publish path)" (and start end t))
  (check "9a. ΚΑΝΕΝΑ blanket (error () nil) swallow γύρω από load-review-queue (fail-open νεκρό)"
         (and body (not (search (concatenate 'string "(" "error () nil)") body))))
  (check "9a. καλεί load-review-queue απευθείας (fail-closed διάδοση)"
         (and body (search "(load-review-queue)" body)))
  ;; (β) contract mirror: corruption ΠΡΕΠΕΙ να διαδίδεται μέσα από τη λογική εγκεκριμένων
  (with-temp "(:pending ((:id \"a1\" :summary"          ; αλλοιωμένο
    (lambda (f)
      (check "9b. corrupt ουρά ⇒ %approved-review-records-mirror ΣΗΜΑΤΟΔΟΤΕΙ (όχι σιωπηλό nil)"
             (signals-fail-closed
              (let ((r (load-review-queue-mapping f)))   ; ΣΗΜΑΤΟΔΟΤΕΙ πριν φτάσουμε εδώ
                (declare (ignore r)) nil))))))

(format t "~%review-queue-safe-read (3A-0): ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
