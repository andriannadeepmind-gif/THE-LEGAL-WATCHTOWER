;;;; systems/orchestrator-cli/understanding-learning.lisp
;;;; ============================================================================
;;;; ΜΑΘΗΣΗ ΚΑΤΑΝΟΗΣΗΣ — το learning substrate του διαλόγου (όχι περιεχόμενο)
;;;; ============================================================================
;;;;
;;;; Η εντολή του δημιουργού (2026-07-07): αν άνθρωπος γράφει τον επόμενο
;;;; ταξινομητή μετά από κάθε αποτυχία, φτιάχνουμε bot. Εδώ χτίζεται το
;;;; υπόστρωμα ώστε το ΙΔΙΟ το σύστημα να μετατρέπει τις αποτυχίες του σε
;;;; ΓΕΝΙΚΕΥΣΙΜΕΣ προτάσεις κατανόησης:
;;;;
;;;;   A. FAILURE LEDGER      δομημένο, επιθεωρήσιμο μητρώο αποτυχιών διαλόγου
;;;;   B. PROPOSAL GENERATOR  αποτυχία → δομημένη πρόταση ΚΑΝΟΝΑ (όχι patch)
;;;;   C. SHADOW EVALUATOR    original + positives + negatives + HELD-OUT
;;;;                          παραφράσεις + πλήρης regression σουίτα διαλόγου
;;;;   D. ADOPTION QUEUE      μέσω του ΥΠΑΡΧΟΝΤΟΣ proposals/--approve —
;;;;                          τίποτα δεν ενεργοποιείται χωρίς υπογραφή
;;;;
;;;; ΘΕΜΕΛΙΩΔΗΣ ΕΓΓΥΗΣΗ (εκ κατασκευής, όχι εκ πειθαρχίας): η γλώσσα των
;;;; κανόνων κατανόησης ΔΕΝ διαθέτει χαρακτηριστικό «περιέχει-τη-φράση» —
;;;; μόνο ΓΡΑΜΜΑΤΙΚΑ/ΔΟΜΙΚΑ χαρακτηριστικά (πράξη λόγου, κλειστές κλάσεις
;;;; δεικτών, κατάσταση μνήμης συνομιλίας, μορφή εκφοράς). Auto-regex bot
;;;; είναι ΑΔΥΝΑΤΟΣ σε αυτή τη γλώσσα: ο κανόνας που θα μάθαινε «μόνο τη
;;;; φράση που είδε» δεν μπορεί καν να διατυπωθεί.
;;;;
;;;; Οι χειροποίητοι ταξινομητές (cognition-self/legal) είναι BOOTSTRAP
;;;; σκαλωσιά — όχι απόδειξη μάθησης. Οι υιοθετημένοι κανόνες εδώ τρέχουν
;;;; ΠΡΙΝ από αυτούς: ό,τι μαθαίνεται, υπερισχύει του χειροποίητου.

(in-package :orchestrator.cli)

;;; ── Η ΓΛΩΣΣΑ ΧΑΡΑΚΤΗΡΙΣΤΙΚΩΝ (τα όργανα-αισθητήρια· κλειστό μητρώο) ──────
;;; Κάθε χαρακτηριστικό είναι συνάρτηση (input memory) → τιμή. ΚΑΝΕΝΑ δεν
;;; κοιτά αυθαίρετα substrings του input — μόνο κλειστές γραμματικές κλάσεις
;;; και κατάσταση. Νέο χαρακτηριστικό = νέα εγγραφή εδώ (bootstrap όργανο).

(defvar *understanding-features* (make-hash-table :test 'equal)
  "Μητρώο χαρακτηριστικών: όνομα → (fn . doc). Η ΜΟΝΗ ύλη των κανόνων.")

(defun deffeature (name doc fn)
  (setf (gethash name *understanding-features*) (cons fn doc))
  name)

(defun feature-names () (sort (loop for k being the hash-keys of *understanding-features* collect k) #'string<))

(defun %uf-recall (mem key) (orchestrator.cognition:recall mem key))

(deffeature "question"
  "Η εκφορά είναι ερώτηση (πράξη λόγου από κλειστή γραμματική κλάση)."
  (lambda (in mem) (declare (ignore mem))
    (eq (orchestrator.citation-authority:utterance-act in) :question)))

(deffeature "second-person"
  "Απευθύνεται στο σύστημα σε β' πρόσωπο (κλειστή κλιτική μορφολογία)."
  (lambda (in mem) (declare (ignore mem))
    (and (orchestrator.citation-authority:second-person-p in) t)))

(deffeature "reference-marker"
  "Φέρει δείκτη αναφοράς/διευκρίνισης (κλειστή κλάση: εννοείς/εξήγησε/δηλαδή/
   τι θα πει/πιο απλά/αυτό που είπες/εκεί το/αυτό το)."
  (lambda (in mem) (declare (ignore mem))
    (and (cl-ppcre:scan
          (orchestrator.decisions:%fold
           "εννοεις|εξηγησε|δηλαδη|τι θα πει|πιο απλα|αυτο που ειπες|εκει το|αυτο το|πρακτικα λεει|γιατι λες")
          (orchestrator.decisions:%fold in))
         t)))

(deffeature "has-last-answer"
  "Υπάρχει πρόσφατη εκφορά ΜΟΥ στη μνήμη συνεδρίας (υπάρχει referent)."
  (lambda (in mem) (declare (ignore in)) (and (%uf-recall mem :last-answer) t)))

(deffeature "last-answer-has-source"
  "Η προηγούμενη εκφορά μου παρέθετε πηγή/άρθρο (explainable legal span)."
  (lambda (in mem) (declare (ignore in))
    (let ((la (%uf-recall mem :last-answer)))
      (and la (cl-ppcre:scan "άρθρο|πηγή" la) t))))

(deffeature "quoted-span-in-last-answer"
  "Η εκφορά περιέχει απόσπασμα που ΥΠΑΡΧΕΙ στην προηγούμενη απάντησή μου
   (δεσμεύσιμο referent) — σύγκριση σε κανονικοποιημένη μορφή, ολόκληρο
   το ουσιώδες τμήμα της ερώτησης, όχι λέξη-λέξη."
  (lambda (in mem)
    (let ((la (%uf-recall mem :last-answer)))
      (when la
        (let* ((f (orchestrator.decisions:%fold in))
               (core (cl-ppcre:regex-replace-all
                      (orchestrator.decisions:%fold
                       "τι εννοεις|τι σημαινει|τι ειναι|εξηγησε μου|εξηγησε|δηλαδη|εκει το|αυτο το|;|\\?")
                      f ""))
               (clean (string-trim " «»\"" core)))
          (and (>= (length clean) 8)
               (search clean (orchestrator.decisions:%fold la))
               t))))))

(deffeature "arithmetic-expression"
  "Η εκφορά είναι/περιέχει ακέραιη αριθμητική πράξη (μορφή, όχι λεξιλόγιο)."
  (lambda (in mem) (declare (ignore mem)) (and (%parse-arith in) t)))

(deffeature "has-digits"
  "Περιέχει ψηφία." (lambda (in mem) (declare (ignore mem)) (and (cl-ppcre:scan "\\d" in) t)))

(deffeature "legal-concept"
  "Περιέχει επιλύσιμη νομική έννοια (γειωμένο λεξικό/ταξινομία)."
  (lambda (in mem) (declare (ignore mem)) (and (%resolve-concept in) t)))

(deffeature "known-content-lemma"
  "Τουλάχιστον ένα λήμμα περιεχομένου της εκφοράς είναι ΓΝΩΣΤΟ στο λεξικό μου."
  (lambda (in mem) (declare (ignore mem))
    (and (some (lambda (tok) (orchestrator.citation-authority:known-lemma tok))
               (orchestrator.citation-authority:tokenize-greek in))
         t)))

(defun input-features (input memory)
  "Το ΔΙΑΝΥΣΜΑ χαρακτηριστικών μιας εκφοράς — plist (όνομα → boolean)."
  (loop for name in (feature-names)
        for fn = (car (gethash name *understanding-features*))
        append (list name (and (ignore-errors (funcall fn input memory)) t))))

;;; ── ΟΙ ΚΑΝΟΝΕΣ ΚΑΤΑΝΟΗΣΗΣ (δηλωτική γνώση — knowledge pack) ─────────────
;;; (:understanding-rule :id … :when ((feature . t/nil)…) :frame :mode-keyword)
;;; Εγκαθίστανται ΜΟΝΟ μέσω υιοθεσίας (πρόταση→σκιά→υπογραφή). Ο διερμηνέας
;;; είναι ΕΝΑΣ, generic — δεν προστίθεται κώδικας ανά κανόνα.

(defvar *learned-rules* '())

(orchestrator.knowledge-packs:define-knowledge-kind :understanding-rules
  :doc "Μαθημένοι κανόνες κατανόησης διαλόγου (feature-based, ποτέ phrase-based)."
  :install (lambda (entries)
             (setf *learned-rules*
                   (append *learned-rules*
                           (loop for e in entries
                                 when (and (listp e) (eq (first e) :understanding-rule))
                                   collect (rest e)))))
  :snapshot (lambda () *learned-rules*)
  :restore (lambda (state) (setf *learned-rules* state)))

(defun validate-understanding-rule (rule)
  "Η ΠΥΛΗ ΕΙΣΟΔΟΥ της γλώσσας: λίστα παραβάσεων (κενή = έγκυρος).
   Phrase-patch = μη διατυπώσιμο: μόνο δηλωμένα χαρακτηριστικά επιτρέπονται."
  (let ((v '()))
    (unless (getf rule :id) (push "κανόνας χωρίς :id" v))
    (let ((w (getf rule :when)))
      (if (null w) (push "κανόνας χωρίς :when" v)
          (dolist (clause w)
            (unless (and (consp clause) (gethash (car clause) *understanding-features*))
              (push (format nil "άγνωστο/απαγορευμένο χαρακτηριστικό: ~S — μόνο το κλειστό μητρώο (~{~A~^, ~})"
                            clause (feature-names)) v)))))
    (let ((fr (getf rule :frame)))
      (unless (member fr '(:conversation-reference :self-meta :general
                           :general-computation :legal :clarify))
        (push (format nil "άγνωστη αφηρημένη κατηγορία: ~S" fr) v)))
    (nreverse v)))

(defun %rule-matches-p (rule input memory)
  (let ((fv (input-features input memory)))
    (every (lambda (clause)
             (eq (and (getf fv (car clause)) t) (and (cdr clause) t)))
           (getf rule :when))))

(defun %frame-for-category (cat input)
  (let ((cls (case cat
               (:conversation-reference 'conversation-reference-frame)
               ((:general :general-computation)
                (if (%parse-arith input) 'arithmetic-frame 'general-knowledge-frame))
               (:self-meta 'about-me-frame)
               (t nil))))
    (when cls
      (if (eq cls 'arithmetic-frame)
          (destructuring-bind (a op b) (%parse-arith input)
            (make-instance cls :input input :slots (list :a a :op op :b b)))
          (make-instance cls :input input)))))

;;; Ο ΕΝΑΣ διερμηνέας — εγγράφεται ΠΡΩΤΟΣ: ό,τι υπογράφηκε υπερισχύει της
;;; bootstrap σκαλωσιάς. Χωρίς υιοθετημένους κανόνες είναι διάφανος (nil).
(orchestrator.cognition:register-classifier "learned-understanding"
 (lambda (input)
   (let ((mem orchestrator.cognition:*current-memory*))
     (loop for rule in *learned-rules*
           when (and (null (validate-understanding-rule rule))
                     (%rule-matches-p rule input mem))
             do (let ((fr (%frame-for-category (getf rule :frame) input)))
                  (when fr (return fr)))))))

;;; ── A. FAILURE LEDGER — δομημένο μητρώο αποτυχιών διαλόγου ──────────────

(defun %failure-ledger-path ()
  (merge-pathnames "failure-ledger.jsonl" (%state-dir)))

(defun record-dialogue-failure! (&key input context wrong-mode expected-mode
                                      gap-id trace-id reason
                                      (source "live-dialogue"))
  "Κάθε γύρος που γεννά κενό κατανόησης γίνεται ΔΟΜΗΜΕΝΗ εγγραφή αποτυχίας —
   η πρώτη ύλη του proposal generator. Επιστρέφει το failure_id."
  (let ((fid (format nil "fail:~A"
                     (subseq (orchestrator.journal:sha256-hex
                              (format nil "~A|~A" input (or context ""))) 0 12))))
    (ignore-errors
      (let ((path (%failure-ledger-path)))
        (ensure-directories-exist path)
        (with-open-file (o path :direction :output :if-exists :append
                                :if-does-not-exist :create :external-format :utf-8)
          (write-string
           (jonathan:to-json
            (list (cons "failure_id" fid)
                  (cons "input" input)
                  (cons "previous_context" (or context ""))
                  (cons "produced_mode" (string-downcase (princ-to-string (or wrong-mode :none))))
                  (cons "wrong_behavior" (or reason "misclassification/gap"))
                  (cons "source" source)
                  (cons "expected_mode_if_known" (if expected-mode
                                            (string-downcase (princ-to-string expected-mode))
                                            "unknown"))
                  (cons "created_gap" (or gap-id ""))
                  (cons "trace_id" (princ-to-string (or trace-id "")))
                  (cons "status" "open")
                  (cons "ts" (orchestrator.journal:iso-now)))
            :from :alist) o)
          (terpri o))))
    fid))

(defun %raw-lines (path)
  "Raw γραμμές κειμένου (JSONL) — ΟΧΙ το sexp-journal (εκείνο διαβάζει plists)."
  (or (ignore-errors (uiop:read-file-lines path)) '()))

(defun open-failures ()
  "Οι ανοιχτές εγγραφές του ledger (raw γραμμές JSON, νεότερες τελευταίες)."
  (remove-if-not (lambda (l) (search "\"status\":\"open\"" l))
                 (%raw-lines (%failure-ledger-path))))

(defun run-failures (args)
  "--failures : το μητρώο αποτυχιών διαλόγου, επιθεωρήσιμο."
  (declare (ignore args))
  (let ((lines (%raw-lines (%failure-ledger-path))))
    (format t "~%── FAILURE LEDGER (~A) — ~D εγγραφές ──~%"
            (enough-namestring (%failure-ledger-path) (uiop:getcwd)) (length lines))
    (dolist (l (last lines 20)) (format t "  ~A~%" l))
    0))
(register-command "--failures" (lambda (a) (run-failures a)))

;;; ── B. PROPOSAL GENERATOR — αποτυχία → δομημένη πρόταση κανόνα ──────────

(defun %json-field (line field)
  (cl-ppcre:register-groups-bind (v)
      ((format nil "\"~A\":\"((?:[^\"\\\\]|\\\\.)*)\"" field) line)
    (cl-ppcre:regex-replace-all "\\\\\"" v "\"")))

(defun %held-out-paraphrases (input)
  "ΠΑΡΑΦΡΑΣΕΙΣ που ΔΕΝ είδε ο κανόνας: εναλλαγή δεικτών μέσα στην κλειστή
   κλάση + δομικές παραλλαγές. Παράγονται ντετερμινιστικά, αποκλείουν το
   πρωτότυπο. (v1 — αργότερα: η γεννήτρια ελληνικών.)"
  (let* ((f (string-trim " ;?" (orchestrator.decisions:%fold input)))
         ;; οι δείκτες αναδιπλώνονται με την ΙΔΙΑ %fold (τελικό ς→σ κ.λπ.)
         (markers (mapcar #'orchestrator.decisions:%fold
                          '("τι εννοείς" "εξήγησέ μου" "δηλαδή τι σημαίνει"
                            "τι θα πει" "πιο απλά τι λες")))
         (present (find-if (lambda (m) (search m f)) markers))
         (rest-part (string-trim " ;?—"
                                 (if present (cl-ppcre:regex-replace
                                              (cl-ppcre:quote-meta-chars present) f "")
                                     f))))
    (remove-duplicates
     (remove-if (lambda (p) (string= (string-trim " ;?" (orchestrator.decisions:%fold p)) f))
               (append
                (loop for m in markers
                      collect (format nil "~A ~A;" m rest-part))
                (list (format nil "αυτο που ειπες — ~A — εξηγησε το πιο απλα" rest-part)
                      (format nil "μπορεις να μου εξηγησεις τι θα πει ~A;" rest-part))))
     :test #'string=)))

(defun %induce-rule (input context expected)
  "Επαγωγή ΓΕΝΙΚΟΥ κανόνα: κράτα μόνο τα ΘΕΤΙΚΑ διακριτικά χαρακτηριστικά της
   αποτυχίας (ποτέ tokens). Το context μπαίνει σε προσωρινή μνήμη ώστε τα
   memory-features να αποτιμηθούν όπως στη ζωντανή στιγμή."
  (let* ((mem (make-instance 'orchestrator.cognition:working-memory)))
    (when (plusp (length (or context "")))
      (orchestrator.cognition:remember mem :last-answer context))
    (let* ((fv (input-features input mem))
           (on (loop for (k v) on fv by #'cddr when v collect (cons k t))))
      (list :id (format nil "ur:~A" (subseq (orchestrator.journal:sha256-hex input) 0 10))
            :when on
            :frame expected))))

(defun generate-understanding-proposal (failure-line &key expected-mode)
  "Η ΜΙΑ αποτυχία → η ΠΛΗΡΗΣ δομημένη πρόταση (τα 16 πεδία του δημιουργού).
   ΔΕΝ εγκαθιστά τίποτα — παράγει, αξιολογεί σε ΣΚΙΑ, καταθέτει στην ουρά."
  (let* ((fid (%json-field failure-line "failure_id"))
         (input (%json-field failure-line "input"))
         (context (%json-field failure-line "previous_context"))
         (wrong (%json-field failure-line "produced_mode"))
         (expected (or expected-mode
                       (let ((e (%json-field failure-line "expected_mode_if_known")))
                         (and e (not (string= e "unknown"))
                              (intern (string-upcase e) :keyword))))))
    (if (null expected)
        (list :decision :quarantine :observed-failure-ids (list fid) :input input
              :reason "expected_mode άγνωστο — απαιτείται σχολιασμός δημιουργού (καμία εικασία)")
        (let* ((rule (%induce-rule input context expected))
               (viol (validate-understanding-rule rule))
               (held (%held-out-paraphrases input))
               (positives (cons input held))
               ;; αρνητικά: εκφορές ΑΛΛΩΝ τρόπων από τη ζωντανή σουίτα regression
               (negatives '("τι λέει το άρθρο 280 του κώδικα πολιτικής δικονομίας;"
                            "τι σημαίνει δομημένη απάντηση;"
                            "ποιος είσαι;"
                            "απάντησε στην ουσία της αγωγής"
                            "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας για να το ιδιοποιηθεί.")))
          (append
           (list :proposal-id (format nil "up:~A" (subseq (orchestrator.journal:sha256-hex (or fid input)) 0 10))
                 :observed-failure-ids (list fid)
                 :abstract-failure-class (format nil "~A↛~(~A~)" wrong expected)
                 :induced-frame expected
                 :failure-id fid
                 :input input
                 :context (subseq (or context "") 0 (min 200 (length (or context ""))))
                 :wrong-mode wrong
                 :expected-mode expected
                 :rule rule
                 :required-features (mapcar #'car (getf rule :when))
                 :why-not-phrase-specific
                 (format nil "η γλώσσα κανόνων δεν διαθέτει token/phrase χαρακτηριστικά — ο κανόνας αναφέρεται μόνο σε: ~{~A~^, ~}"
                         (mapcar #'car (getf rule :when)))
                 :positive-tests positives
                 :negative-tests negatives
                 :held-out-tests held
                 :regression-tests "πλήρης σουίτα --dialogue-gate"
                 :affected-modes (list expected wrong)
                 :affected-contracts '("understanding-rule-language")
                 :affected-capabilities '("διάλογος" "μάθηση-κατανόησης")
                 :rollback-plan "αφαίρεση του pack κανόνα (hot) — ο διερμηνέας μένει διάφανος"
                 :language-violations viol)
           (if viol (list :decision :denied)
               (shadow-evaluate-rule rule input positives negatives held context)))))))

;;; ── C. SHADOW EVALUATOR ──────────────────────────────────────────────────

(defun %classify-with-rule (rule input context)
  "Ταξινόμηση ΟΠΩΣ θα γινόταν ζωντανά, με τον κανόνα προσωρινά εγκατεστημένο."
  (let ((mem (make-instance 'orchestrator.cognition:working-memory)))
    (when (plusp (length (or context "")))
      (orchestrator.cognition:remember mem :last-answer context))
    (let ((orchestrator.cognition:*current-memory* mem)
          (*learned-rules* (cons rule *learned-rules*)))
      (let ((fr (orchestrator.cognition:decompose input)))
        (and fr (%frame->mode fr t nil))))))

(defun shadow-evaluate-rule (rule original positives negatives held context)
  "ΣΚΙΑ: (1) η αρχική αποτυχία διορθώνεται· (2) positives στο σωστό mode·
   (3) negatives ΔΕΝ αλλάζουν mode· (4) held-out ≥ 2/3· (5) regression: η
   πλήρης σουίτα διαλόγου πράσινη με τον κανόνα εγκατεστημένο.
   Πλήρες αποτέλεσμα + ετυμηγορία — ποτέ σιωπηλό pass."
  (when (null negatives)                       ; φρουρός #7: χωρίς negatives ⇒ DENIED
    (return-from shadow-evaluate-rule
      (list :shadow (list :candidate-rule-id (getf rule :id) :error "no negative tests")
            :decision :denied)))
  (let* ((target (getf rule :frame))
         (mode-of (lambda (in ctx) (%classify-with-rule rule in ctx)))
         (stable-mode (let ((mem (make-instance 'orchestrator.cognition:working-memory)))
                        (when (plusp (length (or context "")))
                          (orchestrator.cognition:remember mem :last-answer context))
                        (let ((orchestrator.cognition:*current-memory* mem))
                          (let ((fr (orchestrator.cognition:decompose original)))
                            (and fr (%frame->mode fr t nil))))))
         (orig-ok (eq (funcall mode-of original context) target))
         (pos-fail (count-if-not (lambda (p) (eq (funcall mode-of p context) target))
                                 positives))
         (neg-fail (count-if (lambda (n) (eq (funcall mode-of n nil) target))
                             negatives))
         (held-pass (count-if (lambda (h) (eq (funcall mode-of h context) target)) held))
         (regression-ok
           (let ((*learned-rules* (cons rule *learned-rules*)))
             (zerop (let ((*standard-output* (make-broadcast-stream)))
                      (run-dialogue-gate))))))
    (list :shadow (list :candidate-rule-id (getf rule :id)
                        :stable-result stable-mode
                        :candidate-result (funcall mode-of original context)
                        :original-fixed orig-ok
                        :positives-failed pos-fail
                        :negatives-fired neg-fail
                        :held-out-passed (list held-pass (length held))
                        :regression-green regression-ok)
          :decision (cond ((not regression-ok) :denied)  ; έσπασε υπάρχουσα κατανόηση
                          ((plusp neg-fail) :denied)     ; υπεργενίκευση
                          ((not orig-ok) :denied)        ; δεν λύνει καν την αποτυχία
                          ((< (* 3 held-pass) (* 2 (length held))) :quarantine)
                          (t :requires-human)))))        ; ΠΟΤΕ αυτόματο adoptable

;;; ── D. ADOPTION QUEUE — μέσω της ΥΠΑΡΧΟΥΣΑΣ ουράς προτάσεων ─────────────

(defun run-learn-understanding (args)
  "--learn-understanding [expected-mode] : ένας κύκλος του substrate πάνω στο
   ledger: για κάθε ανοιχτή αποτυχία παράγεται πρόταση, αξιολογείται σε σκιά
   και -αν επιζήσει- κατατίθεται στην ουρά έγκρισης. ΚΑΜΙΑ ενεργοποίηση εδώ."
  (let ((expected (and args (intern (string-upcase (first args)) :keyword)))
        (fails (open-failures)))
    (format t "~%── ΜΑΘΗΣΗ ΚΑΤΑΝΟΗΣΗΣ: ~D ανοιχτές αποτυχίες ──~%" (length fails))
    (dolist (fl (last fails 5))
      (let ((p (generate-understanding-proposal fl :expected-mode expected)))
        (format t "~%• ~A «~A»~%  ετυμηγορία σκιάς: ~(~A~)~@[ — ~A~]~%"
                (getf p :failure-id) (getf p :input)
                (getf p :decision) (getf p :reason))
        (when (getf p :shadow)
          (format t "  σκιά: ~S~%" (getf p :shadow)))
        (when (eq (getf p :decision) :requires-human)
          (orchestrator.proposals:propose!
           :sig (format nil "understanding-rule ~A" (getf p :failure-id))
           :kind :understanding-rule
           :why (format nil "μάθηση κατανόησης από ~A: «~A» → ~(~A~) (γενικός κανόνας: ~{~A~^+~})"
                        (getf p :failure-id) (getf p :input) (getf p :expected-mode)
                        (mapcar #'car (getf (getf p :rule) :when)))
           :payload (prin1-to-string
                     (list :filename (format nil "understanding-~A.sexp"
                                             (subseq (orchestrator.journal:sha256-hex
                                                      (getf p :failure-id)) 0 8))
                           :pack-text (with-output-to-string (o)
                                        (let ((*print-pretty* nil))
                                          (format o "(:knowledge-pack :understanding-rules 1~%")
                                          (format o " ;; ΑΥΤΟ-ΠΡΟΤΑΘΗΚΕ από αποτυχία ~A — feature-based, όχι phrase~%"
                                                  (getf p :failure-id))
                                          (format o " (:understanding-rule ~{~S ~}))~%"
                                                  (getf p :rule))))
                           :proposal p)))
          (format t "  → ΚΑΤΑΤΕΘΗΚΕ στην ουρά έγκρισης (--thoughts / --approve)~%"))))
    0))
(register-command "--learn-understanding" (lambda (a) (run-learn-understanding a)))

;;; ── ΔΗΛΩΣΗ ΣΤΟΝ ΚΑΘΡΕΦΤΗ (ratchet) ──────────────────────────────────────

(orchestrator.self-model:declare-capability! "μάθηση-κατανόησης"
 :description "learning substrate διαλόγου: failure ledger → feature-based rule proposal → shadow (positives/negatives/held-out/regression) → ουρά υπογραφής· phrase-patch αδύνατο εκ κατασκευής"
 :package :orchestrator.cli
 :functions '("record-dialogue-failure!" "generate-understanding-proposal"
              "shadow-evaluate-rule" "validate-understanding-rule")
 :gate "--understanding-gate"
 :depends-on '("διάλογος" "πακέτα-γνώσης" "πολιτικές-έγκρισης"))

(orchestrator.contracts:defcontract "understanding-rule-language" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "μάθηση-κατανόησης" :role "νόηση"
 :purpose "οι κανόνες κατανόησης διατυπώνονται ΜΟΝΟ σε δηλωμένα γραμματικά/δομικά χαρακτηριστικά — token/phrase literals ανύπαρκτα στη γλώσσα"
 :inputs '("failure ledger εγγραφές" "expected abstract category (δημιουργός όταν άγνωστο)")
 :outputs '("δομημένη πρόταση 16 πεδίων" "ετυμηγορία σκιάς" "pack :understanding-rules")
 :preconditions '("κάθε χαρακτηριστικό στο κλειστό μητρώο *understanding-features*")
 :postconditions '("υπεργενίκευση ⇒ denied από negatives" "phrase-fit ⇒ αδιατύπωτο"
                   "καμία ενεργοποίηση χωρίς υπογραφή δημιουργού")
 :side-effects '("εγγραφές failure-ledger.jsonl" "προτάσεις στην ουρά Σ11")
 :legal-critical nil :policy-level :ανθρώπινη-έγκριση
 :audit "κάθε πρόταση φέρει shadow report + held-out αποτελέσματα"
 :rollback "αφαίρεση pack κανόνα — hot, ο διερμηνέας μένει διάφανος"
 :tests '("--understanding-gate"))

;;; ── Η ΠΥΛΗ ──────────────────────────────────────────────────────────────

(defun run-understanding-gate ()
  "--understanding-gate : το learning substrate, κλειδωμένο."
  (let ((fails '()) (total 0))
    (flet ((chk (label ok)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΜΑΘΗΣΗΣ ΚΑΤΑΝΟΗΣΗΣ ──~%")
      ;; ① Α: αποτυχία ⇒ δομημένη εγγραφή με όλα τα πεδία
      (let ((fid (record-dialogue-failure!
                  :input "δοκιμαστική-αποτυχία-πύλης;" :context "δοκιμή"
                  :wrong-mode :legal-diagnostic :gap-id "gap:test")))
        (chk "① ledger: δομημένη εγγραφή (failure_id/input/context/wrong_mode/status)"
             (let ((l (find-if (lambda (x) (search fid x)) (open-failures))))
               (and l (%json-field l "produced_mode") (%json-field l "status")))))
      ;; ② γλώσσα: phrase-χαρακτηριστικό = ΑΔΙΑΤΥΠΩΤΟ (απορρίπτεται ονομαστικά)
      (chk "② phrase-patch αδύνατο: κανόνας με χαρακτηριστικό «contains-token» ⇒ άκυρος"
           (let ((viol (validate-understanding-rule
                        '(:id "x" :when (("contains-token" . t)) :frame :general))))
             (and viol (search "απαγορευμένο" (first viol)))))
      ;; ③ Β: πλήρης πρόταση 16 πεδίων από συνθετική αποτυχία
      (let* ((line (jonathan:to-json
                    (list (cons "failure_id" "fail:gate-b")
                          (cons "input" "τι εννοείς να έχει απαντήσει στην ουσία;")
                          (cons "context" "…χωρίς να έχει απαντήσει στην ουσία, θεωρείται ότι δεν μετέχει… (ΚΠολΔ άρθρο 280)")
                          (cons "wrong_mode" "self-meta")
                          (cons "expected_mode_if_known" "conversation-reference")
                          (cons "status" "open"))
                    :from :alist))
             (p (generate-understanding-proposal line)))
        (chk "③ generator: 16 πεδία — rule/why-not-patch/positives/negatives/held-out/rollback/shadow/verdict"
             (and (getf p :proposal-id) (getf p :observed-failure-ids)
                  (getf p :abstract-failure-class) (getf p :induced-frame)
                  (getf p :rule) (getf p :required-features)
                  (getf p :why-not-phrase-specific)
                  (getf p :positive-tests) (getf p :negative-tests)
                  (getf p :held-out-tests) (getf p :rollback-plan)
                  (getf p :affected-modes) (getf p :affected-contracts)
                  (getf p :shadow) (getf p :decision)))
        ;; ④ ο επαχθείς κανόνας είναι ΓΕΝΙΚΟΣ: μόνο ονόματα χαρακτηριστικών
        (chk "④ ο κανόνας αναφέρεται ΜΟΝΟ σε χαρακτηριστικά του μητρώου (κανένα token)"
             (null (validate-understanding-rule (getf p :rule))))
        ;; ⑤ Γ: ετυμηγορία ΠΟΤΕ αυτόματα adoptable — μέγιστο requires-human
        (chk "⑤ σκιά: μέγιστη ετυμηγορία requires-human (η υπογραφή αναπαλλοτρίωτη)"
             (member (getf p :decision) '(:requires-human :quarantine :denied)))
        ;; ⑥ held-out: αξιολογήθηκαν παραφράσεις που ΔΕΝ είναι το πρωτότυπο
        (chk "⑥ held-out: ≥3 παραφράσεις, καμία ταυτόσημη με το πρωτότυπο"
             (let ((h (getf p :held-out-tests)))
               (and (>= (length h) 3)
                    (notany (lambda (x)
                              (string= (orchestrator.decisions:%fold x)
                                       (orchestrator.decisions:%fold
                                        "τι εννοείς να έχει απαντήσει στην ουσία;")))
                            h)))))
      ;; ⑦ υπεργενίκευση ⇒ DENIED: κανόνας «κάθε ερώτηση ⇒ general» σκοτώνεται
      (chk "⑦ υπεργενίκευση: «question⇒general» ⇒ denied (τα negatives τον καίνε)"
           (eq (getf (shadow-evaluate-rule
                      '(:id "ur:over" :when (("question" . t)) :frame :general)
                      "τι είναι η κβαντομηχανική;"
                      '("τι είναι η κβαντομηχανική;")
                      '("τι λέει το άρθρο 280 του κώδικα πολιτικής δικονομίας;")
                      '("ποια είναι η πρωτεύουσα της Ισπανίας;") nil)
                     :decision)
               :denied))
      ;; ⑦β φρουρός: πρόταση ΧΩΡΙΣ negative tests ⇒ denied
      (chk "⑦β χωρίς negatives ⇒ denied (φρουρός acceptance #7)"
           (eq (getf (shadow-evaluate-rule
                      '(:id "ur:noneg" :when (("question" . t)) :frame :general)
                      "x;" '("x;") '() '("y;") nil)
                     :decision)
               :denied))
      ;; ⑧ Δ: χωρίς υπογραφή ΤΙΠΟΤΑ δεν ενεργοποιείται — ο διερμηνέας διάφανος
      (chk "⑧ καμία ενεργοποίηση χωρίς υπογραφή: *learned-rules* ανεπηρέαστο από generator"
           (null *learned-rules*))
      ;; ⑨ ο διερμηνέας ΕΝΕΡΓΟΠΟΙΕΙ υπογεγραμμένο κανόνα (hot, αναστρέψιμα)
      (chk "⑨ υιοθετημένος κανόνας ⇒ ο διερμηνέας ταξινομεί χωρίς νέο κώδικα (+αναστροφή)"
           (let ((mem (make-instance 'orchestrator.cognition:working-memory)))
             (orchestrator.cognition:remember mem :last-answer "…δοκιμαστικό χωρίο (ΚΠολΔ άρθρο 280)…")
             (let* ((orchestrator.cognition:*current-memory* mem)
                    (*learned-rules*
                      '((:id "ur:test" :when (("question" . t) ("reference-marker" . t)
                                              ("has-last-answer" . t))
                         :frame :conversation-reference)))
                    (fr (orchestrator.cognition:decompose "τι εννοείς εκεί;")))
               (typep fr 'conversation-reference-frame))))
      ;; ── Π0 (live failure memory): A/B/C/D του δημιουργού ──
      (let* ((before (length (%raw-lines (%failure-ledger-path))))
             (out (with-output-to-string (*standard-output*)
                    (run-ask '("μπλα" "μπλα" "ακατανόητο" "12345"))))
             (fid (cl-ppcre:register-groups-bind (w)
                      ("failure_id: (fail:[0-9a-f]+)" out) w))
             (lines (%raw-lines (%failure-ledger-path)))
             (entry (and fid (find-if (lambda (l) (search fid l)) lines))))
        (chk "⑩ Π0-A: ζωντανό «δεν κατάλαβα» ⇒ failure_id στο envelope + εγγραφή ledger (open, live-dialogue)"
             (and fid entry (> (length lines) before)
                  (search "\"status\":\"open\"" entry)
                  (search "live-dialogue" entry)
                  (search "memory_recorded: true" out)))
        (let ((out2 (with-output-to-string (*standard-output*)
                      (run-ask '("δείξε" "μου" "τι" "κατέγραψες")))))
          (chk "⑪ Π0-B: «δείξε μου τι κατέγραψες» ⇒ ΠΛΗΡΕΣ record (id/input/mode/reason/gap/status)"
               (and fid (search fid out2)
                    (search "μπλα μπλα ακατανόητο 12345" out2)
                    (search "produced_mode" out2) (search "wrong_behavior" out2)
                    (search "created_gap" out2) (search "status" out2)))))
      (let ((before (length (%raw-lines (%failure-ledger-path)))))
        (with-output-to-string (*standard-output*) (run-ask '("ποιος" "είσαι;")))
        (chk "⑫ Π0-C: κατανοητή ερώτηση ⇒ ΚΑΜΙΑ νέα εγγραφή στον ledger"
             (= before (length (%raw-lines (%failure-ledger-path))))))
      (chk "⑬ Π0-D: %lesson (aggregate) και ledger ΞΕΧΩΡΙΣΤΑ — ένας writer ο καθένας, κανένα δεύτερο store"
           (and (fboundp '%lesson) (fboundp 'record-dialogue-failure!)
                (probe-file (%failure-ledger-path)))))
    (format t "~%── ΠΥΛΗ ΜΑΘΗΣΗΣ ΚΑΤΑΝΟΗΣΗΣ: ~D/~D πέρασαν ──~%"
            (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--understanding-gate"
  (lambda (a) (declare (ignore a)) (run-understanding-gate)))
