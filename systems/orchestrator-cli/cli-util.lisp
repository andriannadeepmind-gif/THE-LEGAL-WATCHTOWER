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

(defvar *command-owners* (make-hash-table :test 'equal)
  "\"--foo\" → namestring του αρχείου-ΙΔΙΟΚΤΗΤΗ (η έδρα της εντολής). Μία εντολή,
   ΕΝΑΣ ιδιοκτήτης — η σιωπηλή αντικατάσταση έδρας είναι ΔΟΜΙΚΑ αδύνατη.")

(define-condition command-seat-collision (error)
  ((name :initarg :name :reader collision-command-name)
   (owner :initarg :owner :reader collision-existing-owner)
   (claimant :initarg :claimant :reader collision-claimant))
  (:report (lambda (c s)
             (format s "ΣΥΓΚΡΟΥΣΗ ΕΔΡΑΣ ΕΝΤΟΛΗΣ «~A»: ιδιοκτήτης ~A, διεκδικητής ~A — ~
                        μία εντολή έχει ΜΙΑ έδρα· μετονόμασε τη νέα εντολή στην έδρα της."
                     (collision-command-name c)
                     (collision-existing-owner c)
                     (collision-claimant c)))))

(defun %registration-site ()
  "Το αρχείο-έδρα της τρέχουσας εγγραφής — από τη ΜΙΑ άδεια load-time αλήθειας
   (orchestrator.paths:current-load-file, FF1 ⑭: identity-only, ποτέ ρίζα)."
  (orchestrator.paths:current-load-file))

(defun register-command (name fn)
  "Εγγραφή εντολής NAME με χειριστή FN που λαμβάνει τα ορίσματα ΜΕΤΑ την εντολή
   (λίστα) και επιστρέφει exit-code. ΝΟΜΟΣ ΜΙΑΣ ΕΔΡΑΣ: αν το NAME ανήκει ήδη σε
   ΑΛΛΟ αρχείο, σφάλμα COMMAND-SEAT-COLLISION (καμία σιωπηλή αντικατάσταση) —
   επανεγγραφή από το ΙΔΙΟ αρχείο επιτρέπεται (idempotent reload)."
  (when (gethash name *retired-commands*)
    (error "ΑΝΑΣΤΑΣΗ ΚΑΤΑΡΓΗΜΕΝΗΣ ΕΔΡΑΣ «~A»: το όνομα είναι ΚΑΤΑΡΓΗΜΕΝΟ — ~
            καμία επανεγγραφή. Δες authority-v2/fixtures/legacy-authority/." name))
  (let ((site (%registration-site))
        (owner (gethash name *command-owners*)))
    ;; ΝΟΜΟΣ ΜΙΑΣ ΕΔΡΑΣ, fail-closed (re-review B-5): ανώνυμο runtime site ΔΕΝ
    ;; μπορεί να επαναδιεκδικήσει υπάρχουσα έδρα — αλλιώς δύο runtime εγγραφές
    ;; («<runtime>»≡«<runtime>») θα αντικαθιστούσαν σιωπηλά. Idempotent reload ίδιου
    ;; ΑΠΟΔΩΣΙΜΟΥ αρχείου επιτρέπεται.
    (when (and owner (or (not (orchestrator.paths:load-site-attributable-p site))
                         (string/= owner site)))
      (error 'command-seat-collision :name name :owner owner :claimant site))
    (setf (gethash name *command-owners*) site
          (gethash name *commands*) fn)))

;;; ----------------------------------------------------------------------------
;;; ΚΑΤΑΡΓΗΜΕΝΕΣ ΕΔΡΕΣ — ΜΙΑ ΕΔΡΑ ΓΙΑ ΟΛΕΣ, ΚΑΝΕΝΑ ΝΕΚΡΟ ΣΩΜΑ
;;; ----------------------------------------------------------------------------
;;;
;;; ΕΥΡΗΜΑ ΔΗΜΙΟΥΡΓΟΥ (P1): «το παλιό σώμα του --attest-release παραμένει
;;; μεταγλωττισμένο και η εντολή παραμένει εγγεγραμμένη». ΟΡΘΟ. Ένα σώμα που
;;; υπάρχει αλλά «δεν φτάνεται» είναι φρουρός γύρω από λάθος σχήμα: αρκεί μια
;;; μελλοντική επεξεργασία να μετακινήσει το (error …) και η παλιά διαδρομή
;;; ξαναζωντανεύει. Ο ΝΟΜΟΣ απαιτεί εξάλειψη της ΚΛΑΣΗΣ, όχι φύλαξη.
;;;
;;; ΕΔΩ: το σώμα ΔΙΑΓΡΑΦΕΤΑΙ (το ιστορικό ίχνος παγώνει σε
;;; authority-v2/fixtures/legacy-authority/). Το ΟΝΟΜΑ καταχωρείται ως
;;; ΚΑΤΑΡΓΗΜΕΝΟ σε ΕΝΑ μητρώο. Δεν υπάρχει συνάρτηση να κληθεί — υπάρχει μόνο
;;; τίμια απάντηση. Και η επανεγγραφή καταργημένου ονόματος είναι ΣΦΑΛΜΑ:
;;; καμία ανάσταση κατά λάθος.

(defvar *retired-commands* (make-hash-table :test 'equal)
  "\"--foo\" → plist (:reason :retired-in :replacement :site). ΚΑΤΑΡΓΗΜΕΝΗ ΕΔΡΑ:
   το όνομα ΔΕΝ έχει σώμα — ούτε απρόσιτο. Απαντά, δεν εκτελεί.")

(define-condition retired-command-invoked (error)
  ((name :initarg :name :reader retired-command-name)
   (info :initarg :info :reader retired-command-info))
  (:report (lambda (c s)
             (let ((i (retired-command-info c)))
               (format s "ΚΑΤΑΡΓΗΜΕΝΗ ΕΔΡΑ «~A»: ~A~@[~%  Καταργήθηκε: ~A~]~
                          ~@[~%  Αντικαταστάθηκε από: ~A~]~%  ~
                          Το σώμα της εντολής ΔΕΝ υπάρχει — δεν είναι απενεργοποιημένο, είναι ΔΙΑΓΡΑΜΜΕΝΟ."
                       (retired-command-name c)
                       (getf i :reason) (getf i :retired-in) (getf i :replacement))))))

(defun retire-command! (name &key reason retired-in replacement)
  "Καταχώρηση ΚΑΤΑΡΓΗΜΕΝΗΣ έδρας. Αν το NAME είναι ΕΝΕΡΓΟ στο μητρώο εντολών,
   ΣΦΑΛΜΑ: μια έδρα δεν μπορεί να είναι ταυτόχρονα ενεργή και καταργημένη."
  (when (gethash name *commands*)
    (error "ΑΝΤΙΦΑΣΗ ΕΔΡΑΣ «~A»: δηλώνεται ΚΑΤΑΡΓΗΜΕΝΗ ενώ είναι ΕΝΕΡΓΗ (~A)"
           name (gethash name *command-owners*)))
  (setf (gethash name *retired-commands*)
        (list :reason reason :retired-in retired-in :replacement replacement
              :site (%registration-site)))
  name)

(defun retired-command (name)
  "Το plist της καταργημένης έδρας NAME, ή NIL."
  (and name (gethash name *retired-commands*)))

(defun all-retired-commands ()
  (sort (loop for k being the hash-keys of *retired-commands* collect k) #'string<))

(defun find-command (name)
  "Ο χειριστής της εντολής NAME, ή NIL όταν δεν είναι στο μητρώο."
  (and name (gethash name *commands*)))

(defun resolve-command (name)
  "Η ΜΙΑ ΕΔΡΑ ΕΠΙΛΥΣΗΣ: (values handler kind), kind ∈ :registered|:retired|:unknown.
   ΕΝΕΡΓΗ ⇒ ο χειριστής της. ΚΑΤΑΡΓΗΜΕΝΗ ⇒ χειριστής που σηματοδοτεί
   RETIRED-COMMAND-INVOKED (τίμια απάντηση, όχι «Unknown command»). ΑΓΝΩΣΤΗ ⇒
   (values NIL :unknown) και ο καλών βάζει το usage — η τυπογραφία του usage
   ζει στο main, η ΚΡΙΣΗ ζει εδώ.
   Ο dispatcher ΚΑΙ κάθε απόδειξη περνούν από ΕΔΩ: δεν υπάρχει δεύτερη διαδρομή
   επίλυσης που θα μπορούσε να αποκλίνει σιωπηλά."
  (let ((h (find-command name)))
    (cond
      (h (values h :registered))
      ((retired-command name)
       (let ((info (retired-command name)))
         (values (lambda (args)
                   (declare (ignore args))
                   (error 'retired-command-invoked :name name :info info))
                 :retired)))
      (t (values nil :unknown)))))

(defun command-owner (name)
  "Το αρχείο-έδρα της εντολής NAME, ή NIL."
  (gethash name *command-owners*))

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

(defun %creator-request-authorised-p (key)
  "Η ΜΙΑ έδρα ταυτότητας δημιουργού για ΚΑΘΕ HTTP επιφάνεια (/ask, /cmd, cockpit):
   χωρίς LAWMAX_CREATOR_TOKEN (προσωπική τοπική εγκατάσταση) η θύρα ΕΙΝΑΙ ο
   δημιουργός· με token, απαιτείται KEY (από ?key=…) που ταιριάζει ΑΚΡΙΒΩΣ.
   KEY είναι το raw string της query (ή NIL αν λείπει). Καμία δεύτερη υλοποίηση
   αυτού του ελέγχου δεν επιτρέπεται — όλες οι επιφάνειες την ΚΑΤΑΝΑΛΩΝΟΥΝ."
  (let ((tok (%non-blank (uiop:getenv "LAWMAX_CREATOR_TOKEN"))))
    (or (null tok) (equal tok key))))

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
   ένα state ΕΚΤΟΣ του mount θα πέθαινε με κάθε --rm container και ο δαίμονας θα
   ξεχνούσε πού έμεινε (αυτό ακριβώς συνέβη: ο cursor δεν επιβίωνε στον host)."
  (or (%non-blank (uiop:getenv "STATE_DIR")) (orchestrator.paths:institution-dir "deployment/state/")))

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

;;; ── Η ΜΙΑ έδρα ντετερμινιστικής JSON εκπομπής (cli) ─────────────────────────
;;; Νόμος «0 διπλά»: κανένας cli emitter δεν ξαναϋλοποιεί escape/scalar διάκριση.
;;; (Οι epistemic emitters — census->json/%tlog — είναι release-identity-critical
;;;  bytes σε ΑΛΛΟ package· η διαπακετική ένωση είναι δηλωμένη ξεχωριστή φάση με
;;;  απόδειξη ότι τα release ids δεν μετακινούνται.)

;; [ΒΑΣΗ Β.2] Η τοπική %json-escape ΣΒΗΣΤΗΚΕ → ΜΙΑ έδρα orchestrator.spec:
;; json-string-escape (byte-identical). Το %json-scalar την καταναλώνει.

(defun %json-scalar (v)
  "Η ΜΙΑ cli scalar→JSON: NIL→null· float→~,4F (ντετ., locale-independent)·
   ακέραιος/λόγος→δεκαδική αναπαράσταση· αλλιώς \"escaped-string\". Κάθε cli
   deterministic emitter την ΚΑΤΑΝΑΛΩΝΕΙ — καμία inline επανάληψη της διάκρισης."
  (cond ((null v) "null")
        ((floatp v) (format nil "~,4F" v))
        ((integerp v) (princ-to-string v))
        ((rationalp v) (format nil "~,4F" (float v 1d0)))
        (t (format nil "\"~A\"" (orchestrator.spec:json-string-escape v)))))
