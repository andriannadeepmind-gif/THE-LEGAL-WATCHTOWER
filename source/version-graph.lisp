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
;;;;     chain-hash ανά γραμμή: sha256(prev-chain ‖ 0x1F ‖ record-id).
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
   #:legal-date #:legal-date-p
   #:text-version #:text-version-p #:amendment-edge #:amendment-edge-p
   #:quarantined-edge #:quarantined-edge-p #:knowledge-gap #:knowledge-gap-p
   #:temporal-uncertainty #:unknown-provision #:invalid-edge
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
   #:make-edge-spec #:make-version-spec))

(in-package :orchestrator.version-graph)

;;; ----------------------------------------------------------------------------
;;; Τύποι χρόνου — το NIL ΔΕΝ χωράει
;;; ----------------------------------------------------------------------------

(defun legal-date-p (x)
  "ISO ημερομηνία «YYYY-MM-DD» — αυστηρό σχήμα, τίποτα άλλο."
  (and (stringp x) (= 10 (length x))
       (char= #\- (char x 4)) (char= #\- (char x 7))
       (loop for i in '(0 1 2 3 5 6 8 9)
             always (digit-char-p (char x i)))))

(deftype legal-date () '(and string (satisfies legal-date-p)))

(define-condition invalid-edge (error)
  ((reason :initarg :reason :reader invalid-edge-reason))
  (:report (lambda (c s) (format s "Άκυρη ακμή: ~A" (invalid-edge-reason c)))))

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

(defun %chain-next (prev record-id)
  (orchestrator.journal:sha256-hex
   (format nil "~A~C~A" prev (code-char 31) record-id)))

(defun %journal! (graph plist &key (verify t))
  "Μία γραμμή στο journal της έδρας [0086]: chained-append + require-durable!.
   Με VERIFY (προεπιλογή) γίνεται και read-back επαλήθευση ανά γραμμή· σε
   ΜΑΖΙΚΟ import η ανά-γραμμή επανανάγνωση είναι O(n²) — εκεί VERIFY NIL και
   η αλήθεια επαληθεύεται στο τέλος με ΠΛΗΡΕΣ replay (verify-chain, O(n))."
  (let ((next-chain (%chain-next (vg-chain graph) (getf plist :record-id))))
    (multiple-value-bind (line receipt)
        (orchestrator.journal:chained-append
         (vg-path graph)
         (lambda (last)
           (declare (ignore last))
           (append plist (list :chain next-chain)))
         :verify verify)
      (orchestrator.journal:require-durable! receipt :version-graph)
      (setf (vg-chain graph) next-chain)
      line)))

(defun %recorded-of (line)
  (or (getf line :at) (orchestrator.journal:iso-now)))

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
        ;; journal: η ακμή + οι νέες εκδόσεις + το κλείσιμο της προηγούμενης
        (%journal! graph (list :kind :amendment-edge :record-id eid
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
                               :at (orchestrator.journal:iso-now)))
        (let ((edge (make-amendment-edge
                     :edge-id eid :op op :from-versions from :to-versions to-hashes
                     :target target :act-ref (getf espec :act-ref)
                     :act-internal-seq (getf espec :act-internal-seq)
                     :corrects-edge-id (getf espec :corrects-edge-id)
                     :source-span (getf espec :source-span)
                     :enacted (getf espec :enacted) :effective (getf espec :effective)
                     :fek-date (getf espec :fek-date)
                     :recorded-from (orchestrator.journal:iso-now)
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

(defun %ts<= (a b) (not (string> a b)))

(defun %recorded-live-p (v known-at)
  (and (%ts<= (tv-recorded-from v) known-at)
       (or (eq :current (tv-recorded-until v))
           (string> (tv-recorded-until v) known-at))))

(defun %valid-covers-p (v valid-at)
  (and (%ts<= (tv-valid-from v) valid-at)
       (or (eq :open (tv-valid-until v))
           (string> (tv-valid-until v) valid-at))))

(defun version-at (graph pid &key valid-at known-at)
  "Η έκδοση του PID που (α) ήταν ΓΝΩΣΤΗ στο σύστημα κατά KNOWN-AT και
   (β) ΙΣΧΥΕ κατά VALID-AT. ΚΑΙ ΤΑ ΔΥΟ ΥΠΟΧΡΕΩΤΙΚΑ — κανένα σιωπηλό τώρα.
   Καραντίνα/κενό γνώσης που τέμνει το ερώτημα ⇒ temporal-uncertainty (τίμια
   άγνοια)· άγνωστη διάταξη ⇒ unknown-provision."
  (%require-date valid-at "valid-at")
  (unless (stringp known-at)
    (error 'invalid-edge :reason "known-at υποχρεωτικό (ISO timestamp/ημερομηνία)"))
  (let ((records (gethash pid (vg-by-provision graph))))
    (unless records (error 'unknown-provision :provision pid))
    ;; ΚΑΡΑΝΤΙΝΑ που στοχεύει τη διάταξη = ΜΗ εφαρμοσμένη γνωστή αλλαγή ⇒ και
    ;; το ΤΡΕΧΟΝ κείμενο αναξιόπιστο — ολική αβεβαιότητα για τη διάταξη.
    (let ((q (find-if (lambda (q)
                        (let ((m (qe-edge q)))
                          (equal pid (getf m :target))))
                      (vg-quarantine graph))))
      (when q
        (error 'temporal-uncertainty :provision pid
               :why (format nil "ακμή σε καραντίνα (~A)" (qe-reason q)))))
    (let ((live (loop for v in records
                      when (and (%recorded-live-p v known-at)
                                (%valid-covers-p v valid-at))
                        collect v)))
      (cond
        ((= 1 (length live)) (values (first live) :complete))
        ((null live)
         ;; ΚΕΝΟ ΓΝΩΣΗΣ (text-less ιστορικό — π.χ. αναθεωρήσεις χωρίς κείμενο):
         ;; το ερώτημα πέφτει σε περίοδο που ΔΕΝ ανακατασκευάζεται ⇒ ΡΗΤΗ
         ;; αβεβαιότητα, όχι σιωπηλό «καμία έκδοση» (TEMP-01/TEMP-04 honesty).
         (let ((g (find pid (vg-gaps graph) :key #'kg-provision-id :test #'equal)))
           (if g
               (error 'temporal-uncertainty :provision pid
                      :why (format nil "δηλωμένο κενό γνώσης (~A ~A): το κείμενο της περιόδου δεν ανακατασκευάζεται από τις διαθέσιμες πηγές"
                                   (kg-kind g) (kg-effective g)))
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
   της chain-hash αλυσίδας γραμμή-προς-γραμμή. Σπασμένη αλυσίδα ⇒ ΣΦΑΛΜΑ."
  (let ((graph (make-graph body-string)))
    (dolist (line (orchestrator.journal:read-lines (vg-path graph)))
      (let* ((rid (getf line :record-id))
             (expect (%chain-next (vg-chain graph) rid)))
        (unless (equal expect (getf line :chain))
          (error 'invalid-edge
                 :reason (format nil "σπασμένη αλυσίδα στο ~A: περίμενα ~A βρήκα ~A"
                                 rid expect (getf line :chain))))
        (setf (vg-chain graph) expect)
        (ecase (getf line :kind)
          (:text-version
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
             (when v (setf (tv-recorded-until v) (%recorded-of line))))))))
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
