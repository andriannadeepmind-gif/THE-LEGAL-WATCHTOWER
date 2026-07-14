;;;; source/version-graph.lisp
;;;; ============================================================================
;;;; Ο ΔΙΤΕΜΠΟΡΙΚΟΣ ΓΡΑΦΟΣ ΕΚΔΟΣΕΩΝ — [0088] Temporal/Identity Φ2
;;;; ============================================================================
;;;;
;;;; Η ΜΙΑ έδρα νομικού χρόνου: αμετάβλητοι κόμβοι-κείμενα (text-version) με
;;;; πλήρες bitemporal [valid-from,valid-until) × [recorded-from,recorded-until),
;;;; τυποποιημένες πράξεις-ακμές (amendment-edge) με before/after δέσμευση, και
;;;; ΔΟΜΙΚΗ καραντίνα (quarantined-edge = ΑΛΛΟΣ ΤΥΠΟΣ, αόρατος στην επιλογή
;;;; έκδοσης — η κλάση TEMP-02 «NIL effective εφαρμόζεται σιωπηλά» ΕΞΑΛΕΙΦΕΤΑΙ,
;;;; δεν φρουρείται). Σχέδιο: deployment/LAWMAX-TEMPORAL-IDENTITY-DESIGN.md §1.2-1.3.
;;;;
;;;; Αμετάβλητοι invariants (στην έδρα, όχι στους callers):
;;;;  G1 admit-edge! = replay-then-append: ακμή δεκτή ΜΟΝΟ αν οι from-versions
;;;;     υπάρχουν/είναι ανοιχτές ΚΑΙ τα to-contents αναπαράγουν ακριβώς τα
;;;;     δηλωμένα to-hashes· αλλιώς καραντίνα :conflicted-before-hash.
;;;;  G2 ολική διάταξη εφαρμογής: (effective, fek-date, act-internal-seq, edge-id)
;;;;     — το NIL δεν υπάρχει στον τύπο, άρα δεν ταξινομείται.
;;;;  G3 append-only journal (η [0086] έδρα orchestrator.journal, sexp γραμμές
;;;;     με Persistence Receipt — ΟΧΙ νέο ιδίωμα αποθήκευσης) + αλυσίδα
;;;;     full-record (Κ2): payload-hash = sha256(κανονική σειριοποίηση ΟΛΟΥ
;;;;     του payload)· chain = sha256(prev-chain ‖ 0x1F ‖ payload-hash)·
;;;;     στο replay επανυπολογίζονται payload-hash + semantic record hash.
;;;;  G5 retract-knowledge!: ο ΜΟΝΑΔΙΚΟΣ τρόπος «διαγραφής» — κλείνει
;;;;     recorded-until με ΝΕΑ γραμμή· το journal δεν ξαναγράφεται ποτέ.
;;;;
;;;; ΔΗΛΩΜΕΝΑ ΟΡΙΑ Φ2 (πληρότητα φάσης, όχι σιωπηλά):
;;;;  - Interim TSA seals + RFC-6962 consistency ανά release cut (G6) δένουν
;;;;    στο release layer (Φ4) — εδώ υπάρχει το verify-chain (πλήρες replay).
;;;;  - :renumber/:split/:merge: πλήρης υποστήριξη στη Φ3 (import) — εδώ ο
;;;;    τύπος τα δηλώνει, το admit-edge! τα απορρίπτει ΡΗΤΑ ως :unsupported-op
;;;;    (τίμια άγνοια, όχι μισή σημασιολογία).
;;;;  - Το recorded-from προέρχεται από το journal receipt (πραγματικός χρόνος
;;;;    εγγραφής) — ΠΟΤΕ από την deterministic-time έδρα.

(defpackage :orchestrator.version-graph
  (:use :cl)
  (:export
   ;; τύποι/συνθήκες
   #:legal-date #:legal-date-p #:legal-instant #:legal-instant-p
   #:text-version #:text-version-p #:amendment-edge #:amendment-edge-p
   #:quarantined-edge #:quarantined-edge-p #:knowledge-gap #:knowledge-gap-p
   #:temporal-uncertainty #:unknown-provision #:invalid-edge #:journal-corruption
   ;; text-version αναγνώστες
   #:tv-version-hash #:tv-provision-id #:tv-text #:tv-heading
   #:tv-valid-from #:tv-valid-until #:tv-recorded-from #:tv-recorded-until
   #:tv-status #:tv-previous-version-hash #:tv-created-by #:tv-assurance
   ;; edge αναγνώστες
   #:ae-edge-id #:ae-op #:ae-target #:ae-effective #:ae-enacted
   #:qe-reason #:qe-edge
   ;; γράφος
   #:version-graph #:make-graph #:graph-body #:load-graph
   #:graph-versions-of #:graph-quarantine #:graph-gaps #:graph-edge-count
   #:submit-genesis! #:admit-edge! #:quarantine! #:retract-knowledge!
   #:add-knowledge-gap! #:kg-provision-id #:kg-effective #:kg-kind
   #:version-at #:snapshot-at #:verify-chain #:graph-chain-head
   #:make-edge-spec #:make-version-spec
   ;; [0088 Φ7 Π1] Formal Temporal Semantics — effectivity conditions
   #:make-effectivity-condition #:condition-id #:condition-ast #:condition-class
   #:valid-condition-ast-p #:instrument-kinds
   #:date+ #:sat
   #:invalid-condition))

(in-package :orchestrator.version-graph)

;;; ----------------------------------------------------------------------------
;;; Τύποι χρόνου — το NIL ΔΕΝ χωράει
;;; ----------------------------------------------------------------------------

(defun %leap-year-p (y)
  (and (zerop (mod y 4)) (or (plusp (mod y 100)) (zerop (mod y 400)))))

(defun %days-in-month (y m)
  (case m
    ((1 3 5 7 8 10 12) 31)
    ((4 6 9 11) 30)
    (2 (if (%leap-year-p y) 29 28))
    (t 0)))

(defun %digits-int (s start end)
  "Ακέραιος από ASCII ψηφία [START,END) — ΜΟΝΟ #\\0..#\\9. [0088 Φ5-κριτής Ε1]:
   το digit-char-p δεχόταν ΚΑΘΕ Unicode decimal (fullwidth ５, Arabic-Indic ٥),
   ανοίγοντας equivocation surface (ίδιο %time-key, διαφορετικό hash/bytes). Ο
   canonical-UTC τύπος πρέπει να είναι ASCII-only ΔΟΜΙΚΑ, για ΟΛΟΥΣ τους
   καλούντες (date/instant/time-key) ταυτόχρονα."
  (loop with n = 0
        for i from start below end
        for c = (char s i)
        do (unless (char<= #\0 c #\9) (return nil))
           (setf n (+ (* 10 n) (- (char-code c) 48)))
        finally (return n)))

(defun legal-date-p (x)
  "ISO ημερομηνία «YYYY-MM-DD» με ΠΡΑΓΜΑΤΙΚΟ γρηγοριανό έλεγχο (μήνας 1-12,
   ημέρα ≤ ημερών μήνα, δίσεκτα) — το «2026-99-99» ΔΕΝ είναι νομικός χρόνος."
  (and (stringp x) (= 10 (length x))
       (char= #\- (char x 4)) (char= #\- (char x 7))
       (let ((y (%digits-int x 0 4)) (m (%digits-int x 5 7)) (d (%digits-int x 8 10)))
         (and y m d (<= 1 m 12) (<= 1 d (%days-in-month y m))))))

(defun legal-instant-p (x)
  "ISO στιγμή «YYYY-MM-DDTHH:MM:SSZ» — CANONICAL UTC, υποχρεωτικό Z, γνήσιος
   γρηγοριανός + ωρολογιακός έλεγχος. Καμία λεξικογραφική «ημερομηνία» δεν
   περνιέται για στιγμή."
  (and (stringp x) (= 20 (length x))
       (char= #\T (char x 10)) (char= #\Z (char x 19))
       (char= #\: (char x 13)) (char= #\: (char x 16))
       (legal-date-p (subseq x 0 10))
       (let ((h (%digits-int x 11 13)) (mi (%digits-int x 14 16)) (s (%digits-int x 17 19)))
         (and h mi s (< h 24) (< mi 60) (< s 60)))))

(deftype legal-date () '(and string (satisfies legal-date-p)))
(deftype legal-instant () '(and string (satisfies legal-instant-p)))

(defun %time-key (x what)
  "Δομημένο κλειδί σύγκρισης χρόνου (integer) — ΟΧΙ σύγκριση συμβολοσειρών.
   Δέχεται legal-date (⇒ αρχή ημέρας) ή legal-instant· ΚΑΘΕ άλλη μορφή =
   typed σφάλμα. Παλαιό ζωνο-χωρίς 19-χαρακτήρων instant (προ-Υ1 journals)
   γίνεται δεκτό στην ΑΝΑΓΝΩΣΗ μόνο — νέες εγγραφές φέρουν πάντα Z."
  (cond
    ((legal-date-p x)
     (* (+ (* (%digits-int x 0 4) 10000) (* (%digits-int x 5 7) 100) (%digits-int x 8 10))
        1000000))
    ((or (legal-instant-p x)
         (and (stringp x) (= 19 (length x)) (char= #\T (char x 10))
              (legal-date-p (subseq x 0 10))))
     (+ (* (+ (* (%digits-int x 0 4) 10000) (* (%digits-int x 5 7) 100) (%digits-int x 8 10))
           1000000)
        (* (%digits-int x 11 13) 10000) (* (%digits-int x 14 16) 100) (%digits-int x 17 19)))
    (t (error 'invalid-edge
              :reason (format nil "~A δεν είναι legal-date/legal-instant: ~S" what x)))))

(defun %time<= (a b &optional (what-a "χρόνος") (what-b "χρόνος"))
  (<= (%time-key a what-a) (%time-key b what-b)))

(define-condition invalid-edge (error)
  ((reason :initarg :reason :reader invalid-edge-reason))
  (:report (lambda (c s) (format s "Άκυρη ακμή: ~A" (invalid-edge-reason c)))))

(define-condition journal-corruption (error)
  ;; [0088 Φ5-κριτής Ε2] ΞΕΧΩΡΙΣΤΟΣ τύπος από invalid-edge: η αλλοίωση/ρήξη
  ;; ΑΠΟΘΗΚΕΥΜΕΝΟΥ journal είναι server-integrity αποτυχία (⇒ 500), ΠΟΤΕ
  ;; client «άκυρη είσοδος» (⇒ 400). Η invalid-edge σημαίνει «κακό υποψήφιο
  ;; υλικό»· αυτή σημαίνει «η ίδια η καταγεγραμμένη αλήθεια πειράχτηκε».
  ((reason :initarg :reason :reader journal-corruption-reason))
  (:report (lambda (c s) (format s "ΔΙΕΦΘΑΡΜΕΝΟ journal: ~A" (journal-corruption-reason c)))))

(define-condition temporal-uncertainty (error)
  ((provision :initarg :provision :reader uncertainty-provision)
   (why :initarg :why :reader uncertainty-why))
  (:report (lambda (c s)
             (format s "Χρονική αβεβαιότητα για ~A: ~A — ΚΑΜΙΑ έμπιστη απάντηση"
                     (uncertainty-provision c) (uncertainty-why c)))))

(define-condition unknown-provision (error)
  ((provision :initarg :provision :reader unknown-provision-id))
  (:report (lambda (c s)
             (format s "Άγνωστη διάταξη στον γράφο: ~A" (unknown-provision-id c)))))

(defun %require-date (x what)
  (unless (legal-date-p x)
    (error 'invalid-edge :reason (format nil "~A δεν είναι legal-date: ~S (το NIL/άγνωστο ⇒ καραντίνα, όχι έμπιστη ακμή)" what x)))
  x)

;;; ----------------------------------------------------------------------------
;;; Δομές — αμετάβλητοι κόμβοι, typed ακμές, καραντίνα ΩΣ ΤΥΠΟΣ
;;; ----------------------------------------------------------------------------

(defstruct (text-version (:conc-name tv-))
  version-hash          ; sha256 canonical record (χωρίς recorded — event time εκτός ταυτότητας)
  provision-id          ; provision-id-string (orchestrator.identity)
  text heading
  valid-from            ; legal-date — ΥΠΟΧΡΕΩΤΙΚΟ
  valid-until           ; legal-date | :open   (κλείνει ΜΟΝΟ μέσω ακμής, journaled)
  recorded-from         ; journal receipt time — ΥΠΟΧΡΕΩΤΙΚΟ
  recorded-until        ; timestamp | :current (κλείνει ΜΟΝΟ μέσω retract, journaled)
  status                ; :in-force :repealed :not-yet-effective :suspended
  previous-version-hash ; sha256 | :genesis
  created-by            ; edge-id | (:base . derivation)
  assurance)            ; :verified :extracted-verified :attested-manual :reconstructed :legacy-unverifiable

(defparameter +edge-ops+
  '(:insert :delete :replace :replace-heading :renumber :split :merge
    :repeal :restore :correct :restate :retract-knowledge))

(defparameter +supported-ops+ '(:insert :replace :replace-heading :repeal :restore :correct :restate)
  "Οι πράξεις με ΠΛΗΡΗ σημασιολογία replay στη Φ2. Οι δομικές
   (:renumber/:split/:merge/:delete) αποκτούν replay στη Φ3 (import) —
   ως τότε admit-edge! ⇒ ΡΗΤΟ invalid-edge :unsupported-op, ποτέ μισή εφαρμογή.")

(defstruct (amendment-edge (:conc-name ae-))
  edge-id
  op                    ; ∈ +edge-ops+
  from-versions         ; λίστα version-hashes (κενή ΜΟΝΟ για :insert)
  to-versions           ; λίστα version-hashes
  target                ; provision-id-string
  act-ref               ; string — ταυτότητα πράξης (π.χ. "gr/psifisma/2019#fekA187")
  act-internal-seq      ; (άρθρο σειρά) ΜΕΣΑ στην πράξη — ΥΠΟΧΡΕΩΤΙΚΟ (tie-break G2)
  corrects-edge-id      ; μόνο για :correct
  source-span           ; plist (:artifact-digest :page :char-start :char-end) | NIL(δηλωμένο :missing-span)
  enacted effective     ; legal-date — ΥΠΟΧΡΕΩΤΙΚΑ ΣΤΟΝ ΤΥΠΟ
  fek-date              ; legal-date (για το G2 κλειδί)
  recorded-from recorded-until
  assurance confidence)

(defstruct (quarantined-edge (:conc-name qe-))
  edge                  ; το υποψήφιο υλικό (plist όπως υποβλήθηκε — ΔΕΝ έγινε amendment-edge)
  reason                ; :unknown-effective :unknown-text :conflicted-before-hash
                        ; :low-confidence :unresolved-target :unsupported-op
  recorded-from)

(defstruct (knowledge-gap (:conc-name kg-))
  provision-id act-ref kind effective recorded-from)

;;; ----------------------------------------------------------------------------
;;; Κανονικά hashes — ΜΟΝΟ μέσω της έδρας canonical serialization (Φ1β spec)
;;; ----------------------------------------------------------------------------

(defun %version-hash (provision-id text heading valid-from status previous)
  "Ταυτότητα περιεχομένου έκδοσης — ΧΩΡΙΣ recorded (bit-reproducible σύνολο)."
  (orchestrator.canonical-representation:canonical-hash
   (list (cons "heading" (or heading :null))
         (cons "previous_version_hash" (string-downcase (string previous)))
         (cons "provision_id" provision-id)
         (cons "status" (string-downcase (symbol-name status)))
         (cons "text" text)
         (cons "valid_from" valid-from))))

(defun %edge-hash (op target from to act-ref act-seq enacted effective fek-date span)
  (orchestrator.canonical-representation:canonical-hash
   (list (cons "act_ref" act-ref)
         (cons "act_seq" act-seq)
         (cons "effective" effective)
         (cons "enacted" enacted)
         (cons "fek_date" fek-date)
         (cons "from" from)
         (cons "op" (string-downcase (symbol-name op)))
         (cons "span" (or span :null))
         (cons "target" target)
         (cons "to" to))))

;;; ----------------------------------------------------------------------------
;;; Ο γράφος — προβολή στη μνήμη ΤΟΥ append-only journal (ποτέ ανάποδα)
;;; ----------------------------------------------------------------------------

(defstruct (version-graph (:conc-name vg-) (:constructor %make-graph))
  body                  ; body-id-string
  path                  ; journal pathname
  versions              ; version-hash → text-version (equal)
  by-provision          ; provision-id-string → λίστα version-hashes (σειρά εισαγωγής)
  edges                 ; edge-id → amendment-edge
  quarantine            ; λίστα quarantined-edge
  gaps                  ; λίστα knowledge-gap
  chain)                ; τρέχον chain-hash (κεφαλή αλυσίδας)

(defun %graph-path (body-string)
  (orchestrator.paths:institution-dir
   (format nil "deployment/data/version-graph/~A.vgraph.sexp"
           (substitute #\- #\/ body-string))))

(defun make-graph (body-string)
  (%make-graph :body body-string :path (%graph-path body-string)
               :versions (make-hash-table :test 'equal)
               :by-provision (make-hash-table :test 'equal)
               :edges (make-hash-table :test 'equal)
               :quarantine '() :gaps '() :chain "genesis"))

(defun %canon-sexp (x out)
  "Κανονική σειριοποίηση sexp ΤΙΜΩΝ — συνάρτηση της ΑΞΙΑΣ, ποτέ της
   αναπαράστασης (το prin1 τύπωνε non-simple strings ως #A(...) — η ταυτότητα
   δεν επιτρέπεται να εξαρτάται από το αν ένα string είναι simple array).
   Επιτρεπτό πεδίο = ό,τι επιτρέπει το sexp journal: NIL, keyword, string,
   integer, λίστα αυτών. Οτιδήποτε άλλο ⇒ ΣΦΑΛΜΑ (fail-closed — όχι σιωπηλή
   «κάπως» σειριοποίηση)."
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
     ;; [Ε3] χειρισμός ΚΑΙ improper lists (dotted pair): το `on` σκόνταφτε σε
     ;; endp πάνω σε atom (type-error αντί fail-closed etypecase). Κανένα
     ;; journaled payload δεν είναι dotted σήμερα, αλλά η ταυτότητα δεν
     ;; επιτρέπεται να έχει «σχεδόν σωστή» σειριοποίηση.
     (loop for tail = x then (cdr tail)
           while (consp tail)
           do (%canon-sexp (car tail) out)
              (cond ((consp (cdr tail)) (write-char #\Space out))
                    ((cdr tail) (write-string " . " out) (%canon-sexp (cdr tail) out))))
     (write-char #\) out))))

(defun %payload-hash (plist)
  "[0088 Φ5 Κ2] sha256 της ΚΑΝΟΝΙΚΗΣ σειριοποίησης ΟΛΟΚΛΗΡΟΥ του journal
   payload (κάθε πεδίο — text/status/effective/assurance/reason/at/…), ΟΧΙ
   μόνο του semantic record-id — μέσω του %canon-sexp (value-canonical).
   Το chain αλυσοδένει ΑΥΤΟ: αλλοίωση ΟΠΟΙΟΥΔΗΠΟΤΕ byte με αμετάβλητο
   record-id/chain ⇒ ρήξη στο replay."
  (orchestrator.journal:sha256-hex
   (with-output-to-string (out) (%canon-sexp plist out))))

(defun %strip-envelope (line)
  "Το payload μιας γραμμής = η γραμμή ΧΩΡΙΣ τα envelope πεδία (:chain,
   :payload-hash) — ό,τι ακριβώς hash-άρεται."
  (loop for (k v) on line by #'cddr
        unless (member k '(:chain :payload-hash))
          append (list k v)))

(defun %chain-next (prev payload-hash)
  (orchestrator.journal:sha256-hex
   (format nil "~A~C~A" prev (code-char 31) payload-hash)))

(defun %journal! (graph plist &key (verify t))
  "Μία γραμμή στο journal της έδρας [0086]: chained-append + require-durable!.
   Κάθε γραμμή φέρει :payload-hash (δέσμευση ΟΛΟΚΛΗΡΟΥ record — Κ2) και
   :chain = sha256(prev ‖ 0x1F ‖ payload-hash). Με VERIFY (προεπιλογή)
   γίνεται και read-back επαλήθευση ανά γραμμή· σε ΜΑΖΙΚΟ import η ανά-γραμμή
   επανανάγνωση είναι O(n²) — εκεί VERIFY NIL και η αλήθεια επαληθεύεται στο
   τέλος με ΠΛΗΡΕΣ replay (verify-chain, O(n))."
  (let* ((ph (%payload-hash plist))
         (next-chain (%chain-next (vg-chain graph) ph)))
    (multiple-value-bind (line receipt)
        (orchestrator.journal:chained-append
         (vg-path graph)
         (lambda (last)
           (declare (ignore last))
           (append plist (list :payload-hash ph :chain next-chain)))
         :verify verify)
      (orchestrator.journal:require-durable! receipt :version-graph)
      (setf (vg-chain graph) next-chain)
      line)))

(defun %recorded-of (line)
  "Το transaction-time μιας γραμμής = ΑΠΟΚΛΕΙΣΤΙΚΑ το αποθηκευμένο :at της.
   [Υ3]: κανένα σιωπηλό iso-now fallback — γραμμή χωρίς :at είναι διεφθαρμένη."
  (or (getf line :at)
      (error 'invalid-edge
             :reason (format nil "journal γραμμή χωρίς :at (record ~A) — διεφθαρμένο transaction-time"
                             (getf line :record-id)))))

;;; ── εσωτερική υλοποίηση εφαρμογής εγγραφών στην προβολή μνήμης ──

(defun %install-version (graph v)
  "Εγκατάσταση RECORD στην προβολή. Το by-provision κρατά ΟΛΑ τα records
   (και τα διτεμπορικά υπερκείμενα — supersession)· το versions δείχνει το
   ΤΡΕΧΟΝ record κάθε content-hash (για from-hash lookups)."
  (setf (gethash (tv-version-hash v) (vg-versions graph)) v)
  (push v (gethash (tv-provision-id v) (vg-by-provision graph))))

(defun %open-version (graph pid)
  "Η ανοιχτή (valid-until :open, recorded-until :current) έκδοση του PID, ή NIL."
  (loop for v in (gethash pid (vg-by-provision graph))
        when (and (eq :open (tv-valid-until v)) (eq :current (tv-recorded-until v)))
          return v))

(defun %supersede-validity (graph v new-valid-until at)
  "ΔΙΤΕΜΠΟΡΙΚΗ υπερκατάσταση — ποτέ μετάλλαξη γνώσης: το record «v ισχύει
   :open» παύει να είναι η τρέχουσα γνώση (recorded-until=AT) και ΝΕΟ record
   ίδιου content-hash με valid-until=NEW-VALID-UNTIL γίνεται η τρέχουσα.
   Έτσι το «τι ήξερε το σύστημα πριν το AT» μένει ΑΘΙΚΤΟ (as-known αλήθεια)."
  (setf (tv-recorded-until v) at)
  (let ((v2 (copy-text-version v)))
    (setf (tv-valid-until v2) new-valid-until
          (tv-recorded-from v2) at
          (tv-recorded-until v2) :current)
    (%install-version graph v2)
    v2))

;;; ----------------------------------------------------------------------------
;;; Δημόσιες πράξεις — ΟΛΕΣ journal-first
;;; ----------------------------------------------------------------------------

(defun make-version-spec (&key provision-id text heading valid-from
                               (status :in-force) (previous :genesis) assurance)
  "Υποψήφιο περιεχόμενο έκδοσης (πριν την εισδοχή). Fail-closed στον χρόνο."
  (%require-date valid-from "valid-from")
  (unless (and (stringp provision-id) (stringp text))
    (error 'invalid-edge :reason "provision-id/text μη-string"))
  (unless (member assurance '(:verified :extracted-verified :attested-manual
                              :reconstructed :legacy-unverifiable))
    (error 'invalid-edge :reason (format nil "άγνωστο assurance ~S" assurance)))
  (list :provision-id provision-id :text text :heading heading
        :valid-from valid-from :status status :previous previous
        :assurance assurance))

(defun make-edge-spec (&key op target from-versions to-specs act-ref
                            act-internal-seq corrects-edge-id source-span
                            enacted effective fek-date
                            (assurance :extracted-verified) (confidence 1))
  "Υποψήφια ακμή. Ο ΤΥΠΟΣ απαιτεί enacted/effective/fek-date ως legal-date —
   υποψήφιο με άγνωστη ισχύ ΔΕΝ κατασκευάζεται καν: πήγαινε στο quarantine!."
  (unless (member op +edge-ops+)
    (error 'invalid-edge :reason (format nil "άγνωστη πράξη ~S" op)))
  (%require-date enacted "enacted") (%require-date effective "effective")
  (%require-date fek-date "fek-date")
  (unless (and (consp act-internal-seq) (= 2 (length act-internal-seq))
               (every #'integerp act-internal-seq))
    (error 'invalid-edge :reason "act-internal-seq: απαιτείται (άρθρο σειρά) — tie-break G2"))
  (when (and (eq op :correct) (not (stringp corrects-edge-id)))
    (error 'invalid-edge :reason ":correct χωρίς corrects-edge-id"))
  (list :op op :target target :from-versions from-versions :to-specs to-specs
        :act-ref act-ref :act-internal-seq act-internal-seq
        :corrects-edge-id corrects-edge-id :source-span source-span
        :enacted enacted :effective effective :fek-date fek-date
        :assurance assurance :confidence confidence))

(defun add-knowledge-gap! (graph &key provision-id act-ref kind effective)
  "ΤΙΜΙΑ ΑΓΝΟΙΑ πρώτης τάξης: δηλωμένο κενό ανακατασκευής (π.χ. text-less
   αναθεώρηση) — journaled, ορατό σε κάθε ερώτημα που πέφτει στο κενό."
  (%require-date effective "effective (κενού γνώσης)")
  (let* ((rid (format nil "gap:~A@~A:~A" provision-id effective (or act-ref "")))
         (line (%journal! graph (list :kind :knowledge-gap :record-id rid
                                      :provision-id provision-id :act-ref act-ref
                                      :gap-kind kind :effective effective
                                      :at (orchestrator.journal:iso-now))
                          :verify nil))
         (g (make-knowledge-gap :provision-id provision-id :act-ref act-ref
                                :kind kind :effective effective
                                :recorded-from (%recorded-of line))))
    (push g (vg-gaps graph))
    g))

(defun submit-genesis! (graph vspec &key derivation)
  "Εισδοχή έκδοσης-γένεσης (bootstrap/import) — δεν προέρχεται από ακμή.
   Ο έλεγχος σύγκρουσης (G4) προηγείται ΚΑΘΕ εγγραφής — κανένα ορφανό record."
  (when (%open-version graph (getf vspec :provision-id))
    (error 'invalid-edge :reason (format nil "genesis σε διάταξη με ΑΝΟΙΧΤΗ έκδοση: ~A (σύγκρουση ταυτότητας — G4)" (getf vspec :provision-id))))
  (let* ((vh (%version-hash (getf vspec :provision-id) (getf vspec :text)
                            (getf vspec :heading) (getf vspec :valid-from)
                            (getf vspec :status) :genesis))
         (line (%journal! graph
                          (list :kind :text-version :record-id vh
                                :provision-id (getf vspec :provision-id)
                                :text (getf vspec :text)
                                :heading (getf vspec :heading)
                                :valid-from (getf vspec :valid-from)
                                :status (getf vspec :status)
                                :previous "genesis"
                                :created-by (or derivation "bootstrap")
                                :assurance (getf vspec :assurance)
                                :at (orchestrator.journal:iso-now))
                          :verify nil))
         (v (make-text-version
             :version-hash vh :provision-id (getf vspec :provision-id)
             :text (getf vspec :text) :heading (getf vspec :heading)
             :valid-from (getf vspec :valid-from) :valid-until :open
             :recorded-from (%recorded-of line) :recorded-until :current
             :status (getf vspec :status) :previous-version-hash :genesis
             :created-by (or derivation "bootstrap")
             :assurance (getf vspec :assurance))))
    (%install-version graph v)
    v))

(defun quarantine! (graph material reason)
  "Ρητή καραντίνα — ΤΥΠΟΣ αόρατος στην επιλογή έκδοσης, ΟΡΑΤΟΣ στο audit."
  (unless (member reason '(:unknown-effective :unknown-text :conflicted-before-hash
                           :low-confidence :unresolved-target :unsupported-op))
    (error 'invalid-edge :reason (format nil "άγνωστος λόγος καραντίνας ~S" reason)))
  (let* ((rid (orchestrator.journal:sha256-hex (format nil "~S" material)))
         (line (%journal! graph (list :kind :quarantined :record-id rid
                                      :reason reason :material material
                                      :at (orchestrator.journal:iso-now))))
         (q (make-quarantined-edge :edge material :reason reason
                                   :recorded-from (%recorded-of line))))
    (push q (vg-quarantine graph))
    q))

(defun admit-edge! (graph espec)
  "G1: replay-then-append. Επιστρέφει (values amendment-edge νέες-εκδόσεις) ή
   (values NIL quarantined-edge) όταν το replay διαψεύδει το υλικό. ΠΟΤΕ μισή
   εφαρμογή, ΠΟΤΕ σιωπηλή αποδοχή."
  (let ((op (getf espec :op))
        (target (getf espec :target)))
    (unless (member op +supported-ops+)
      (return-from admit-edge!
        (values nil (quarantine! graph espec :unsupported-op))))
    (let* ((cur (%open-version graph target))
           (from (getf espec :from-versions)))
      ;; προϋποθέσεις ανά πράξη — αποτυχία = καραντίνα με ΛΟΓΟ, όχι error
      (cond
        ((eq op :insert)
         (when cur (return-from admit-edge!
                     (values nil (quarantine! graph espec :conflicted-before-hash))))
         (when from (return-from admit-edge!
                      (values nil (quarantine! graph espec :conflicted-before-hash)))))
        (t
         (unless cur (return-from admit-edge!
                       (values nil (quarantine! graph espec :unresolved-target))))
         (unless (and (= 1 (length from))
                      (equal (first from) (tv-version-hash cur)))
           (return-from admit-edge!
             (values nil (quarantine! graph espec :conflicted-before-hash))))))
      ;; replay: τα to-specs αναπαράγουν ΑΚΡΙΒΩΣ τις δηλωμένες νέες εκδόσεις
      (let* ((prev-hash (if cur (tv-version-hash cur) :genesis))
             (tos (loop for vs in (getf espec :to-specs)
                        collect (list vs (%version-hash
                                          (getf vs :provision-id) (getf vs :text)
                                          (getf vs :heading) (getf vs :valid-from)
                                          (getf vs :status) prev-hash))))
             (to-hashes (mapcar #'second tos))
             (eid (%edge-hash op target from to-hashes
                              (getf espec :act-ref) (getf espec :act-internal-seq)
                              (getf espec :enacted) (getf espec :effective)
                              (getf espec :fek-date) (getf espec :source-span))))
        ;; συνέπεια πράξης↔περιεχομένου
        (when (and (member op '(:replace :correct :restate)) (/= 1 (length tos)))
          (return-from admit-edge!
            (values nil (quarantine! graph espec :unknown-text))))
        (when (and (eq op :replace-heading) cur
                   (not (equal (getf (first (getf espec :to-specs)) :text) (tv-text cur))))
          (return-from admit-edge!
            (values nil (quarantine! graph espec :conflicted-before-hash))))
        (when (and (eq op :repeal)
                   (not (eq :repealed (getf (first (getf espec :to-specs)) :status))))
          (return-from admit-edge!
            (values nil (quarantine! graph espec :unknown-text))))
        ;; journal: η ακμή + οι νέες εκδόσεις + το κλείσιμο της προηγούμενης.
        ;; [Υ3 replay identity]: το in-memory recorded-from = ΑΚΡΙΒΩΣ το :at
        ;; της γραμμής που γράφτηκε — ΠΟΤΕ δεύτερο iso-now μετά την εγγραφή
        ;; (live ≠ replayed έστω κατά 1s είναι απαράδεκτο σε bitemporal έδρα).
        (let* ((edge-line (%journal! graph
                                     (list :kind :amendment-edge :record-id eid
                                           :op op :target target
                                           :from from :to to-hashes
                                           :act-ref (getf espec :act-ref)
                                           :act-seq (getf espec :act-internal-seq)
                                           :corrects (getf espec :corrects-edge-id)
                                           :span (getf espec :source-span)
                                           :enacted (getf espec :enacted)
                                           :effective (getf espec :effective)
                                           :fek-date (getf espec :fek-date)
                                           :assurance (getf espec :assurance)
                                           :confidence (getf espec :confidence)
                                           :at (orchestrator.journal:iso-now))))
               (edge (make-amendment-edge
                      :edge-id eid :op op :from-versions from :to-versions to-hashes
                      :target target :act-ref (getf espec :act-ref)
                      :act-internal-seq (getf espec :act-internal-seq)
                      :corrects-edge-id (getf espec :corrects-edge-id)
                      :source-span (getf espec :source-span)
                      :enacted (getf espec :enacted) :effective (getf espec :effective)
                      :fek-date (getf espec :fek-date)
                      :recorded-from (%recorded-of edge-line)
                      :recorded-until :current
                      :assurance (getf espec :assurance)
                      :confidence (getf espec :confidence)))
               (new-versions '()))
          (setf (gethash eid (vg-edges graph)) edge)
          ;; κλείσιμο ισχύος προηγούμενης — ΔΙΤΕΜΠΟΡΙΚΗ supersession (journaled):
          ;; η παλιά πεποίθηση «:open» παραμένει ορατή σε as-known ερωτήματα
          (when cur
            (let ((at (orchestrator.journal:iso-now)))
              (%journal! graph (list :kind :close-validity
                                     :record-id (format nil "close:~A@~A" (tv-version-hash cur) eid)
                                     :version (tv-version-hash cur)
                                     :valid-until (getf espec :effective)
                                     :edge eid :at at))
              (%supersede-validity graph cur (getf espec :effective) at)))
          (dolist (pair tos)
            (destructuring-bind (vs vh) pair
              (let* ((line (%journal! graph
                                      (list :kind :text-version :record-id vh
                                            :provision-id (getf vs :provision-id)
                                            :text (getf vs :text)
                                            :heading (getf vs :heading)
                                            :valid-from (getf vs :valid-from)
                                            :status (getf vs :status)
                                            :previous (string-downcase (string prev-hash))
                                            :created-by eid
                                            :assurance (getf vs :assurance)
                                            :at (orchestrator.journal:iso-now))))
                     (v (make-text-version
                         :version-hash vh :provision-id (getf vs :provision-id)
                         :text (getf vs :text) :heading (getf vs :heading)
                         :valid-from (getf vs :valid-from) :valid-until :open
                         :recorded-from (%recorded-of line) :recorded-until :current
                         :status (getf vs :status) :previous-version-hash prev-hash
                         :created-by eid :assurance (getf vs :assurance))))
                (%install-version graph v)
                (push v new-versions))))
          (values edge (nreverse new-versions)))))))

(defun retract-knowledge! (graph version-hash &key reason)
  "G5: κλείνει recorded-until της έκδοσης — ΝΕΑ γραμμή, καμία επανεγγραφή."
  (let ((v (gethash version-hash (vg-versions graph))))
    (unless v (error 'unknown-provision :provision version-hash))
    (let ((now (orchestrator.journal:iso-now)))
      (%journal! graph (list :kind :retract :record-id (format nil "retract:~A" version-hash)
                             :version version-hash :reason (or reason "unspecified")
                             :at now))
      (setf (tv-recorded-until v) now)
      v)))

;;; ----------------------------------------------------------------------------
;;; Διτεμπορικά ερωτήματα — το recorded ΣΥΜΜΕΤΕΧΕΙ στην επιλογή (TEMP-03 νεκρό)
;;; ----------------------------------------------------------------------------

(defun %recorded-live-p (v known-at)
  (and (%time<= (tv-recorded-from v) known-at "recorded-from" "known-at")
       (or (eq :current (tv-recorded-until v))
           (not (%time<= (tv-recorded-until v) known-at "recorded-until" "known-at")))))

(defun %valid-covers-p (v valid-at)
  (and (%time<= (tv-valid-from v) valid-at "valid-from" "valid-at")
       (or (eq :open (tv-valid-until v))
           (not (%time<= (tv-valid-until v) valid-at "valid-until" "valid-at")))))

(defun %known-by-p (recorded-from known-at)
  "T όταν κάτι με RECORDED-FROM ήταν ήδη ΓΝΩΣΤΟ κατά KNOWN-AT — η
   transaction-time πύλη για καραντίνες/κενά (Υ2): μελλοντική καταγραφή δεν
   δηλητηριάζει παλαιότερο epistemic snapshot."
  (%time<= recorded-from known-at "recorded-from" "known-at"))

(defun version-at (graph pid &key valid-at known-at)
  "Η έκδοση του PID που (α) ήταν ΓΝΩΣΤΗ στο σύστημα κατά KNOWN-AT και
   (β) ΙΣΧΥΕ κατά VALID-AT. ΚΑΙ ΤΑ ΔΥΟ ΥΠΟΧΡΕΩΤΙΚΑ ΚΑΙ TYPED: valid-at =
   legal-date, known-at = legal-instant (canonical UTC) — καμία λεξικογραφική
   σύγκριση, καμία άκυρη ημερολογιακά τιμή. Καραντίνα/κενό γνώσης επηρεάζει
   ΜΟΝΟ αν ήταν ήδη καταγεγραμμένο κατά KNOWN-AT (διτεμπορική σημασιολογία
   Υ2)· άγνωστη διάταξη ⇒ unknown-provision.
   ΔΗΛΩΜΕΝΟ ΥΠΟΛΟΙΠΟ (Υ2β): τα knowledge-gaps δεν φέρουν ακόμη άνω όριο
   valid-διαστήματος — κενό γνωστό κατά known-at καλύπτει ΟΛΗ την ακάλυπτη
   valid περίοδο της διάταξης (υπερ-προσεκτικό: αβεβαιότητα, ποτέ ψευδής
   βεβαιότητα ή ψευδής ανυπαρξία)."
  (%require-date valid-at "valid-at")
  (unless (legal-instant-p known-at)
    (error 'invalid-edge
           :reason (format nil "known-at δεν είναι legal-instant (YYYY-MM-DDTHH:MM:SSZ): ~S" known-at)))
  (let ((records (gethash pid (vg-by-provision graph))))
    (unless records (error 'unknown-provision :provision pid))
    ;; ΚΑΡΑΝΤΙΝΑ που στοχεύει τη διάταξη ΚΑΙ ήταν γνωστή κατά known-at = ΜΗ
    ;; εφαρμοσμένη γνωστή αλλαγή ⇒ το κείμενο της τομής αναξιόπιστο. Καραντίνα
    ;; καταγεγραμμένη ΜΕΤΑ το known-at δεν υπήρχε σε εκείνο το snapshot γνώσης.
    (let ((q (find-if (lambda (q)
                        (and (equal pid (getf (qe-edge q) :target))
                             (%known-by-p (qe-recorded-from q) known-at)))
                      (vg-quarantine graph))))
      (when q
        (error 'temporal-uncertainty :provision pid
               :why (format nil "ακμή σε καραντίνα (~A, καταγεγραμμένη ~A)"
                            (qe-reason q) (qe-recorded-from q)))))
    (let ((live (loop for v in records
                      when (and (%recorded-live-p v known-at)
                                (%valid-covers-p v valid-at))
                        collect v)))
      (cond
        ((= 1 (length live)) (values (first live) :complete))
        ((null live)
         ;; ΚΕΝΟ ΓΝΩΣΗΣ (text-less ιστορικό): μετρά ΜΟΝΟ αν ήταν ήδη
         ;; καταγεγραμμένο κατά known-at (Υ2) — αλλιώς το snapshot εκείνης της
         ;; γνώσης απλώς δεν είχε καμία έκδοση (:no-version-in-force, τίμιο).
         (let ((g (find-if (lambda (g)
                             (and (equal pid (kg-provision-id g))
                                  (%known-by-p (kg-recorded-from g) known-at)))
                           (vg-gaps graph))))
           (if g
               (error 'temporal-uncertainty :provision pid
                      :why (format nil "δηλωμένο κενό γνώσης (~A ~A, καταγεγραμμένο ~A): το κείμενο της περιόδου δεν ανακατασκευάζεται από τις διαθέσιμες πηγές"
                                   (kg-kind g) (kg-effective g) (kg-recorded-from g)))
               (values nil :no-version-in-force))))
        (t (error 'temporal-uncertainty :provision pid
                  :why (format nil "~D επικαλυπτόμενες εκδόσεις στην τομή — ασυνεπής γράφος" (length live))))))))

(defun snapshot-at (graph &key valid-at known-at)
  "Ολόκληρο το σώμα στην τομή (valid-at, known-at): alist pid→text-version,
   με ΡΗΤΗ λίστα quarantined/gaps (ποτέ σιωπηλά απόντα)."
  (let ((out '()) (uncertain '()))
    (maphash (lambda (pid hashes)
               (declare (ignore hashes))
               (handler-case
                   (multiple-value-bind (v basis) (version-at graph pid :valid-at valid-at :known-at known-at)
                     (declare (ignore basis))
                     (when v (push (cons pid v) out)))
                 (temporal-uncertainty (e)
                   (push (cons pid (uncertainty-why e)) uncertain))))
             (vg-by-provision graph))
    (values (sort out #'string< :key #'car)
            (sort uncertain #'string< :key #'car)
            (mapcar (lambda (q) (list (qe-reason q) (getf (qe-edge q) :target)))
                    (vg-quarantine graph)))))

;;; ----------------------------------------------------------------------------
;;; Φόρτωση/επαλήθευση από το journal — το αρχείο ΕΙΝΑΙ η αλήθεια
;;; ----------------------------------------------------------------------------

(defun load-graph (body-string)
  "Ανακατασκευή της προβολής μνήμης με ΠΛΗΡΕΣ replay του journal + επαλήθευση
   ΚΑΘΕ γραμμής σε ΔΥΟ επίπεδα (Κ2 full-record integrity):
     ① payload-hash: επανυπολογισμός από την κανονική σειριοποίηση ΟΛΟΚΛΗΡΟΥ
        του payload (κάθε πεδίο) ≡ αποθηκευμένο :payload-hash — αλλοίωση
        ΟΠΟΙΟΥΔΗΠΟΤΕ πεδίου με αμετάβλητο record-id ΣΠΑΕΙ εδώ·
     ② chain: sha256(prev ‖ 0x1F ‖ payload-hash) ≡ αποθηκευμένο :chain.
   Γραμμή χωρίς :payload-hash = παλαιό σχήμα (προ-Κ2) ⇒ journal-corruption με
   οδηγία (τα journals είναι runtime κατασκευάσματα: διαγραφή + reimport).
   ΚΑΘΕ ρήξη ⇒ journal-corruption (server-integrity, ΟΧΙ invalid-edge/client)."
  (let ((graph (make-graph body-string)))
    (dolist (line (orchestrator.journal:read-lines (vg-path graph)))
      (let* ((rid (getf line :record-id))
             (stored-ph (getf line :payload-hash))
             (ph (%payload-hash (%strip-envelope line)))
             (expect (%chain-next (vg-chain graph) ph)))
        (unless stored-ph
          (error 'journal-corruption
                 :reason (format nil "γραμμή ~A χωρίς :payload-hash — παλαιό σχήμα journal (προ-Κ2): διέγραψε το ~A και ξανακάνε import"
                                 rid (vg-path graph))))
        (unless (equal ph stored-ph)
          (error 'journal-corruption
                 :reason (format nil "ΑΛΛΟΙΩΣΗ PAYLOAD στο ~A: recomputed ~A ≠ αποθηκευμένο ~A — κάποιο πεδίο του record πειράχτηκε"
                                 rid ph stored-ph)))
        (unless (equal expect (getf line :chain))
          (error 'journal-corruption
                 :reason (format nil "σπασμένη αλυσίδα στο ~A: περίμενα ~A βρήκα ~A"
                                 rid expect (getf line :chain))))
        (setf (vg-chain graph) expect)
        ;; ③ semantic record hash ανά kind: το record-id ΞΑΝΑΒΓΑΙΝΕΙ από τα
        ;; πεδία — relabeling/πλαστό id αδύνατο ακόμη κι αν το payload-hash
        ;; ξαναγραφόταν συνεπές.
        (case (getf line :kind)
          (:text-version
           (let ((semantic (%version-hash (getf line :provision-id) (getf line :text)
                                          (getf line :heading) (getf line :valid-from)
                                          (getf line :status)
                                          (if (equal (getf line :previous) "genesis")
                                              :genesis (getf line :previous)))))
             (unless (equal semantic rid)
               (error 'journal-corruption
                      :reason (format nil "text-version ~A: semantic hash ~A ≠ record-id — πλαστή ταυτότητα έκδοσης" rid semantic))))
           (%install-version graph
                             (make-text-version
                              :version-hash rid
                              :provision-id (getf line :provision-id)
                              :text (getf line :text) :heading (getf line :heading)
                              :valid-from (getf line :valid-from) :valid-until :open
                              :recorded-from (%recorded-of line) :recorded-until :current
                              :status (getf line :status)
                              :previous-version-hash (if (equal (getf line :previous) "genesis")
                                                         :genesis (getf line :previous))
                              :created-by (getf line :created-by)
                              :assurance (getf line :assurance))))
          (:amendment-edge
           (let ((semantic (%edge-hash (getf line :op) (getf line :target)
                                       (getf line :from) (getf line :to)
                                       (getf line :act-ref) (getf line :act-seq)
                                       (getf line :enacted) (getf line :effective)
                                       (getf line :fek-date) (getf line :span))))
             (unless (equal semantic rid)
               (error 'journal-corruption
                      :reason (format nil "amendment-edge ~A: semantic hash ~A ≠ record-id — πλαστή ταυτότητα ακμής" rid semantic))))
           (setf (gethash rid (vg-edges graph))
                 (make-amendment-edge
                  :edge-id rid :op (getf line :op) :target (getf line :target)
                  :from-versions (getf line :from) :to-versions (getf line :to)
                  :act-ref (getf line :act-ref) :act-internal-seq (getf line :act-seq)
                  :corrects-edge-id (getf line :corrects)
                  :source-span (getf line :span)
                  :enacted (getf line :enacted) :effective (getf line :effective)
                  :fek-date (getf line :fek-date)
                  :recorded-from (%recorded-of line) :recorded-until :current
                  :assurance (getf line :assurance) :confidence (getf line :confidence))))
          (:close-validity
           (let ((v (gethash (getf line :version) (vg-versions graph))))
             (when v (%supersede-validity graph v (getf line :valid-until)
                                          (%recorded-of line)))))
          (:quarantined
           (push (make-quarantined-edge :edge (getf line :material)
                                        :reason (getf line :reason)
                                        :recorded-from (%recorded-of line))
                 (vg-quarantine graph)))
          (:knowledge-gap
           (push (make-knowledge-gap :provision-id (getf line :provision-id)
                                     :act-ref (getf line :act-ref)
                                     :kind (getf line :gap-kind)
                                     :effective (getf line :effective)
                                     :recorded-from (%recorded-of line))
                 (vg-gaps graph)))
          (:retract
           (let ((v (gethash (getf line :version) (vg-versions graph))))
             (when v (setf (tv-recorded-until v) (%recorded-of line)))))
          (t (error 'journal-corruption
                    :reason (format nil "άγνωστο :kind ~S στη γραμμή ~A — διεφθαρμένο/μελλοντικό σχήμα"
                                    (getf line :kind) rid))))))
    graph))

(defun verify-chain (body-string)
  "Ανεξάρτητη επαλήθευση: πλήρες replay από τον δίσκο. (values T κεφαλή πλήθος)
   ή σφάλμα με το ΑΚΡΙΒΕΣ σημείο ρήξης."
  (let ((g (load-graph body-string)))
    (values t (vg-chain g)
            (length (orchestrator.journal:read-lines (vg-path g))))))

(defun graph-chain-head (graph)
  "Η κεφαλή της chain-hash αλυσίδας του journal — η δεσμευτική ρίζα ΟΛΗΣ της
   καταγεγραμμένης ιστορίας του γράφου (κάθε record αλυσοδεμένο sha256)."
  (vg-chain graph))

;;; βοηθητικά για tests/επιθεώρηση
(defun graph-versions-of (graph pid)
  "ΟΛΑ τα records του PID (μαζί με τα διτεμπορικά υπερκείμενα)."
  (gethash pid (vg-by-provision graph)))
(defun graph-quarantine (graph) (vg-quarantine graph))
(defun graph-gaps (graph) (vg-gaps graph))
(defun graph-edge-count (graph) (hash-table-count (vg-edges graph)))
(defun graph-body (graph) (vg-body graph))

;;; ============================================================================
;;; [0088 Φ7 Π1] FORMAL TEMPORAL SEMANTICS — effectivity-condition πυρήνας
;;; Spec: deployment/LAWMAX-TEMPORAL-SEMANTICS-SPEC.md (v2, εγκεκριμένο).
;;; ΜΟΝΟΤΟΝΗ γραμματική (χωρίς :not/:unless — κλάση :suspensive/:resolutory
;;; στη ΔΗΛΩΣΗ)· denotational sat = ΟΛΙΚΗ συνάρτηση· date+ κατά ΑΚ 241-243.
;;; ============================================================================

(define-condition invalid-condition (error)
  ((reason :initarg :reason :reader invalid-condition-reason))
  (:report (lambda (c s) (format s "Άκυρο effectivity condition: ~A"
                                 (invalid-condition-reason c)))))

(defun %instrument-registry-path ()
  (orchestrator.paths:institution-dir "deployment/data/instrument-kind-registry.sexp"))

(let ((cache nil))
  (defun instrument-kinds ()
    "Το ΚΛΕΙΣΤΟ μητρώο ειδών θεσμικών γεγονότων — δηλωτικά δεδομένα από το
     deployment/data/instrument-kind-registry.sexp. Απόν/άκυρο ⇒ ΣΦΑΛΜΑ."
    (or cache
        (setf cache
              (let ((plist (with-open-file (s (%instrument-registry-path)
                                              :external-format :utf-8)
                             (let ((*package* (find-package :keyword)))
                               (read s)))))
                (unless (eq (getf plist :schema) :instrument-kind-registry/1)
                  (error 'invalid-condition
                         :reason "μητρώο instrument-kinds: άγνωστο schema"))
                (or (getf plist :kinds)
                    (error 'invalid-condition
                           :reason "μητρώο instrument-kinds: κενό")))))))

(defun valid-condition-ast-p (ast)
  "T ή σφάλμα invalid-condition με ΛΟΓΟ — ποτέ σιωπηλό NIL για άκυρη μορφή.
   Γραμματική v2: date-reached | instrument-event | after | and | or."
  (unless (consp ast)
    (error 'invalid-condition :reason (format nil "μη-λίστα κόμβος: ~S" ast)))
  (ecase (first ast)
    (:date-reached
     (unless (and (= 2 (length ast)) (legal-date-p (second ast)))
       (error 'invalid-condition
              :reason (format nil ":date-reached απαιτεί ΜΙΑ legal-date: ~S" ast))))
    (:instrument-event
     (unless (and (= 3 (length ast))
                  (member (second ast) (instrument-kinds))
                  (stringp (third ast)) (plusp (length (third ast))))
       (error 'invalid-condition
              :reason (format nil ":instrument-event απαιτεί (KIND∈μητρώο REF-string): ~S" ast))))
    (:after
     (unless (and (= 3 (length ast))
                  (consp (second ast))
                  (member (first (second ast)) '(:days :months :years))
                  (integerp (second (second ast)))
                  (plusp (second (second ast))))
       (error 'invalid-condition
              :reason (format nil ":after απαιτεί ((:days|:months|:years N>0) condition): ~S" ast)))
     (valid-condition-ast-p (third ast)))
    ((:and :or)
     (unless (>= (length (rest ast)) 2)
       (error 'invalid-condition
              :reason (format nil "~S απαιτεί ≥2 υπο-conditions" (first ast))))
     (mapc #'valid-condition-ast-p (rest ast))))
  t)

(defstruct (effectivity-condition (:conc-name condition-)
                                  (:constructor %make-condition))
  id     ; sha256 του value-canonical (class . AST) — η ταυτότητα
  class  ; :suspensive | :resolutory
  ast)

(defun make-effectivity-condition (class ast)
  "Typed effectivity condition. CLASS: :suspensive (η ισχύς ΑΡΧΙΖΕΙ στην
   ικανοποίηση) | :resolutory (η ισχύς ΠΑΥΕΙ στην ικανοποίηση — π.χ. ΠΝΠ μη
   κυρωθείσα, 44§1 Σ). Το AST επικυρώνεται ΠΛΗΡΩΣ στην κατασκευή· η ταυτότητα
   = hash του value-canonical (class . AST) — ίδιο condition ⇒ ίδιο id."
  (unless (member class '(:suspensive :resolutory))
    (error 'invalid-condition :reason (format nil "άγνωστη κλάση αίρεσης ~S" class)))
  (valid-condition-ast-p ast)
  (%make-condition
   :id (orchestrator.journal:sha256-hex
        (with-output-to-string (out) (%canon-sexp (cons class ast) out)))
   :class class :ast ast))

;;; ── date+ : Η ΜΙΑ ολική συνάρτηση ελληνικής προθεσμίας (ΑΚ 241-243) ──

(defun date+ (iso-date duration)
  "Η legal-date DURATION μετά την ISO-DATE, κατά ΑΚ 241-243:
   • :days — η προθεσμία λήγει με την παρέλευση N ημερών (η ημέρα έναρξης
     ΔΕΝ προσμετράται ⇒ ημερολογιακά: date + N)·
   • :months/:years — λήγει την ΑΝΤΙΣΤΟΙΧΗ ημερομηνία· ελλείψει αυτής
     (31/1+1μ), την ΤΕΛΕΥΤΑΙΑ ημέρα του μήνα (28-29/2, με δίσεκτα).
   Ολική & καθαρή: legal-date × DURATION → legal-date, αλλιώς typed σφάλμα.
   ΔΗΛΩΜΕΝΟ ΟΡΙΟ (spec §1.2): χωρίς κανόνα αργιών — αφορά έναρξη ισχύος."
  (unless (legal-date-p iso-date)
    (error 'invalid-condition :reason (format nil "date+: μη legal-date ~S" iso-date)))
  (unless (and (consp duration) (member (first duration) '(:days :months :years))
               (integerp (second duration)) (plusp (second duration)))
    (error 'invalid-condition :reason (format nil "date+: άκυρο duration ~S" duration)))
  (let ((y (%digits-int iso-date 0 4))
        (m (%digits-int iso-date 5 7))
        (d (%digits-int iso-date 8 10))
        (n (second duration)))
    (ecase (first duration)
      (:days
       (multiple-value-bind (sec min hr dd mm yy)
           (decode-universal-time
            (+ (encode-universal-time 0 0 12 d m y 0) (* n 86400)) 0)
         (declare (ignore sec min hr))
         (format nil "~4,'0D-~2,'0D-~2,'0D" yy mm dd)))
      ((:months :years)
       (let* ((total-months (+ (* y 12) (1- m)
                               (if (eq (first duration) :months) n (* 12 n))))
              (yy (floor total-months 12))
              (mm (1+ (mod total-months 12)))
              (dd (min d (%days-in-month yy mm))))
         (format nil "~4,'0D-~2,'0D-~2,'0D" yy mm dd))))))

;;; ── sat : denotational, ΟΛΙΚΗ (spec §1.2) ──
;;; LIVE-EVENTS: λίστα plists (:condition-id :kind :ref :outcome :at) — ΗΔΗ
;;; φιλτραρισμένα ως recorded-live κατά known-at από τον καλούντα (Π2 έδρα)·
;;; το sat είναι ΚΑΘΑΡΗ συνάρτηση, δεν αγγίζει χρόνο εγγραφής.

(defun %sat-instrument (kind ref live-events)
  "Το αποτέλεσμα για (:instrument-event KIND REF): από το ΜΟΝΑΔΙΚΟ live
   γεγονός που ταιριάζει (kind+ref). Πολλαπλά αντιφατικά ⇒ ΣΦΑΛΜΑ (ο γράφος
   είναι ασυνεπής — όχι σιωπηλή επιλογή). Κανένα ⇒ :pending."
  (let ((hits (remove-if-not
               (lambda (e) (and (eq (getf e :kind) kind)
                                (equal (getf e :ref) ref)))
               live-events)))
    (cond ((null hits) (values :pending nil))
          ((null (rest hits))
           (values (getf (first hits) :outcome) (getf (first hits) :at)))
          (t (error 'invalid-condition
                    :reason (format nil "~D αντιφατικά live γεγονότα για ~S ~S"
                                    (length hits) kind ref))))))

(defun sat (ast live-events)
  "(values :pending|:satisfied|:refuted at-ή-nil) — ολική, ντετερμινιστική.
   :or ⇒ ικανοποίηση με το ΕΛΑΧΙΣΤΟ at· :and ⇒ με το ΜΕΓΙΣΤΟ at·
   refuted κανόνες κατά spec §1.2. Το at είναι ΠΑΝΤΑ legal-date."
  (ecase (first ast)
    (:date-reached (values :satisfied (second ast)))
    (:instrument-event (%sat-instrument (second ast) (third ast) live-events))
    (:after
     (multiple-value-bind (st at) (sat (third ast) live-events)
       (if (eq st :satisfied)
           (values :satisfied (date+ at (second ast)))
           (values st at))))
    (:and
     (let ((results (mapcar (lambda (c) (multiple-value-list (sat c live-events)))
                            (rest ast))))
       (cond ((find :refuted results :key #'first)
              (values :refuted
                      (reduce (lambda (a b) (if (%time<= a b) a b))
                              (mapcar #'second (remove :refuted results
                                                       :key #'first :test-not #'eq)))))
             ((every (lambda (r) (eq (first r) :satisfied)) results)
              (values :satisfied
                      (reduce (lambda (a b) (if (%time<= a b) b a))
                              (mapcar #'second results))))
             (t (values :pending nil)))))
    (:or
     (let ((results (mapcar (lambda (c) (multiple-value-list (sat c live-events)))
                            (rest ast))))
       (cond ((find :satisfied results :key #'first)
              (values :satisfied
                      (reduce (lambda (a b) (if (%time<= a b) a b))
                              (mapcar #'second (remove :satisfied results
                                                       :key #'first :test-not #'eq)))))
             ((every (lambda (r) (eq (first r) :refuted)) results)
              (values :refuted
                      (reduce (lambda (a b) (if (%time<= a b) b a))
                              (mapcar #'second results))))
             (t (values :pending nil)))))))
