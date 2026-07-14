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
   ;; [Φ7-HARDENING #1] commencement sum type — Η έδρα έναρξης ισχύος
   #:tv-commencement #:tv-commencement-key
   #:commencement-p #:commencement-fixed #:commencement-conditional
   #:commencement-key #:parse-commencement #:commencement-date #:commencement-cid
   ;; edge αναγνώστες
   #:ae-edge-id #:ae-op #:ae-target #:ae-effective #:ae-enacted
   #:qe-reason #:qe-edge
   ;; γράφος
   #:version-graph #:make-graph #:graph-body #:load-graph
   #:graph-versions-of #:graph-quarantine #:graph-gaps #:graph-edge-count
   #:submit-genesis! #:admit-edge! #:quarantine! #:retract-knowledge!
   #:add-knowledge-gap! #:kg-provision-id #:kg-effective #:kg-kind
   #:version-at #:snapshot-at #:verify-chain #:graph-chain-head #:graph-latest-at
   #:make-edge-spec #:make-version-spec
   ;; [0088 Φ7 Π1] Formal Temporal Semantics — effectivity conditions
   #:make-effectivity-condition #:condition-id #:condition-ast #:condition-class
   #:valid-condition-ast-p #:instrument-kinds
   #:instrument-kind-entries #:instrument-kind-entry
   ;; [Φ7 Π2] condition records — διτεμπορικά, ΚΑΜΙΑ αποθηκευμένη κατάσταση
   #:declare-condition! #:record-condition-event! #:retract-condition-event!
   #:condition-status #:graph-condition #:graph-condition-events
   #:condition-event #:ce-event-id #:ce-condition-id #:ce-kind #:ce-ref
   #:ce-outcome #:ce-at #:ce-evidence #:ce-verifier
   #:ce-recorded-from #:ce-recorded-until
   ;; [Φ7 Π4] regime edges + Allen έδρα + Υ2β
   #:admit-regime-edge! #:retract-regime-edge! #:graph-regimes
   #:regime-edge #:re-edge-id #:re-op #:re-target #:re-version
   #:re-span-from #:re-span-until #:re-scope #:re-condition-id #:re-prior-edge-id
   #:re-recorded-from #:re-recorded-until
   #:interval-relation #:interval-intersects-p #:interval-covers-p
   ;; [Φ7 Π5] deterministic effectivity attestation
   #:make-effectivity-attestation
   ;; [Φ7-HARDENING #2] scope model — Η ΜΙΑ έδρα
   #:scope-dimension-entries #:scope-dimension-tags
   #:canon-scope-set #:scope-covers-p #:scope-intersects-p
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
  commencement          ; [Φ7-HARDENING #1] sum type (:fixed d)|(:conditional cid)
                        ; — Η έδρα· ΠΟΤΕ sentinel string σε πεδίο ημερομηνίας
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
  provision-id act-ref kind effective
  until          ; [Υ2β] legal-date | NIL — δηλωμένο ΑΝΩ όριο του κενού:
                 ; με until, το κενό μπλοκάρει ΜΟΝΟ valid-at ∈ [effective, until)·
                 ; NIL = ως τώρα (όλη η ακάλυπτη περίοδος — υπερ-προσεκτικό)
  recorded-from)

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

;;; [Φ7 Π3] effective sum type: legal-date | (:conditional condition-id) —
;;; ΚΛΕΙΣΤΟ, το NIL δεν χωράει (spec §4). Στο hash/σειριοποίηση το conditional
;;; προβάλλεται ως "conditional:<cid>" (value-canonical string).

(defun %conditional-effective-p (e)
  (and (consp e) (eq (first e) :conditional)
       (stringp (second e)) (plusp (length (second e)))
       (null (cddr e))))

(defun %effective-key (e)
  "Η κανονική string προβολή του effective για hash/ταξινόμηση."
  (if (%conditional-effective-p e)
      (format nil "conditional:~A" (second e))
      e))

;;; [Φ7-HARDENING #1] COMMENCEMENT SUM TYPE — Η ΜΙΑ έδρα έναρξης ισχύος:
;;;   (:fixed <legal-date>) | (:conditional <condition-id>)
;;; ΚΛΕΙΣΤΟΣ τύπος. ΚΑΜΙΑ condition-ταυτότητα δεν μεταμφιέζεται σε
;;; ημερομηνία: το tv-valid-from είναι πλέον ΠΡΟΒΟΛΗ (legal-date | NIL —
;;; τίμια άγνοια όσο η αίρεση εκκρεμεί), ΟΧΙ slot που χωράει sentinel.
;;; Το journal/hash δεσμεύει την ΚΑΝΟΝΙΚΗ string προβολή (commencement-key:
;;; "YYYY-MM-DD" | "conditional:<cid>") — αυτό είναι ΣΕΙΡΙΟΠΟΙΗΣΗ της έδρας,
;;; όχι δεύτερος τύπος: τα append-only journals δεν ξαναγράφονται ΠΟΤΕ
;;; (καμία byte-migration, όλα τα υπάρχοντα hashes/chains σταθερά), ενώ η
;;; runtime αναπαράσταση είναι ΠΑΝΤΑ το sum type (parse-commencement =
;;; fail-closed αντίστροφη, load-graph τη διατρέχει).

(defun commencement-p (c)
  (and (consp c) (null (cddr c))
       (case (first c)
         (:fixed (legal-date-p (second c)))
         (:conditional (and (stringp (second c)) (plusp (length (second c)))))
         (t nil))))

(defun commencement-fixed (date)
  (%require-date date "commencement")
  (list :fixed date))

(defun commencement-conditional (cid)
  (unless (and (stringp cid) (plusp (length cid)))
    (error 'invalid-edge :reason "commencement-conditional: condition-id μη κενό string"))
  (list :conditional cid))

(defun %require-commencement (c where)
  (unless (commencement-p c)
    (error 'invalid-edge
           :reason (format nil "~A: απαιτείται commencement (:fixed legal-date) | (:conditional cid) — βρέθηκε ~S"
                           where c)))
  c)

(defun commencement-key (c)
  "Η ΜΙΑ κανονική string προβολή για journal/hash — projection, όχι τύπος."
  (%require-commencement c "commencement-key")
  (ecase (first c)
    (:fixed (second c))
    (:conditional (format nil "conditional:~A" (second c)))))

(defun parse-commencement (s)
  "Αντίστροφη της commencement-key — fail-closed (load-graph/replay)."
  (unless (stringp s)
    (error 'journal-corruption
           :reason (format nil "commencement serialization μη-string: ~S" s)))
  (cond ((legal-date-p s) (list :fixed s))
        ((and (> (length s) 12) (string= "conditional:" s :end2 12))
         (list :conditional (subseq s 12)))
        (t (error 'journal-corruption
                  :reason (format nil "μη αναγνωρίσιμη commencement serialization: ~S" s)))))

(defun commencement-date (c)
  "legal-date για :fixed, NIL για :conditional (η ημερομηνία ΔΕΝ υπάρχει
   πριν την ικανοποίηση — παράγεται στο version-at από το sat, spec §4)."
  (when (eq :fixed (first c)) (second c)))

(defun commencement-cid (c)
  (when (eq :conditional (first c)) (second c)))

(defun %tv-conditional-cid (v)
  "Το condition-id μιας ΥΠΟ ΑΙΡΕΣΗ έκδοσης, αλλιώς NIL — μέσω της έδρας."
  (commencement-cid (tv-commencement v)))

(defun tv-valid-from (v)
  "ΗΜΕΡΟΜΗΝΙΑΚΗ προβολή της έναρξης ισχύος: legal-date για :fixed,
   NIL για :conditional — τίμια άγνοια, ποτέ sentinel μεταμφιεσμένο σε date."
  (commencement-date (tv-commencement v)))

(defun tv-commencement-key (v)
  "Η κανονική string προβολή της έναρξης (ταυτότητες/receipts)."
  (commencement-key (tv-commencement v)))

(defun %edge-hash (op target from to act-ref act-seq enacted effective fek-date span)
  (orchestrator.canonical-representation:canonical-hash
   (list (cons "act_ref" act-ref)
         (cons "act_seq" act-seq)
         (cons "effective" (%effective-key effective))
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
  conditions            ; [Φ7 Π2] condition-id → effectivity-condition (equal)
  cond-events           ; [Φ7 Π2] condition-id → λίστα condition-event (equal)
  regimes               ; [Φ7 Π4] λίστα regime-edge (σειρά εισαγωγής, νεότερο πρώτο)
  chain                 ; τρέχον chain-hash (κεφαλή αλυσίδας)
  (latest-at "1970-01-01T00:00:00Z")) ; [#7] το ΜΕΓΙΣΤΟ journal :at — παράγωγο
                        ; του journal (ντετερμινιστικό), το as-of των receipts

(defun %graph-path (body-string)
  (orchestrator.paths:institution-dir
   (format nil "deployment/data/version-graph/~A.vgraph.sexp"
           (substitute #\- #\/ body-string))))

(defun make-graph (body-string)
  (%make-graph :body body-string :path (%graph-path body-string)
               :versions (make-hash-table :test 'equal)
               :by-provision (make-hash-table :test 'equal)
               :edges (make-hash-table :test 'equal)
               :conditions (make-hash-table :test 'equal)
               :cond-events (make-hash-table :test 'equal)
               :quarantine '() :gaps '() :regimes '() :chain "genesis"))

(defun graph-latest-at (graph)
  "[Φ7-HARDENING #7] Το transaction-time στιγμιότυπο «ό,τι ξέρει το journal»
   — μέγιστο :at όλων των γραμμών: ντετερμινιστική συνάρτηση του journal,
   ΟΧΙ ρολόι build (τα receipt ids μένουν αναπαραγώγιμα ανά journal state)."
  (vg-latest-at graph))

(defun %note-latest-at! (graph at)
  (when (and (stringp at) (string> at (vg-latest-at graph)))
    (setf (vg-latest-at graph) at)))

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
      (%note-latest-at! graph (getf plist :at))
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

(defun make-version-spec (&key provision-id text heading valid-from commencement
                               (status :in-force) (previous :genesis) assurance)
  "Υποψήφιο περιεχόμενο έκδοσης (πριν την εισδοχή). Fail-closed στον χρόνο.
   [Φ7-HARDENING #1] ΑΚΡΙΒΩΣ ΜΙΑ πηγή έναρξης: είτε VALID-FROM (legal-date ⇒
   (:fixed d)) είτε COMMENCEMENT (το sum type αυτούσιο) — ποτέ και τα δύο,
   ποτέ sentinel string."
  (when (and valid-from commencement)
    (error 'invalid-edge :reason "make-version-spec: valid-from ΚΑΙ commencement — ακριβώς μία πηγή έναρξης"))
  (let ((c (cond (commencement (%require-commencement commencement "make-version-spec"))
                 (t (%require-date valid-from "valid-from")
                    (list :fixed valid-from)))))
    (unless (and (stringp provision-id) (stringp text))
      (error 'invalid-edge :reason "provision-id/text μη-string"))
    (unless (member assurance '(:verified :extracted-verified :attested-manual
                                :reconstructed :legacy-unverifiable))
      (error 'invalid-edge :reason (format nil "άγνωστο assurance ~S" assurance)))
    (list :provision-id provision-id :text text :heading heading
          :commencement c :status status :previous previous
          :assurance assurance)))

(defun %normalize-version-spec (vs)
  "[Φ7-HARDENING #1] Η ΜΙΑ είσοδος version-spec στο admit-edge!: spec με
   :commencement επικυρώνεται· raw plist με :valid-from περνά ΜΕΣΑ από τη
   make-version-spec (μία έδρα κατασκευής — καμία δεύτερη σημασιολογία)."
  (if (getf vs :commencement)
      (progn (%require-commencement (getf vs :commencement) "to-spec") vs)
      (apply #'make-version-spec vs)))

(defun make-edge-spec (&key op target from-versions to-specs act-ref
                            act-internal-seq corrects-edge-id source-span
                            enacted effective fek-date
                            (assurance :extracted-verified) (confidence 1))
  "Υποψήφια ακμή. Ο ΤΥΠΟΣ απαιτεί enacted/effective/fek-date ως legal-date —
   υποψήφιο με άγνωστη ισχύ ΔΕΝ κατασκευάζεται καν: πήγαινε στο quarantine!."
  (unless (member op +edge-ops+)
    (error 'invalid-edge :reason (format nil "άγνωστη πράξη ~S" op)))
  (%require-date enacted "enacted")
  ;; [Φ7 Π3] effective sum type: legal-date | (:conditional cid)
  (unless (%conditional-effective-p effective)
    (%require-date effective "effective"))
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

(defun add-knowledge-gap! (graph &key provision-id act-ref kind effective until)
  "ΤΙΜΙΑ ΑΓΝΟΙΑ πρώτης τάξης: δηλωμένο κενό ανακατασκευής (π.χ. text-less
   αναθεώρηση) — journaled, ορατό σε κάθε ερώτημα που πέφτει στο κενό.
   [Υ2β] Με UNTIL (legal-date): το κενό γίνεται ΔΙΑΣΤΗΜΑ [effective, until)
   — μπλοκάρει μόνο τομές μέσα του· χωρίς UNTIL: όλη η ακάλυπτη περίοδος."
  (%require-date effective "effective (κενού γνώσης)")
  (when until (%require-date until "until (κενού γνώσης)"))
  (let* ((rid (format nil "gap:~A@~A..~A:~A" provision-id effective
                      (or until "open") (or act-ref "")))
         (line (%journal! graph (list :kind :knowledge-gap :record-id rid
                                      :provision-id provision-id :act-ref act-ref
                                      :gap-kind kind :effective effective
                                      :gap-until until
                                      :at (orchestrator.journal:iso-now))
                          :verify nil))
         (g (make-knowledge-gap :provision-id provision-id :act-ref act-ref
                                :kind kind :effective effective :until until
                                :recorded-from (%recorded-of line))))
    (push g (vg-gaps graph))
    g))

(defun submit-genesis! (graph vspec &key derivation)
  "Εισδοχή έκδοσης-γένεσης (bootstrap/import) — δεν προέρχεται από ακμή.
   Ο έλεγχος σύγκρουσης (G4) προηγείται ΚΑΘΕ εγγραφής — κανένα ορφανό record."
  (when (%open-version graph (getf vspec :provision-id))
    (error 'invalid-edge :reason (format nil "genesis σε διάταξη με ΑΝΟΙΧΤΗ έκδοση: ~A (σύγκρουση ταυτότητας — G4)" (getf vspec :provision-id))))
  ;; [Φ7-HARDENING #1] genesis με conditional commencement δεν έχει νόημα:
  ;; η γένεση σώματος είναι γεγονός, όχι αίρεση — fail-closed.
  (when (commencement-cid (getf vspec :commencement))
    (error 'invalid-edge :reason "genesis με :conditional commencement — η γένεση απαιτεί (:fixed legal-date)"))
  (let* ((vh (%version-hash (getf vspec :provision-id) (getf vspec :text)
                            (getf vspec :heading)
                            (commencement-key (getf vspec :commencement))
                            (getf vspec :status) :genesis))
         (line (%journal! graph
                          (list :kind :text-version :record-id vh
                                :provision-id (getf vspec :provision-id)
                                :text (getf vspec :text)
                                :heading (getf vspec :heading)
                                :valid-from (commencement-key (getf vspec :commencement))
                                :status (getf vspec :status)
                                :previous "genesis"
                                :created-by (or derivation "bootstrap")
                                :assurance (getf vspec :assurance)
                                :at (orchestrator.journal:iso-now))
                          :verify nil))
         (v (make-text-version
             :version-hash vh :provision-id (getf vspec :provision-id)
             :text (getf vspec :text) :heading (getf vspec :heading)
             :commencement (getf vspec :commencement) :valid-until :open
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
  (setf espec (copy-list espec))
  (setf (getf espec :to-specs)
        (mapcar #'%normalize-version-spec (getf espec :to-specs)))
  (let ((op (getf espec :op))
        (target (getf espec :target))
        (effective (getf espec :effective)))
    (unless (member op +supported-ops+)
      (return-from admit-edge!
        (values nil (quarantine! graph espec :unsupported-op))))
    ;; [Φ7 Π3] effective sum type — typed, ποτέ nullable: legal-date Ή
    ;; (:conditional cid) με ΔΗΛΩΜΕΝΟ cid (declare-before-reference).
    (cond
      ((%conditional-effective-p effective)
       (let ((c (graph-condition graph (second effective))))
         (unless c
           (error 'invalid-edge
                  :reason (format nil "conditional ακμή με ΑΔΗΛΩΤΟ condition-id ~A — declare-condition! πρώτα"
                                  (second effective))))
         ;; [κριτής Π2-Π4 #3] resolutory commencement ΔΕΝ υποστηρίζεται εδώ:
         ;; η διαλυτική αίρεση κλείνει ισχύ (σχήμα Π5/regime) — αντεστραμμένη
         ;; σημασιολογία δεν επιτρέπεται να είναι καν αναπαραστάσιμη.
         (when (eq (condition-class c) :resolutory)
           (error 'invalid-edge
                  :reason "conditional ακμή έναρξης με :resolutory αίρεση — η διαλυτική ΚΛΕΙΝΕΙ ισχύ: χρησιμοποίησε admit-regime-edge! (:expire/:suspend με condition-id, [#3])")))
       ;; [Φ7-HARDENING #1] οι υπό αίρεση νέες εκδόσεις: typed commencement
       ;; (:conditional cid) + :not-yet-effective — ημερομηνία ισχύος ΔΕΝ
       ;; υπάρχει πριν την ικανοποίηση (παράγωγη, §4)· κανένα sentinel.
       (dolist (vs (getf espec :to-specs))
         (unless (and (equal (getf vs :commencement)
                             (list :conditional (second effective)))
                      (eq (getf vs :status) :not-yet-effective))
           (error 'invalid-edge
                  :reason (format nil "conditional ακμή: κάθε to-spec απαιτεί :commencement (:conditional ~A) και :status :not-yet-effective — βρέθηκε (~S ~S)"
                                  (second effective)
                                  (getf vs :commencement) (getf vs :status))))))
      (t (%require-date effective "effective")))
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
                                          (getf vs :heading)
                                          (commencement-key (getf vs :commencement))
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
          ;; κλείσιμο ισχύος προηγούμενης — ΔΙΤΕΜΠΟΡΙΚΗ supersession (journaled).
          ;; [Φ7 Π3 — spec §4] Για CONDITIONAL ακμή ΔΕΝ γράφεται κανένα κλείσιμο:
          ;; η προηγούμενη μένει :open και το version-at παράγει το κλείσιμο
          ;; από το sat στην τομή (valid-at, known-at) — ΕΝΑΣ μηχανισμός.
          (when (and cur (not (%conditional-effective-p effective)))
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
                                            :valid-from (commencement-key (getf vs :commencement))
                                            :status (getf vs :status)
                                            :previous (string-downcase (string prev-hash))
                                            :created-by eid
                                            :assurance (getf vs :assurance)
                                            :at (orchestrator.journal:iso-now))))
                     (v (make-text-version
                         :version-hash vh :provision-id (getf vs :provision-id)
                         :text (getf vs :text) :heading (getf vs :heading)
                         :commencement (getf vs :commencement) :valid-until :open
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

(defun %live-at-p (recorded-from recorded-until known-at)
  "[κριτής Π2-Π4 #9] Η ΜΙΑ έδρα του διτεμπορικού liveness κατηγορήματος:
   recorded-from ≤ known-at < recorded-until|:current — versions, condition
   events και regime edges τη διατρέχουν ΟΛΑ."
  (and (%time<= recorded-from known-at "recorded-from" "known-at")
       (or (eq :current recorded-until)
           (< (%time-key known-at "known-at")
              (%time-key recorded-until "recorded-until")))))

(defun %recorded-live-p (v known-at)
  (%live-at-p (tv-recorded-from v) (tv-recorded-until v) known-at))

(defun %finish-version (graph pid valid-at known-at v basis &optional scope-context)
  "[Φ7 Π4] Τελικό βήμα version-at: live αναστολή που καλύπτει το valid-at
   (χωρίς revive εκεί) ⇒ typed basis (:suspended edge-id) — ΓΝΩΣΤΗ απάντηση,
   ποτέ 422."
  (let ((s (and v (%active-suspension graph pid valid-at known-at scope-context))))
    (if s
        (values v (list :suspended (re-edge-id s)))
        (values v basis))))

(defun %known-by-p (recorded-from known-at)
  "T όταν κάτι με RECORDED-FROM ήταν ήδη ΓΝΩΣΤΟ κατά KNOWN-AT — η
   transaction-time πύλη για καραντίνες/κενά (Υ2): μελλοντική καταγραφή δεν
   δηλητηριάζει παλαιότερο epistemic snapshot."
  (%time<= recorded-from known-at "recorded-from" "known-at"))

(defun version-at (graph pid &key valid-at known-at scope-context)
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
    ;; [Φ7 Π3/Π4 — spec §4, ΕΝΑΣ ΜΗΧΑΝΙΣΜΟΣ (κλείσιμο κριτή Π2-Π4 #1/#2/#4)]
    ;; TILING: κάθε recorded-live έκδοση αποκτά ΠΑΡΑΓΩΓΑ όρια —
    ;; • conditional (sentinel valid-from): sat(cid, known-at) ⇒ satisfied
    ;;   ⇒ from = t (ή το from ρητού retroact) — τα regime rewrites
    ;;   ΕΦΑΡΜΟΖΟΝΤΑΙ ΚΑΙ εδώ· pending/refuted ⇒ ΕΚΤΟΣ ισχύος·
    ;; • κανονική: %rewritten-bounds (διτεμπορικά rewrites).
    ;; Μετά, ΚΑΘΕ until ψαλιδίζεται στο from της ΕΠΟΜΕΝΗΣ (κατά from)
    ;; έκδοσης — το κλείσιμο της προηγούμενης είναι ΣΗΜΑΣΙΟΛΟΓΙΑ του
    ;; μοντέλου, όχι προτεραιότητα διαδρομής: τρίτες/κανονικές ακμές μετά
    ;; από conditional δεν παράγουν ούτε ψευδο-επικαλύψεις ούτε νεκρές
    ;; νικήτριες εκδόσεις. Ίδιο fold live και στο replay (καμία κατάσταση).
    (let ((tiles '())          ; στοιχεία (v from until)
          (pending '()))       ; στοιχεία (cid . since) — ΟΛΑ τα pending
      (dolist (v records)
        (when (%recorded-live-p v known-at)
          (let ((cid (%tv-conditional-cid v)))
            (if cid
                (multiple-value-bind (st at)
                    (condition-status graph cid :known-at known-at)
                  (case st
                    (:satisfied
                     (multiple-value-bind (f u) (%rewritten-bounds graph v known-at scope-context)
                       ;; [#1] conditional βάση from = NIL (καμία ημερομηνία στην
                       ;; έδρα)· ρητό retroact την ξαναγράφει σε date — αλλιώς
                       ;; from = το παράγωγο sat at (spec §4).
                       (push (list v (or f at) u) tiles)))
                    (:pending (push (cons cid (tv-recorded-from v)) pending))
                    (t nil)))
                (multiple-value-bind (f u) (%rewritten-bounds graph v known-at scope-context)
                  (push (list v f u) tiles))))))
      ;; ντετερμινιστική επιλογή pending σημείωσης: ελάχιστο (since, cid)
      (let ((pending-note
              (when pending
                (let ((best (first (sort (copy-list pending)
                                         (lambda (a b)
                                           (or (< (%time-key (cdr a) "since")
                                                  (%time-key (cdr b) "since"))
                                               (and (= (%time-key (cdr a) "since")
                                                       (%time-key (cdr b) "since"))
                                                    (string< (car a) (car b)))))))))
                  (list :not-yet-effective (car best) (cdr best))))))
        (setf tiles (sort tiles (lambda (a b)
                                  (< (%time-key (second a) "from")
                                     (%time-key (second b) "from")))))
        ;; ίδια from σε δύο εκδόσεις = μη επιλύσιμη διαμάχη
        (loop for (a b) on tiles while b
              do (when (= (%time-key (second a) "from") (%time-key (second b) "from"))
                   (error 'temporal-uncertainty :provision pid
                          :why "δύο εκδόσεις με ΙΔΙΟ σημείο έναρξης ισχύος στην τομή — ασυνεπής γράφος")))
        ;; ψαλίδισμα: until_i := min(until_i, from_{i+1})
        (loop for (a b) on tiles while b
              do (when (or (eq (third a) :open)
                           (> (%time-key (third a) "until")
                              (%time-key (second b) "from")))
                   (setf (third a) (second b))))
        (let ((live (remove-if-not
                     (lambda (tile)
                       (destructuring-bind (v f u) tile
                         (declare (ignore v))
                         (and (%time<= f valid-at "from" "valid-at")
                              (or (eq u :open)
                                  (< (%time-key valid-at "valid-at")
                                     (%time-key u "until"))))))
                     tiles)))
          (cond
            ((= 1 (length live))
             (%finish-version graph pid valid-at known-at
                              (first (first live)) (or pending-note :complete)
                              scope-context))
            ((null live)
         ;; ΚΕΝΟ ΓΝΩΣΗΣ (text-less ιστορικό): μετρά ΜΟΝΟ αν ήταν ήδη
         ;; καταγεγραμμένο κατά known-at (Υ2) — αλλιώς το snapshot εκείνης της
         ;; γνώσης απλώς δεν είχε καμία έκδοση (:no-version-in-force, τίμιο).
         ;; [Υ2β] gap με δηλωμένο until = ΔΙΑΣΤΗΜΑ [effective, until): μπλοκάρει
         ;; ΜΟΝΟ τομές μέσα του· χωρίς until: όλη η ακάλυπτη περίοδος (ως τώρα).
         (let ((g (find-if (lambda (g)
                             (and (equal pid (kg-provision-id g))
                                  (%known-by-p (kg-recorded-from g) known-at)
                                  (or (null (kg-until g))
                                      (interval-covers-p (kg-effective g)
                                                         (kg-until g) valid-at))))
                           (vg-gaps graph))))
           (if g
               (error 'temporal-uncertainty :provision pid
                      :why (format nil "δηλωμένο κενό γνώσης (~A ~A, καταγεγραμμένο ~A): το κείμενο της περιόδου δεν ανακατασκευάζεται από τις διαθέσιμες πηγές"
                                   (kg-kind g) (kg-effective g) (kg-recorded-from g)))
               ;; [κριτής Π2-Π4 #5] το ονομαστικό pending ΔΕΝ χάνεται:
               ;; τρίτη τιμή (:not-yet-effective cid since) όταν υπάρχει
               ;; δηλωμένη επικείμενη διάταξη — προσθετικό, κανένας
               ;; καταναλωτής του (values nil :no-version-in-force) δεν σπάει.
               (values nil :no-version-in-force pending-note))))
        (t (error 'temporal-uncertainty :provision pid
                  :why (format nil "~D επικαλυπτόμενες εκδόσεις στην τομή — ασυνεπής γράφος" (length live))))))))))

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
        (%note-latest-at! graph (getf line :at))
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
                              :commencement (parse-commencement (getf line :valid-from))
                              :valid-until :open
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
                                     :until (getf line :gap-until)
                                     :recorded-from (%recorded-of line))
                 (vg-gaps graph)))
          (:retract
           (let ((v (gethash (getf line :version) (vg-versions graph))))
             (when v (setf (tv-recorded-until v) (%recorded-of line)))))
          ;; [Φ7 Π2] condition records — semantic hash ③ ανά kind
          (:condition-declared
           (let* ((class (getf line :class))
                  (ast (getf line :ast))
                  (semantic (orchestrator.journal:sha256-hex
                             (with-output-to-string (out)
                               (%canon-sexp (list :lawmax/effectivity-condition/1
                                                  class ast)
                                            out)))))
             (unless (equal semantic rid)
               (error 'journal-corruption
                      :reason (format nil "condition-declared ~A: semantic hash ~A ≠ record-id — πλαστή ταυτότητα αίρεσης" rid semantic)))
             ;; το journaled ast οφείλει να ΕΙΝΑΙ κανονικό (spec §3.1)
             (valid-condition-ast-p ast)
             (unless (equal ast (%canon-condition-ast ast))
               (error 'journal-corruption
                      :reason (format nil "condition-declared ~A: journaled ast ΔΕΝ είναι κανονικό — διεφθαρμένη δήλωση" rid)))
             (setf (gethash rid (vg-conditions graph))
                   (%make-condition :id rid :class class :ast ast))))
          (:condition-event
           (let* ((cid (getf line :condition-id))
                  (semantic (%condition-event-hash
                             cid (getf line :ikind) (getf line :ref)
                             (getf line :outcome) (getf line :event-at)
                             (%evidence-digest (getf line :evidence)))))
             (unless (equal semantic rid)
               (error 'journal-corruption
                      :reason (format nil "condition-event ~A: semantic hash ~A ≠ record-id — πλαστή ταυτότητα γεγονότος" rid semantic)))
             (unless (gethash cid (vg-conditions graph))
               (error 'journal-corruption
                      :reason (format nil "condition-event ~A αναφέρει αδήλωτο cid ~A — σπασμένο declare-before-reference" rid cid)))
             (push (make-condition-event
                    :event-id rid :condition-id cid
                    :kind (getf line :ikind) :ref (getf line :ref)
                    :outcome (getf line :outcome) :at (getf line :event-at)
                    :evidence (getf line :evidence)
                    :verifier (getf line :verifier)
                    :recorded-from (%recorded-of line)
                    :recorded-until :current)
                   (gethash cid (vg-cond-events graph)))))
          ;; [Φ7 Π4] regime edges — semantic check ③
          (:regime-edge
           (let ((semantic (%regime-hash (getf line :op) (getf line :target)
                                         (getf line :version)
                                         (getf line :span-from) (getf line :span-until)
                                         (getf line :scope) (getf line :condition-id)
                                         (getf line :act-ref) (getf line :act-seq)
                                         (getf line :enacted) (getf line :fek-date)
                                         (getf line :prior))))
             (unless (equal semantic rid)
               (error 'journal-corruption
                      :reason (format nil "regime-edge ~A: semantic hash ~A ≠ record-id — πλαστή καθεστωτική πράξη" rid semantic)))
             (%install-regime graph
                              (make-regime-edge
                               :edge-id rid :op (getf line :op)
                               :target (getf line :target) :version (getf line :version)
                               :span-from (getf line :span-from)
                               :span-until (getf line :span-until)
                               :scope (getf line :scope) ; [#2] το scope ΦΟΡΤΩΝΕΤΑΙ (πριν: σιωπηλό drop)
                               :condition-id (getf line :condition-id)
                               :act-ref (getf line :act-ref) :act-seq (getf line :act-seq)
                               :enacted (getf line :enacted) :fek-date (getf line :fek-date)
                               :prior-edge-id (getf line :prior)
                               :recorded-from (%recorded-of line)
                               :recorded-until :current))))
          (:regime-retract
           (let* ((eid (getf line :edge))
                  (re (find-if (lambda (r) (and (equal (re-edge-id r) eid)
                                                (eq (re-recorded-until r) :current)))
                               (vg-regimes graph))))
             (unless re
               (error 'journal-corruption
                      :reason (format nil "regime-retract ~A: ανύπαρκτο/κλεισμένο edge ~A" rid eid)))
             (setf (re-recorded-until re) (%recorded-of line))))
          (:condition-event-retract
           (let* ((eid (getf line :event))
                  (ce (loop for events being the hash-values of (vg-cond-events graph)
                            thereis (find-if (lambda (e)
                                               (and (equal (ce-event-id e) eid)
                                                    (eq (ce-recorded-until e) :current)))
                                             events))))
             (unless ce
               (error 'journal-corruption
                      :reason (format nil "condition-event-retract ~A: ανύπαρκτο/ήδη κλεισμένο event ~A" rid eid)))
             (setf (ce-recorded-until ce) (%recorded-of line))))
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
  (defun instrument-kind-entries ()
    "Το ΚΛΕΙΣΤΟ TYPED μητρώο ειδών θεσμικών γεγονότων (schema /2): λίστα
     plists (:kind :authority-class :evidence) από το
     deployment/data/instrument-kind-registry.sexp. Reader safety: *read-eval*
     ΡΗΤΑ nil (κριτής-δημιουργού Π1). Απόν/άκυρο/ελλιπές ⇒ ΣΦΑΛΜΑ."
    (or cache
        (setf cache
              (let ((plist (with-open-file (s (%instrument-registry-path)
                                              :external-format :utf-8)
                             (let ((*package* (find-package :keyword))
                                   (*read-eval* nil))
                               (read s)))))
                (unless (eq (getf plist :schema) :instrument-kind-registry/2)
                  (error 'invalid-condition
                         :reason "μητρώο instrument-kinds: άγνωστο schema (απαιτείται /2)"))
                (let ((entries (getf plist :entries)))
                  (unless entries
                    (error 'invalid-condition
                           :reason "μητρώο instrument-kinds: κενό"))
                  (dolist (e entries)
                    (unless (and (keywordp (getf e :kind))
                                 (keywordp (getf e :authority-class))
                                 (consp (getf e :evidence)))
                      (error 'invalid-condition
                             :reason (format nil "μητρώο instrument-kinds: ελλιπής typed εγγραφή ~S — κάθε kind απαιτεί :authority-class + :evidence schema" e))))
                  ;; [κριτής A#12] μοναδικότητα kinds — διπλή εγγραφή δεν
                  ;; επιλύεται σιωπηλά στην πρώτη
                  (unless (= (length entries)
                             (length (remove-duplicates
                                      entries :key (lambda (e) (getf e :kind)))))
                    (error 'invalid-condition
                           :reason "μητρώο instrument-kinds: διπλότυπο kind"))
                  entries))))))

(defun instrument-kinds ()
  "Τα keys του typed μητρώου — για membership ελέγχους γραμματικής."
  (mapcar (lambda (e) (getf e :kind)) (instrument-kind-entries)))

(defun instrument-kind-entry (kind)
  "Η ΠΛΗΡΗΣ typed εγγραφή ενός kind (authority-class, evidence schema) —
   άγνωστο kind ⇒ typed σφάλμα."
  (or (find kind (instrument-kind-entries) :key (lambda (e) (getf e :kind)))
      (error 'invalid-condition
             :reason (format nil "άγνωστο instrument kind ~S" kind))))

;;; ── [Φ7-HARDENING #2] SCOPE MODEL — Η ΜΙΑ έδρα (spec v3 §5) ──
;;; scope-set = πεπερασμένο σύνολο δηλώσεων στις 4 διαστάσεις
;;; {:territorial :personal :material :procedural}. NIL = καθολική ισχύς.
;;; Canonical μορφή: ((:dimension tag…)…) — διαστάσεις σε σταθερή σειρά,
;;; tags ταξινομημένα, χωρίς διπλότυπα. Tags ΜΟΝΟ από το κλειστό data-μητρώο.

(defparameter +scope-dimensions+
  '(:territorial :personal :material :procedural)
  "Η σταθερή σειρά διαστάσεων της canonical μορφής.")

(defun %scope-registry-path ()
  (orchestrator.paths:institution-dir "deployment/data/scope-tag-registry.sexp"))

(let ((cache nil))
  (defun scope-dimension-entries ()
    "Το ΚΛΕΙΣΤΟ TYPED μητρώο scope tags (schema /1): λίστα plists
     (:dimension :tags :doc). Reader safety: *read-eval* ΡΗΤΑ nil.
     Απόν/άκυρο/ελλιπές/διπλότυπο ⇒ ΣΦΑΛΜΑ — ποτέ σιωπηλή αποδοχή."
    (or cache
        (setf cache
              (let ((plist (with-open-file (s (%scope-registry-path)
                                              :external-format :utf-8)
                             (let ((*package* (find-package :keyword))
                                   (*read-eval* nil))
                               (read s)))))
                (unless (eq (getf plist :schema) :scope-tag-registry/1)
                  (error 'invalid-condition
                         :reason "μητρώο scope-tags: άγνωστο schema (απαιτείται /1)"))
                (let ((entries (getf plist :dimensions)))
                  (unless entries
                    (error 'invalid-condition :reason "μητρώο scope-tags: κενό"))
                  (dolist (e entries)
                    (unless (and (member (getf e :dimension) +scope-dimensions+)
                                 (consp (getf e :tags))
                                 (every #'keywordp (getf e :tags)))
                      (error 'invalid-condition
                             :reason (format nil "μητρώο scope-tags: ελλιπής/άκυρη εγγραφή ~S" e)))
                    (unless (= (length (getf e :tags))
                               (length (remove-duplicates (getf e :tags))))
                      (error 'invalid-condition
                             :reason (format nil "μητρώο scope-tags: διπλότυπο tag στη διάσταση ~S" (getf e :dimension)))))
                  (unless (= (length entries)
                             (length (remove-duplicates
                                      entries :key (lambda (e) (getf e :dimension)))))
                    (error 'invalid-condition
                           :reason "μητρώο scope-tags: διπλότυπη διάσταση"))
                  entries))))))

(defun scope-dimension-tags (dimension)
  "Τα επιτρεπτά tags μιας διάστασης — άγνωστη διάσταση ⇒ typed σφάλμα."
  (let ((e (find dimension (scope-dimension-entries)
                 :key (lambda (e) (getf e :dimension)))))
    (unless e
      (error 'invalid-condition
             :reason (format nil "άγνωστη scope διάσταση ~S — επιτρεπτές: ~S"
                             dimension +scope-dimensions+)))
    (getf e :tags)))

(defun canon-scope-set (scope-set)
  "Επικύρωση + κανονικοποίηση scope-set: NIL = καθολική· αλλιώς λίστα
   (διάσταση tag…) — κάθε διάσταση ≤1 φορά, κάθε tag στο μητρώο της.
   Canonical: διαστάσεις κατά +scope-dimensions+, tags ταξινομημένα κατά
   όνομα, χωρίς διπλότυπα. Οτιδήποτε άλλο ⇒ invalid-edge (fail-closed)."
  (when (null scope-set) (return-from canon-scope-set nil))
  (unless (consp scope-set)
    (error 'invalid-edge :reason (format nil "scope-set: λίστα δηλώσεων ή NIL — βρέθηκε ~S" scope-set)))
  (let ((seen '()))
    (dolist (decl scope-set)
      (unless (and (consp decl) (keywordp (first decl)) (rest decl)
                   (every #'keywordp (rest decl)))
        (error 'invalid-edge :reason (format nil "scope δήλωση: (διάσταση tag+) — βρέθηκε ~S" decl)))
      (let ((dim (first decl)))
        (when (member dim seen)
          (error 'invalid-edge :reason (format nil "scope-set: διπλή διάσταση ~S" dim)))
        (push dim seen)
        (let ((allowed (scope-dimension-tags dim)))
          (dolist (tag (rest decl))
            (unless (member tag allowed)
              (error 'invalid-edge
                     :reason (format nil "scope tag ~S εκτός μητρώου διάστασης ~S" tag dim)))))))
    (loop for dim in +scope-dimensions+
          for decl = (find dim scope-set :key #'first)
          when decl
            collect (cons dim (sort (remove-duplicates (rest decl))
                                    #'string< :key #'symbol-name)))))

(defun scope-covers-p (scope-set context)
  "scope-set × ερώτημα-πλαίσιο → T | NIL | :unknown (spec §5).
   Απούσα διάσταση στο scope-set = καθολική. Παρούσα διάσταση: αν το
   πλαίσιο δεν τη δηλώνει ⇒ :unknown (τίμια άγνοια — ΠΟΤΕ σιωπηλό ναι)·
   αλλιώς κάλυψη ⇔ ΟΛΑ τα tags του πλαισίου ∈ tags της δήλωσης.
   CONTEXT: λίστα (διάσταση tag+) — περνά την ίδια επικύρωση μητρώου."
  (let ((s (canon-scope-set scope-set))
        (c (canon-scope-set context))
        (unknown nil))
    (dolist (decl s)
      (let ((ctx (find (first decl) c :key #'first)))
        (cond ((null ctx) (setf unknown t))
              ((not (subsetp (rest ctx) (rest decl))) (return-from scope-covers-p nil)))))
    (if unknown :unknown t)))

(defun scope-intersects-p (s1 s2)
  "Δύο scope-sets: ανά διάσταση — universal τέμνει τα πάντα· αλλιώς
   απαιτείται μη κενή τομή tags. NIL scope-set = καθολικό."
  (let ((a (canon-scope-set s1)) (b (canon-scope-set s2)))
    (dolist (dim +scope-dimensions+ t)
      (let ((da (find dim a :key #'first))
            (db (find dim b :key #'first)))
        (when (and da db (null (intersection (rest da) (rest db))))
          (return nil))))))

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

(defun %canon-condition-ast (ast)
  "[Φ6γ-Δ³] ΣΗΜΑΣΙΟΛΟΓΙΚΗ κανονικοποίηση AST (η ταυτότητα είναι semantic,
   ΟΧΙ συντακτική): στα αντιμεταθετικά :and/:or — flattening ίδιων τελεστών,
   αφαίρεση διπλοτύπων, ντετερμινιστική ταξινόμηση παιδιών κατά value-canonical
   string· μονομελές αποτέλεσμα καταρρέει στο παιδί (x∧x ≡ x). Προϋπόθεση:
   ήδη έγκυρο κατά valid-condition-ast-p."
  (ecase (first ast)
    ((:date-reached :instrument-event) ast)
    (:after (list :after (second ast) (%canon-condition-ast (third ast))))
    ((:and :or)
     (let* ((op (first ast))
            (kids (loop for c in (rest ast)
                        for n = (%canon-condition-ast c)
                        append (if (eq (first n) op) (rest n) (list n))))
            (uniq (remove-duplicates kids :test #'equal))
            (sorted (sort (copy-list uniq) #'string<
                          :key (lambda (k)
                                 (with-output-to-string (o) (%canon-sexp k o))))))
       (if (null (rest sorted)) (first sorted) (cons op sorted))))))

(defstruct (effectivity-condition (:conc-name condition-)
                                  (:constructor %make-condition))
  id     ; sha256 του domain-separated value-canonical (tag class canon-AST)
  class  ; :suspensive | :resolutory
  ast)   ; το ΚΑΝΟΝΙΚΟ (semantic) AST — όχι η συντακτική μορφή εισόδου

(defun make-effectivity-condition (class ast)
  "Typed effectivity condition. CLASS: :suspensive (η ισχύς ΑΡΧΙΖΕΙ στην
   ικανοποίηση) | :resolutory (η ισχύς ΠΑΥΕΙ στην ικανοποίηση — π.χ. ΠΝΠ μη
   κυρωθείσα, 44§1 Σ). Το AST επικυρώνεται ΠΛΗΡΩΣ και κανονικοποιείται
   ΣΗΜΑΣΙΟΛΟΓΙΚΑ στην κατασκευή. Ταυτότητα = sha256 του DOMAIN-SEPARATED
   value-canonical (:lawmax/effectivity-condition/1 class canon-AST):
   (:and A B) ≡ (:and B A) ≡ (:and A A B)· μελλοντική αλλαγή σημασιολογίας
   ⇒ νέο tag ⇒ κανένα id δεν επιζεί με άλλη έννοια."
  (unless (member class '(:suspensive :resolutory))
    (error 'invalid-condition :reason (format nil "άγνωστη κλάση αίρεσης ~S" class)))
  (valid-condition-ast-p ast)
  (let ((canon (%canon-condition-ast ast)))
    (%make-condition
     :id (orchestrator.journal:sha256-hex
          (with-output-to-string (out)
            (%canon-sexp (list :lawmax/effectivity-condition/1 class canon) out)))
     :class class :ast canon)))

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

(defun %validate-condition-event (e)
  "[Φ6γ-Δ³ + κριτής A#12] TYPED επικύρωση ΚΑΘΕ event πριν μπει στην
   trusted αποτίμηση — raw plists με άκυρο kind/outcome/at/ref δεν φτάνουν
   ΠΟΤΕ στο sat· το :condition-id (αν υπάρχει) πρέπει να είναι μη κενό
   string· το :evidence (αν υπάρχει) ΕΠΙΚΥΡΩΝΕΤΑΙ κατά το evidence schema
   του kind στο μητρώο /2 — τα schemas ΔΕΝ είναι διακοσμητικά. Πλήρης
   υποχρεωτικότητα evidence: στην Π2 έδρα record-condition-event! (spec §3.2)."
  (unless (and (consp e)
               (member (getf e :kind) (instrument-kinds))
               (stringp (getf e :ref)) (plusp (length (getf e :ref)))
               (member (getf e :outcome) '(:satisfied :refuted))
               (legal-date-p (getf e :at)))
    (error 'invalid-condition
           :reason (format nil "άκυρο condition event ~S — απαιτείται (:kind∈μητρώο :ref string+ :outcome :satisfied|:refuted :at legal-date)" e)))
  (let ((cid (getf e :condition-id)))
    (when (and cid (not (and (stringp cid) (plusp (length cid)))))
      (error 'invalid-condition
             :reason (format nil "άκυρο :condition-id ~S σε event" cid))))
  (let ((ev (getf e :evidence)))
    (when ev (%check-evidence (getf e :kind) ev)))
  e)

(defun %check-evidence (kind evidence)
  "[κριτής Π2-Π4 #12] Η ΜΙΑ έδρα ελέγχου evidence κατά το schema του kind
   (μητρώο /2): απαιτείται plist με ≥1 από τα επιτρεπτά keys. ΔΗΛΩΜΕΝΟ
   όριο: πλήρης τυποποίηση τιμών/ξένων keys στο Π5 (verifier-level)."
  (let ((allowed (getf (instrument-kind-entry kind) :evidence)))
    (unless (and (consp evidence) (some (lambda (k) (getf evidence k)) allowed))
      (error 'invalid-condition
             :reason (format nil "evidence ~S εκτός/χωρίς schema ~S του kind ~S — καμία ικανοποίηση χωρίς τεκμήριο"
                             evidence allowed kind)))
    evidence))

(defun %sat-instrument (kind ref live-events condition-id)
  "Το αποτέλεσμα για (:instrument-event KIND REF): από το ΜΟΝΑΔΙΚΟ live
   γεγονός που ταιριάζει. [Φ6γ-Δ³] Με CONDITION-ID: μετρούν ΜΟΝΟ events
   ρητά δεμένα στο ΙΔΙΟ condition-id — event άλλης δήλωσης με ίδιο kind/ref
   δεν διαρρέει· event ΧΩΡΙΣ :condition-id σε cid-scoped αποτίμηση ⇒ ΣΦΑΛΜΑ.
   Πολλαπλά ΣΥΜΦΩΝΑ ⇒ ΕΛΑΧΙΣΤΟ at (spec §3.3β)· αντιφατικά ⇒ ΣΦΑΛΜΑ."
  (let ((hits (remove-if-not
               (lambda (e)
                 (and (eq (getf e :kind) kind)
                      (equal (getf e :ref) ref)
                      (or (null condition-id)
                          (progn
                            (unless (getf e :condition-id)
                              (error 'invalid-condition
                                     :reason (format nil "event χωρίς :condition-id σε cid-scoped αποτίμηση: ~S" e)))
                            (equal (getf e :condition-id) condition-id)))))
               live-events)))
    (cond ((null hits) (values :pending nil))
          ((let ((o (getf (first hits) :outcome)))
             (every (lambda (h) (eq (getf h :outcome) o)) (rest hits)))
           (values (getf (first hits) :outcome)
                   (reduce (lambda (a b) (if (%time<= a b) a b))
                           (mapcar (lambda (h) (getf h :at)) hits))))
          (t (error 'invalid-condition
                    :reason (format nil "~D αντιφατικά live γεγονότα για ~S ~S — επίλυση ΜΟΝΟ με journaled retract+τεκμήριο (spec §3.3β)"
                                    (length hits) kind ref))))))

(defun sat (ast live-events &key condition-id)
  "(values :pending|:satisfied|:refuted at-ή-nil) — ολική, ντετερμινιστική.
   :or ⇒ ικανοποίηση με το ΕΛΑΧΙΣΤΟ at· :and ⇒ με το ΜΕΓΙΣΤΟ at· refuted
   κανόνες κατά spec §1.2. [Φ6γ-Δ³] ΚΑΘΕ event επικυρώνεται typed πριν την
   αποτίμηση· με CONDITION-ID τα events δένονται δομικά στη δήλωση."
  (mapc #'%validate-condition-event live-events)
  ;; [κριτής A#9] Η μείξη είναι ΣΦΑΛΜΑ και προς τις δύο κατευθύνσεις:
  ;; σε ΜΗ-scoped αποτίμηση, event που φέρει :condition-id απορρίπτεται —
  ;; scoped δεδομένα δεν «μετράνε» ποτέ σιωπηλά εκτός του cid τους. Η
  ;; παραγωγική είσοδος (Π2 condition-status) είναι ΠΑΝΤΑ cid-scoped.
  (when (null condition-id)
    (dolist (e live-events)
      (when (getf e :condition-id)
        (error 'invalid-condition
               :reason (format nil "event με :condition-id σε ΜΗ-scoped αποτίμηση: ~S — δώσε :condition-id στο sat ή αφαίρεσε το πεδίο" e)))))
  (%sat-1 ast live-events condition-id))

(defun %sat-1 (ast live-events condition-id)
  (ecase (first ast)
    (:date-reached (values :satisfied (second ast)))
    (:instrument-event (%sat-instrument (second ast) (third ast) live-events condition-id))
    (:after
     (multiple-value-bind (st at) (%sat-1 (third ast) live-events condition-id)
       (if (eq st :satisfied)
           (values :satisfied (date+ at (second ast)))
           (values st at))))
    (:and
     (let ((results (mapcar (lambda (c) (multiple-value-list (%sat-1 c live-events condition-id)))
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
     (let ((results (mapcar (lambda (c) (multiple-value-list (%sat-1 c live-events condition-id)))
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

;;; ============================================================================
;;; [0088 Φ7 Π2] CONDITION RECORDS — διτεμπορικά, ΚΑΜΙΑ αποθηκευμένη κατάσταση
;;; Spec v3 §3: declare-before-reference, (kind,ref)⊆canon-AST πειθαρχία,
;;; evidence ΥΠΟΧΡΕΩΤΙΚΟ κατά μητρώο /2, retract κατά G5, condition-status =
;;; sat(canon-AST, events live κατά known-at) cid-scoped — ποτέ κατάσταση.
;;; ============================================================================

(defstruct (condition-event (:conc-name ce-))
  event-id       ; semantic hash (βλ. %condition-event-hash)
  condition-id   ; η δήλωση στην οποία είναι ΔΕΜΕΝΟ
  kind ref       ; instrument (kind ∈ μητρώο /2, ref = προσδιοριστής)
  outcome        ; :satisfied | :refuted
  at             ; legal-date — ΠΟΤΕ συνέβη νομικά
  evidence       ; plist κατά το evidence schema του kind
  verifier       ; string | NIL
  recorded-from  ; legal-instant — πότε το έμαθε το σύστημα (line :at)
  recorded-until); :current | legal-instant (G5 retract)

(defun %evidence-digest (evidence)
  (orchestrator.journal:sha256-hex
   (with-output-to-string (out) (%canon-sexp evidence out))))

(defun %condition-event-hash (cid kind ref outcome at evidence-digest)
  "Semantic ταυτότητα event (spec §3.3β): ίδια πεδία ⇒ ΙΔΙΟ γεγονός."
  (orchestrator.journal:sha256-hex
   (with-output-to-string (out)
     (%canon-sexp (list :lawmax/condition-event/1
                        cid kind ref outcome at evidence-digest)
                  out))))

(defun graph-condition (graph cid)
  "Η δηλωμένη αίρεση CID ή NIL."
  (gethash cid (vg-conditions graph)))

(defun graph-condition-events (graph cid)
  "ΟΛΑ τα events του CID (και τα διτεμπορικά κλεισμένα)."
  (gethash cid (vg-cond-events graph)))

(defun %ast-instrument-nodes (ast)
  "Τα (kind . ref) ζεύγη ΟΛΩΝ των :instrument-event κόμβων του AST."
  (ecase (first ast)
    (:date-reached '())
    (:instrument-event (list (cons (second ast) (third ast))))
    (:after (%ast-instrument-nodes (third ast)))
    ((:and :or) (loop for c in (rest ast) append (%ast-instrument-nodes c)))))

(defun declare-condition! (graph condition)
  "Journal της δήλωσης αίρεσης (kind :condition-declared, record-id =
   condition-id, journaled ast = ΚΑΝΟΝΙΚΟ — spec §3.1). Ιδεμποτής: ήδη
   δηλωμένο ίδιο cid ⇒ επιστρέφεται το υπάρχον χωρίς νέα γραμμή."
  (check-type condition effectivity-condition)
  (let ((cid (condition-id condition)))
    (or (gethash cid (vg-conditions graph))
        (progn
          (%journal! graph (list :kind :condition-declared
                                 :record-id cid
                                 :class (condition-class condition)
                                 :ast (condition-ast condition)
                                 :at (orchestrator.journal:iso-now)))
          (setf (gethash cid (vg-conditions graph)) condition)))))

(defun record-condition-event! (graph cid &key kind ref outcome at evidence verifier)
  "Διτεμπορική καταγραφή θεσμικού γεγονότος ΔΕΜΕΝΟΥ στη δήλωση CID.
   Fail-closed πύλες (spec §3.2): (α) declare-before-reference — αδήλωτο
   cid ⇒ ΣΦΑΛΜΑ· (β) το (KIND,REF) πρέπει να ΥΠΑΡΧΕΙ ως :instrument-event
   κόμβος στο canon AST της δήλωσης — ορθογραφική απόκλιση δεν γίνεται
   σιωπηλό αιώνιο :pending· (γ) OUTCOME ∈ {:satisfied :refuted}, AT
   legal-date· (δ) EVIDENCE ΥΠΟΧΡΕΩΤΙΚΟ κατά το evidence schema του kind
   στο μητρώο /2 (unverified_satisfactions=0). Ιδεμποτής στο ίδιο event-id
   όσο το event είναι live. recorded-from = το :at της γραμμής journal."
  (let ((cond (or (gethash cid (vg-conditions graph))
                  (error 'invalid-condition
                         :reason (format nil "αδήλωτο condition-id ~A — declare-before-reference" cid)))))
    (unless (member (cons kind ref) (%ast-instrument-nodes (condition-ast cond))
                    :test #'equal)
      (error 'invalid-condition
             :reason (format nil "(~S ~S) δεν υπάρχει ως :instrument-event κόμβος στη δήλωση ~A — απόκλιση από το AST δεν καταγράφεται" kind ref cid)))
    (unless (member outcome '(:satisfied :refuted))
      (error 'invalid-condition :reason (format nil "άκυρο outcome ~S" outcome)))
    (unless (legal-date-p at)
      (error 'invalid-condition :reason (format nil "άκυρο event at ~S — απαιτείται legal-date" at)))
    (%check-evidence kind evidence)
    (let* ((eid (%condition-event-hash cid kind ref outcome at (%evidence-digest evidence)))
           (live (find-if (lambda (e) (and (equal (ce-event-id e) eid)
                                           (eq (ce-recorded-until e) :current)))
                          (gethash cid (vg-cond-events graph)))))
      (or live
          (let* ((line (%journal! graph (list :kind :condition-event
                                              :record-id eid
                                              :condition-id cid
                                              :ikind kind :ref ref
                                              :outcome outcome :event-at at
                                              :evidence evidence
                                              :verifier verifier
                                              :at (orchestrator.journal:iso-now))))
                 (ce (make-condition-event
                      :event-id eid :condition-id cid :kind kind :ref ref
                      :outcome outcome :at at :evidence evidence
                      :verifier verifier
                      :recorded-from (%recorded-of line)
                      :recorded-until :current)))
            (push ce (gethash cid (vg-cond-events graph)))
            ce)))))

(defun retract-condition-event! (graph event-id)
  "G5 πρότυπο: κλείνει το recorded-until του LIVE event — η «απο-ικανοποίηση»
   υπάρχει ΜΟΝΟ ως προς μεταγενέστερο known-at· κάθε παλαιό snapshot μένει
   αναλλοίωτο. Ανύπαρκτο/ήδη κλεισμένο event ⇒ ΣΦΑΛΜΑ (spec §3.3)."
  (let ((ce (loop for events being the hash-values of (vg-cond-events graph)
                  thereis (find-if (lambda (e)
                                     (and (equal (ce-event-id e) event-id)
                                          (eq (ce-recorded-until e) :current)))
                                   events))))
    (unless ce
      (error 'invalid-condition
             :reason (format nil "retract ανύπαρκτου/κλεισμένου event ~A" event-id)))
    (let ((line (%journal! graph (list :kind :condition-event-retract
                                       :record-id (format nil "ce-retract:~A" event-id)
                                       :event event-id
                                       :at (orchestrator.journal:iso-now)))))
      (setf (ce-recorded-until ce) (%recorded-of line))
      ce)))

(defun %ce-live-p (ce known-at)
  "Υ2 πύλη — μέσω της ΜΙΑΣ liveness έδρας."
  (%live-at-p (ce-recorded-from ce) (ce-recorded-until ce) known-at))

(defun condition-status (graph cid &key known-at)
  "(values :pending|:satisfied|:refuted at-ή-nil) — Η ΜΙΑ είσοδος ερώτησης
   κατάστασης αίρεσης: ΚΑΜΙΑ αποθηκευμένη κατάσταση, ΠΑΝΤΑ sat πάνω στα
   events live κατά KNOWN-AT (Υ2), cid-scoped (spec §3.4). KNOWN-AT:
   ΥΠΟΧΡΕΩΤΙΚΟ legal-instant — ποτέ σιωπηλό «τώρα»."
  (unless (legal-instant-p known-at)
    (error 'invalid-condition
           :reason (format nil "condition-status: άκυρο known-at ~S — απαιτείται legal-instant (UTC Z)" known-at)))
  (let ((cond (or (gethash cid (vg-conditions graph))
                  (error 'invalid-condition
                         :reason (format nil "αδήλωτο condition-id ~A" cid)))))
    (sat (condition-ast cond)
         (loop for ce in (gethash cid (vg-cond-events graph))
               when (%ce-live-p ce known-at)
                 collect (list :condition-id (ce-condition-id ce)
                               :kind (ce-kind ce) :ref (ce-ref ce)
                               :outcome (ce-outcome ce) :at (ce-at ce)
                               :evidence (ce-evidence ce)))
         :condition-id cid)))

;;; ============================================================================
;;; [0088 Φ7 Π4] REGIME EDGES + ALLEN ΕΔΡΑ + Υ2β — spec v3 §5
;;; Καθεστωτικές πράξεις (αναστολή/παράταση/λήξη/επαναφορά/αναδρομή) ως
;;; ΞΕΧΩΡΙΣΤΟΣ τύπος (όχι υπότυπος amendment-edge), διτεμπορικές, journaled.
;;; ============================================================================

;;; ── Allen άλγεβρα: Η ΜΙΑ έδρα σχέσεων typed διαστημάτων [from, until|:open) ──

(defun %ikey (x what)
  (if (eq x :open) most-positive-fixnum (%time-key x what)))

(defun interval-relation (a-from a-until b-from b-until)
  "Η ΜΙΑ από τις 13 Allen σχέσεις των [A-FROM, A-UNTIL) και [B-FROM, B-UNTIL)
   (:open = +∞) — ολική, ντετερμινιστική, σε %time-key ακέραιους (spec §5)."
  (let ((a- (%ikey a-from "a-from")) (a+ (%ikey a-until "a-until"))
        (b- (%ikey b-from "b-from")) (b+ (%ikey b-until "b-until")))
    (when (or (>= a- a+) (>= b- b+))
      (error 'invalid-edge
             :reason "interval-relation: κενό/ανεστραμμένο διάστημα — οι 13 σχέσεις ορίζονται μόνο σε μη κενά [from, until)"))
    (cond
      ((and (= a- b-) (= a+ b+)) :equals)
      ((< a+ b-) :before)
      ((> a- b+) :after)
      ((= a+ b-) :meets)
      ((= b+ a-) :met-by)
      ((and (= a- b-) (< a+ b+)) :starts)
      ((and (= a- b-) (> a+ b+)) :started-by)
      ((and (= a+ b+) (> a- b-)) :finishes)
      ((and (= a+ b+) (< a- b-)) :finished-by)
      ((and (> a- b-) (< a+ b+)) :during)
      ((and (< a- b-) (> a+ b+)) :contains)
      ((and (< a- b-) (< b- a+) (< a+ b+)) :overlaps)
      ((and (< b- a-) (< a- b+) (< b+ a+)) :overlapped-by)
      (t (error 'invalid-edge :reason "αδύνατη Allen περίπτωση — μη ολικό κλειδί")))))

(defun interval-intersects-p (a-from a-until b-from b-until)
  (not (member (interval-relation a-from a-until b-from b-until)
               '(:before :after :meets :met-by))))

(defun interval-covers-p (from until at)
  "T ανν AT ∈ [FROM, UNTIL|:open)."
  (and (%time<= from at "from" "at")
       (or (eq until :open)
           (< (%time-key at "at") (%time-key until "until")))))

;;; ── Regime edge — typed, διτεμπορικό ──

(defparameter +regime-ops+ '(:suspend :extend :expire :revive :retroact))

(defstruct (regime-edge (:conc-name re-))
  edge-id
  op             ; ∈ +regime-ops+
  target         ; provision-id-string
  version        ; version-hash | NIL — ΥΠΟΧΡΕΩΤΙΚΟ για :extend/:expire/:retroact
  span-from      ; legal-date | :on-satisfaction [#3] — το τελευταίο ΜΟΝΟ με
                 ; :resolutory condition-id (η αφετηρία ΠΑΡΑΓΕΤΑΙ από το sat)
  span-until     ; legal-date | :open — για rewrites: το ΝΕΟ valid-until
  scope          ; [#2] canonical scope-set | NIL(=καθολική) — έδρα canon-scope-set
  condition-id   ; [#3] string | NIL — ΔΗΛΩΜΕΝΗ :resolutory αίρεση: η ακμή
                 ; ενεργοποιείται ΜΟΝΟ όταν sat(cid,known-at)=:satisfied
                 ; (first-class διαλυτική σημασιολογία — όχι πια placeholder)
  act-ref act-seq enacted fek-date
  prior-edge-id  ; ΥΠΟΧΡΕΩΤΙΚΟ για :revive — το suspend που αναιρεί
  recorded-from recorded-until)

(defun %regime-hash (op target version span-from span-until scope cid
                     act-ref act-seq enacted fek-date prior)
  (orchestrator.journal:sha256-hex
   (with-output-to-string (out)
     (%canon-sexp (list :lawmax/regime-edge/1 op target version
                        (if (eq span-from :on-satisfaction) "on-satisfaction" span-from)
                        (if (eq span-until :open) "open" span-until)
                        scope cid act-ref act-seq enacted fek-date prior)
                  out))))

(defun %re-live-p (re known-at)
  (%live-at-p (re-recorded-from re) (re-recorded-until re) known-at))

(defun %re-active-span (graph re known-at)
  "[#3] Η ΜΙΑ έδρα ενεργοποίησης regime edge: (values from until active-p).
   Χωρίς condition-id: το δηλωμένο span, πάντα ενεργό (εφόσον live).
   Με :resolutory condition-id: ενεργό ΜΟΝΟ όταν sat(cid,known-at) =
   :satisfied — και αν span-from = :on-satisfaction, from := το sat at
   (η αφετηρία ΠΑΡΑΓΕΤΑΙ, ποτέ δεν προϋπάρχει της ικανοποίησης)."
  (if (null (re-condition-id re))
      (values (re-span-from re) (re-span-until re) t)
      (multiple-value-bind (st at)
          (condition-status graph (re-condition-id re) :known-at known-at)
        (if (eq st :satisfied)
            (values (if (eq (re-span-from re) :on-satisfaction)
                        at (re-span-from re))
                    (re-span-until re) t)
            (values nil nil nil)))))

(defun %re-scope-applies-p (re scope-context)
  "[#2] Εφαρμογή scope στο ερώτημα: T (καλύπτει) ή :unknown (το πλαίσιο δεν
   δηλώνει τη διάσταση — υπερ-προσεκτικά ΕΦΑΡΜΟΖΕΤΑΙ και δηλώνεται μέσω του
   δεσμευμένου edge-id) ⇒ ισχύει· NIL (αποδεδειγμένα εκτός) ⇒ όχι."
  (not (null (scope-covers-p (re-scope re) scope-context))))

(defun graph-regimes (graph) (vg-regimes graph))

(defun %install-regime (graph re) (push re (vg-regimes graph)) re)

(defun admit-regime-edge! (graph &key op target version span-from span-until
                                      scope condition-id act-ref act-seq enacted
                                      fek-date prior-edge-id)
  "Εισδοχή καθεστωτικής πράξης — fail-closed πύλες (spec v3 §5):
   • op ∈ {:suspend :extend :expire :revive :retroact}·
   • span typed: [legal-date|:on-satisfaction, legal-date|:open) με from<until·
   • [#2] SCOPE: scope-set κατά μητρώο (canon-scope-set) — NIL = καθολική·
     δεσμεύεται στο hash/journal, εφαρμόζεται στο ερώτημα (scope-covers-p)·
   • [#3] CONDITION-ID: ΔΗΛΩΜΕΝΗ :resolutory αίρεση — η ακμή ενεργοποιείται
     ΜΟΝΟ όταν sat=:satisfied (first-class διαλυτική σημασιολογία)·
     span-from :on-satisfaction ⇒ η αφετηρία ΠΑΡΑΓΕΤΑΙ από το sat at
     (μόνο :suspend/:expire· για :expire απαιτείται span-until :open —
     η ισχύς λήγει ΣΤΟ σημείο ικανοποίησης)· suspensive αίρεση σε regime
     edge = invalid-edge (η αναβλητική ανήκει στο commencement — μία έδρα)·
   • :extend/:expire/:retroact ⇒ ΥΠΟΧΡΕΩΤΙΚΟ υπάρχον VERSION (τα όρια
     ξαναγράφονται ΔΙΤΕΜΠΟΡΙΚΑ — ορατά μόνο από known-at ≥ recorded)·
   • :revive ⇒ ΥΠΟΧΡΕΩΤΙΚΟ PRIOR-EDGE-ID: live :suspend ΙΔΙΟΥ target με
     ΤΕΜΝΟΝ span (revive χωρίς τι να αναιρέσει = σφάλμα)· revive
     conditional suspend = ΔΗΛΩΜΕΝΟ όριο (επίλυση με retract)·
   • σύγκρουση: live ίδιου op/target/version με ΤΕΜΝΟΝΤΑ spans και
     ΔΙΑΦΟΡΕΤΙΚΑ όρια ⇒ invalid-edge — επίλυση ΜΟΝΟ με journaled retract."
  (unless (member op +regime-ops+)
    (error 'invalid-edge :reason (format nil "άγνωστο regime op ~S" op)))
  (setf scope (canon-scope-set scope))
  (cond
    ((eq span-from :on-satisfaction)
     (unless condition-id
       (error 'invalid-edge :reason ":on-satisfaction span-from ΧΩΡΙΣ condition-id — η αφετηρία παράγεται από το sat ΔΗΛΩΜΕΝΗΣ αίρεσης"))
     (unless (member op '(:suspend :expire))
       (error 'invalid-edge :reason (format nil ":on-satisfaction επιτρέπεται μόνο σε :suspend/:expire — όχι ~S" op)))
     (when (and (eq op :expire) (not (eq span-until :open)))
       (error 'invalid-edge :reason ":expire :on-satisfaction απαιτεί span-until :open — η λήξη ΕΙΝΑΙ το σημείο ικανοποίησης")))
    (t (%require-date span-from "regime span-from")))
  (unless (or (eq span-until :open) (legal-date-p span-until))
    (error 'invalid-edge :reason (format nil "regime span-until: legal-date ή :open, όχι ~S" span-until)))
  (when (and (legal-date-p span-until) (legal-date-p span-from)
             (not (< (%time-key span-from "span-from")
                     (%time-key span-until "span-until"))))
    (error 'invalid-edge :reason "regime span: απαιτείται from < until — κενό/ανεστραμμένο διάστημα δεν είναι καθεστωτική πράξη"))
  (unless (or (integerp act-seq)
              (and (consp act-seq) (= 2 (length act-seq)) (every #'integerp act-seq)))
    (error 'invalid-edge :reason "regime act-seq: integer ή (άρθρο σειρά) integers"))
  (%require-date enacted "regime enacted") (%require-date fek-date "regime fek-date")
  (unless (and (stringp act-ref) (plusp (length act-ref)))
    (error 'invalid-edge :reason "regime act-ref: μη κενό string"))
  (when (member op '(:extend :expire :retroact))
    (unless (and version (gethash version (vg-versions graph)))
      (error 'invalid-edge
             :reason (format nil "~S απαιτεί ΥΠΑΡΧΟΝ version-hash στόχο — βρέθηκε ~S" op version))))
  (when condition-id
    (let ((c (graph-condition graph condition-id)))
      (unless c
        (error 'invalid-edge
               :reason (format nil "regime edge με ΑΔΗΛΩΤΟ condition-id ~A" condition-id)))
      ;; [#3] regime edges ΚΛΕΙΝΟΥΝ/περιορίζουν ισχύ ⇒ μόνο :resolutory·
      ;; η αναβλητική (suspensive) ανήκει στο commencement — ΜΙΑ έδρα ανά ρόλο.
      (unless (eq (condition-class c) :resolutory)
        (error 'invalid-edge
               :reason (format nil "regime edge με ~S αίρεση — μόνο :resolutory εδώ (η suspensive είναι commencement, όχι καθεστώς)"
                               (condition-class c))))))
  (when (eq op :revive)
    (let ((prior (find-if (lambda (re)
                            (and (equal (re-edge-id re) prior-edge-id)
                                 (eq (re-op re) :suspend)
                                 (equal (re-target re) target)
                                 (eq (re-recorded-until re) :current)))
                          (vg-regimes graph))))
      (unless prior
        (error 'invalid-edge
               :reason (format nil ":revive απαιτεί prior-edge-id live :suspend του ίδιου target — ~S δεν βρέθηκε" prior-edge-id)))
      ;; [#3] revive conditional suspend = ΔΗΛΩΜΕΝΟ όριο: η αφετηρία του
      ;; prior δεν είναι συγκρίσιμη πριν το sat — επίλυση με retract.
      (when (eq (re-span-from prior) :on-satisfaction)
        (error 'invalid-edge
               :reason ":revive πάνω σε conditional (:on-satisfaction) suspend — ΔΗΛΩΜΕΝΟ όριο: retract-regime-edge! αντί revive"))
      (when (eq span-from :on-satisfaction)
        (error 'invalid-edge :reason ":revive με :on-satisfaction span — μη υποστηριζόμενο"))
      (unless (interval-intersects-p span-from span-until
                                     (re-span-from prior) (re-span-until prior))
        (error 'invalid-edge
               :reason ":revive span ΔΕΝ τέμνει το span του suspend που αναιρεί"))))
  ;; σύγκρουση live ίδιου op/target/version — spans συγκρίσιμα ΜΟΝΟ όταν
  ;; και τα δύο έχουν συγκεκριμένη αφετηρία ([#3]: conditional edges με
  ;; ταυτόσημα πεδία συμπίπτουν σε eid — το live-dedup τα πιάνει).
  (dolist (re (vg-regimes graph))
    (when (and (eq (re-op re) op)
               (equal (re-target re) target)
               (equal (re-version re) version)
               (eq (re-recorded-until re) :current)
               (legal-date-p span-from)
               (legal-date-p (re-span-from re))
               (interval-intersects-p span-from span-until
                                      (re-span-from re) (re-span-until re))
               (not (and (equal (re-span-from re) span-from)
                         (equal (re-span-until re) span-until))))
      (error 'invalid-edge
             :reason (format nil "συγκρουόμενο live ~S στο ~A με τέμνον span και διαφορετικά όρια (~A) — επίλυση ΜΟΝΟ με retract-regime-edge!"
                             op target (re-edge-id re)))))
  (let* ((eid (%regime-hash op target version span-from span-until scope
                            condition-id act-ref act-seq enacted fek-date prior-edge-id))
         (live (find-if (lambda (re) (and (equal (re-edge-id re) eid)
                                          (eq (re-recorded-until re) :current)))
                        (vg-regimes graph))))
    (or live
        (let ((line (%journal! graph (list :kind :regime-edge :record-id eid
                                           :op op :target target :version version
                                           :span-from span-from :span-until span-until
                                           :scope scope :condition-id condition-id
                                           :act-ref act-ref :act-seq act-seq
                                           :enacted enacted :fek-date fek-date
                                           :prior prior-edge-id
                                           :at (orchestrator.journal:iso-now)))))
          (%install-regime graph
                           (make-regime-edge
                            :edge-id eid :op op :target target :version version
                            :span-from span-from :span-until span-until
                            :scope scope
                            :condition-id condition-id :act-ref act-ref
                            :act-seq act-seq :enacted enacted :fek-date fek-date
                            :prior-edge-id prior-edge-id
                            :recorded-from (%recorded-of line)
                            :recorded-until :current))))))

(defun retract-regime-edge! (graph edge-id)
  "G5: κλείνει recorded-until live regime edge — ΝΕΑ γραμμή, καμία επανεγγραφή."
  (let ((re (find-if (lambda (r) (and (equal (re-edge-id r) edge-id)
                                      (eq (re-recorded-until r) :current)))
                     (vg-regimes graph))))
    (unless re
      (error 'invalid-edge
             :reason (format nil "retract ανύπαρκτου/κλεισμένου regime edge ~A" edge-id)))
    (let ((line (%journal! graph (list :kind :regime-retract
                                       :record-id (format nil "re-retract:~A" edge-id)
                                       :edge edge-id
                                       :at (orchestrator.journal:iso-now)))))
      (setf (re-recorded-until re) (%recorded-of line))
      re)))

(defun %active-suspension (graph pid valid-at known-at &optional scope-context)
  "Το live-κατά-known-at :suspend του PID που καλύπτει το VALID-AT και ΔΕΝ
   αναιρείται εκεί από live :revive — αλλιώς NIL. Γνωστή αναστολή = ΓΝΩΣΤΗ
   απάντηση (:suspended basis), ποτέ ψευδής αβεβαιότητα.
   [#2] scoped suspend εκτός πλαισίου (scope-covers-p = NIL) ΔΕΝ εφαρμόζεται·
   [#3] conditional suspend εφαρμόζεται μόνο ενεργό (sat-παραγόμενο span)."
  (find-if
   (lambda (s)
     (and (eq (re-op s) :suspend)
          (equal (re-target s) pid)
          (%re-live-p s known-at)
          (%re-scope-applies-p s scope-context)
          (multiple-value-bind (f u active) (%re-active-span graph s known-at)
            (and active (interval-covers-p f u valid-at)))
          (not (find-if (lambda (r)
                          (and (eq (re-op r) :revive)
                               (equal (re-prior-edge-id r) (re-edge-id s))
                               (%re-live-p r known-at)
                               (interval-covers-p (re-span-from r) (re-span-until r)
                                                  valid-at)))
                        (vg-regimes graph)))))
   (vg-regimes graph)))

(defun %rewritten-bounds (graph v known-at &optional scope-context)
  "(values valid-from valid-until) της έκδοσης V όπως ΓΝΩΡΙΖΟΝΤΑΝ κατά
   KNOWN-AT: live :extend/:expire ξαναγράφουν το until, live :retroact
   ξαναγράφει from ΚΑΙ until — διτεμπορικά (πριν την καταγραφή: τα παλαιά).
   Εφαρμογή σε χρονική σειρά καταγραφής (νεότερο υπερισχύει).
   [#1] Για conditional έκδοση η βάση from είναι NIL (τίμια: δεν υπάρχει
   ημερομηνία στην έδρα) — ο καλών παράγει το from από το sat.
   [#2] scoped rewrite εκτός πλαισίου ΔΕΝ εφαρμόζεται· [#3] conditional
   (:resolutory) rewrite εφαρμόζεται μόνο ενεργό — :expire :on-satisfaction
   κλείνει την ισχύ ΣΤΟ σημείο ικανοποίησης (until := sat at)."
  (let ((from (tv-valid-from v)) (until (tv-valid-until v)))
    (dolist (re (reverse (vg-regimes graph)))
      (when (and (re-version re)
                 (equal (re-version re) (tv-version-hash v))
                 (%re-live-p re known-at)
                 (%re-scope-applies-p re scope-context))
        (multiple-value-bind (f u active) (%re-active-span graph re known-at)
          (when active
            (case (re-op re)
              (:expire (setf until (if (eq (re-span-from re) :on-satisfaction) f u)))
              (:extend (setf until u))
              (:retroact (setf from f until u))
              (t nil))))))
    (values from until)))

;;; ============================================================================
;;; [0088 Φ7 Π5] EFFECTIVITY ATTESTATION — deterministic certificate (spec §6)
;;; ΚΑΝΕΝΑ online κλειδί: κάθε πεδίο επανυπολογίσιμο από το υπογεγραμμένο
;;; release root + τον journaled γράφο + τον canonical verifier — η αυθεντία
;;; είναι η ΑΝΑΠΑΡΑΓΩΓΙΜΟΤΗΤΑ, byte-wise.
;;; ============================================================================

(defun %pid-condition-states (graph pid known-at)
  "sat-καταστάσεις ΟΛΩΝ των αιρέσεων που αναφέρονται από live conditional
   εκδόσεις του PID — ταξινομημένες κατά cid (ντετερμινιστικά)."
  (let ((out '()))
    (dolist (v (gethash pid (vg-by-provision graph)))
      (let ((cid (%tv-conditional-cid v)))
        (when (and cid (%recorded-live-p v known-at)
                   (not (assoc cid out :test #'equal)))
          (multiple-value-bind (st at) (condition-status graph cid :known-at known-at)
            (push (list cid (string-downcase (symbol-name st)) (or at "")) out)))))
    (sort out #'string< :key #'first)))

(defun %pid-regime-ids (graph pid known-at)
  "Τα edge-ids των live-κατά-known-at regime edges του PID — ταξινομημένα."
  (sort (loop for re in (vg-regimes graph)
              when (and (equal (re-target re) pid) (%re-live-p re known-at))
                collect (re-edge-id re))
        #'string<))

(defun make-effectivity-attestation (graph pid &key valid-at known-at corpus-id
                                                    release-root receipt-id
                                                    verifier-hash)
  "[Π5] Deterministic effectivity certificate για την τομή (VALID-AT,
   KNOWN-AT): plist με :canonical (value-canonical string), :hash (sha256),
   :outcome (sum type — resolved(vhash) | no-version-in-force |
   not-yet-effective(cid since) | suspended(edge-id vhash) |
   uncertain(λόγος)) + όλα τα αγκυρωτικά πεδία. ΧΩΡΙΣ υπογραφή: ο verifier
   ΑΝΑΠΑΡΑΓΕΙ και συγκρίνει byte-wise — αγκύρωση στο release root κατά
   spec §6 (release-anchored ⇔ chain-head = census graph_root υπογεγραμμένου
   release· η κρίση αυτή γίνεται στον καταναλωτή/verifier με το log)."
  (let* ((outcome
           (handler-case
               (multiple-value-bind (v basis note)
                   (version-at graph pid :valid-at valid-at :known-at known-at)
                 (cond
                   ((and v (eq basis :complete)) (list "resolved" (tv-version-hash v)))
                   ((and v (consp basis) (eq (first basis) :suspended))
                    (list "suspended" (second basis) (tv-version-hash v)))
                   ((and v (consp basis) (eq (first basis) :not-yet-effective))
                    ;; η ΠΑΛΑΙΑ in-force + δηλωμένη επικείμενη: resolved με pending
                    (list "resolved" (tv-version-hash v)
                          "pending" (second basis) (third basis)))
                   ((null v)
                    (if (and (consp note) (eq (first note) :not-yet-effective))
                        (list "no-version-in-force" "pending" (second note) (third note))
                        (list "no-version-in-force")))
                   (t (error 'invalid-edge :reason "αδύνατη έκβαση version-at"))))
             (temporal-uncertainty (e)
               (list "uncertain" (uncertainty-why e)))))
         (payload (list :lawmax/attestation/1
                        (or corpus-id "") pid valid-at known-at
                        outcome
                        (%pid-condition-states graph pid known-at)
                        (%pid-regime-ids graph pid known-at)
                        (or receipt-id "") (or release-root "")
                        (vg-chain graph) (or verifier-hash "")))
         (canonical (with-output-to-string (out) (%canon-sexp payload out)))
         (hash (orchestrator.journal:sha256-hex canonical)))
    (list :protocol "lawmax/attestation/1"
          :corpus-id corpus-id :provision pid
          :valid-at valid-at :known-at known-at
          :outcome outcome
          :condition-states (%pid-condition-states graph pid known-at)
          :regime-edge-ids (%pid-regime-ids graph pid known-at)
          :receipt-id receipt-id :release-root release-root
          :graph-chain-head (vg-chain graph)
          :verifier-hash verifier-hash
          :canonical canonical :hash hash)))
