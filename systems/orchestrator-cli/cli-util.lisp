;;;; systems/orchestrator-cli/cli-util.lisp
;;;; ============================================================================
;;;; CLI ΚΟΙΝΟΙ ΒΟΗΘΟΙ — τα θεμελιώδη, καθαρά εργαλεία που μοιράζονται ΟΛΕΣ οι
;;;; εντολές (string-hygiene, μόνιμη κατάσταση/cursors, ημερομηνία).
;;;; ============================================================================
;;;;
;;;; Βγήκαν από το φουσκωμένο main.lisp ως πρώτο βήμα της αποδόμησης του
;;;; «θεού-φακέλου»: αυτοτελείς (εξαρτώνται μόνο μεταξύ τους + CL/uiop/cl-ppcre),
;;;; φορτώνονται ΠΡΩΤΑ, ώστε κάθε επόμενο module εντολών να τους βρίσκει έτοιμους
;;;; χωρίς καμία forward-reference. Καμία αλλαγή συμπεριφοράς — μόνο θέσης.

(in-package :orchestrator.cli)

;;; ----------------------------------------------------------------------------
;;; ΜΗΤΡΩΟ ΕΝΤΟΛΩΝ — open/closed dispatch
;;; ----------------------------------------------------------------------------
;;;
;;; Ο ανώτερος τρόπος από τον γιγάντιο cond: κάθε module εντολών ΕΓΓΡΑΦΕΙ τις
;;; δικές του εδώ, και ο dispatch του main απλώς κοιτά το μητρώο. Νέα εντολή =
;;; μηδέν άγγιγμα στο main· ένα module εντολών φορτώνεται ΤΕΛΕΥΤΑΙΟ (όλοι οι
;;; βοηθοί του ήδη ορισμένοι) χωρίς καμία forward-reference.

(defvar *commands* (make-hash-table :test 'equal)
  "\"--foo\" → (lambda (user-args) → exit-code). Τα modules εγγράφουν εδώ.")

(defun register-command (name fn)
  "Εγγραφή εντολής NAME με χειριστή FN που λαμβάνει τα ορίσματα ΜΕΤΑ την εντολή
   (λίστα) και επιστρέφει exit-code."
  (setf (gethash name *commands*) fn))

(defun find-command (name)
  "Ο χειριστής της εντολής NAME, ή NIL όταν δεν είναι στο μητρώο."
  (and name (gethash name *commands*)))

;;; ----------------------------------------------------------------------------
;;; M1 — ΚΑΘΟΛΙΚΗ ΤΑΥΤΟΤΗΤΑ ΓΥΡΟΥ (turn_id / root span)
;;; ----------------------------------------------------------------------------
;;;
;;; Το turn_id είναι ΠΕΔΙΟ που διατρέχει τις ΥΠΑΡΧΟΥΣΕΣ έδρες (envelope,
;;; episode, failure-ledger, root-span) — ΟΧΙ νέο store. Οι μεταβλητές ζουν
;;; εδώ (φορτώνεται πρώτο) ώστε dispatch/decisions/ledger να τις βλέπουν
;;; χωρίς forward-reference· η ΓΕΝΝΗΣΗ γίνεται σε ΕΝΑ σημείο: είσοδος run-ask.
;;; Spec: deployment/LAWMAX-PHASE-1-TURN-ROOT-SPAN-DESIGN.{md,sexp}.

(defvar *current-turn-id* nil
  "Το turn_id του τρέχοντος --ask γύρου (\"turn:<sha256-12>\") ή NIL εκτός
   γύρου. Μηδενίζεται στην είσοδο ΚΑΘΕ εντολής (dispatch) — ποτέ stale.")

(defvar *turn-root-span* nil
  "Το tevent-id του root span (:command) του τρέχοντος γύρου, δεμένο 1↔1 με
   το *current-turn-id* — η αμφίδρομη αντιστοίχιση turn_id ↔ root_span_id.")

(defvar *turn-counter* 0
  "Αύξων μετρητής γύρων της διεργασίας — μπαίνει στο derivation ώστε διαδοχικοί
   γύροι με ΙΔΙΑ ερώτηση να παίρνουν ΔΙΑΦΟΡΕΤΙΚΟ turn_id (invariant ③).")

(defvar *turn-nonce* nil
  "Process nonce (γεννιέται τεμπέλικα στον πρώτο γύρο) — δύο διεργασίες την
   ίδια στιγμή με ίδια είσοδο δεν συγκρούονται.")

(defun new-turn-id! (input)
  "Γέννηση turn_id στην είσοδο του γύρου: sha256(input ‖ iso ‖ nonce ‖ counter),
   μορφή \"turn:<sha256-12>\". Δένει και το root span της στιγμής (αν υπάρχει)."
  (unless *turn-nonce*
    (setf *turn-nonce* (format nil "~36R~36R" (get-universal-time)
                               (get-internal-real-time))))
  (setf *current-turn-id*
        (format nil "turn:~A"
                (subseq (orchestrator.journal:sha256-hex
                         (format nil "~A|~A|~A|~D" input
                                 (orchestrator.journal:iso-now)
                                 *turn-nonce* (incf *turn-counter*)))
                        0 12))
        *turn-root-span* orchestrator.trace:*current-span*)
  *current-turn-id*)

;;; ----------------------------------------------------------------------------
;;; string hygiene
;;; ----------------------------------------------------------------------------

(defun %non-blank (s)
  "Return S unless it is NIL or blank/whitespace-only (env vars arrive as \"\")."
  (and s (stringp s) (plusp (length (string-trim '(#\Space #\Tab #\Newline #\Return) s))) s))

(defun %normspace (s)
  (string-trim " " (cl-ppcre:regex-replace-all "\\s+" (or s "") " ")))

(defun %current-year-string ()
  (multiple-value-bind (s m h d mo y) (decode-universal-time (get-universal-time))
    (declare (ignore s m h d mo))
    (princ-to-string y)))

;;; ----------------------------------------------------------------------------
;;; ΜΟΝΙΜΗ ΚΑΤΑΣΤΑΣΗ — keyed cursors (ΦΕΚ, ΑΠ, …) σε ΕΝΑ σπίτι
;;; ----------------------------------------------------------------------------

(defun %state-dir ()
  "Το ΕΝΑ σπίτι της μόνιμης κατάστασης (cursors, heartbeat). Ζει κάτω από το
   deployment/ επειδή αυτό είναι ήδη bind-mounted στο docker-compose — ένα
   /app/state ΕΚΤΟΣ mount θα πέθαινε με κάθε --rm container και ο δαίμονας θα
   ξεχνούσε πού έμεινε (αυτό ακριβώς συνέβη: ο cursor δεν επιβίωνε στον host)."
  (or (%non-blank (uiop:getenv "STATE_DIR")) "/app/deployment/state/"))

(defun %cursor-path (key)
  "File holding the last-seen number for cursor KEY. The legacy \"fek\" key keeps
   honouring FEK_STATE_FILE and its historic filename so existing deployments are
   untouched; ':' (illegal on some filesystems) becomes '_' for the rest."
  (if (string= key "fek")
      (or (%non-blank (uiop:getenv "FEK_STATE_FILE"))
          (merge-pathnames "fek-last-seen.txt" (%state-dir)))
      (merge-pathnames (format nil "~A-last-seen.txt" (substitute #\_ #\: key))
                       (%state-dir))))

(defun %read-cursor (key)
  "The highest number cursor KEY has already processed (persisted), or NIL on the
   first run."
  (let ((p (%cursor-path key)))
    (and (probe-file p)
         (ignore-errors (parse-integer (string-trim '(#\Space #\Newline #\Return #\Tab)
                                                     (uiop:read-file-string p)))))))

(defun %write-cursor (key n)
  "Persist N as the highest number processed on cursor KEY — ατομικά (tmp+rename):
   crash στη μέση δεν αφήνει ποτέ μισό/άδειο cursor."
  (let ((p (%cursor-path key)))
    (ignore-errors
     (orchestrator.journal:write-file-atomic p (format nil "~D~%" n))
     n)))

;; The ΦΕΚ discovery's original names, now thin aliases over the keyed cursor —
;; every existing caller keeps working with zero behaviour change.
(defun %read-last-seen () (%read-cursor "fek"))
(defun %write-last-seen (n) (%write-cursor "fek" n))

(defun require-provenance-or-untrusted (gate-name)
  "ΕΠΙΒΟΛΗ ΣΤΟ ENTRYPOINT: legal-critical πύλη χωρίς runtime provenance ΔΕΝ
   παράγει έμπιστη ετυμηγορία — δηλώνει untrusted και αποτυγχάνει. T = μπλόκο."
  (unless (orchestrator.trace:trace-enabled-p :legal-critical)
    (format t "~%── ~A ──~%~
output_status: untrusted~%~
trusted_output_allowed: false~%~
reason: legal-critical πύλη απαιτεί runtime provenance — προφίλ ιχνών ~(~A~)~%"
            gate-name orchestrator.trace:*trace-profile*)
    t))
