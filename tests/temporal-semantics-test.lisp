;;;; tests/temporal-semantics-test.lisp
;;;; ============================================================================
;;;; [0088 Φ7 Π1] FORMAL TEMPORAL SEMANTICS — πυρήνας: AST/μητρώο/date+/sat
;;;; Spec: deployment/LAWMAX-TEMPORAL-SEMANTICS-SPEC.md (v2). Κλειδώνει:
;;;; μονότονη γραμματική (ΧΩΡΙΣ :not/:unless), denotational sat (or=min,
;;;; and=max), date+ κατά ΑΚ 241-243 με δίσεκτα, ταυτότητα = value-canonical
;;;; hash, κλειστό μητρώο, ολικότητα (typed σφάλματα — ποτέ σιωπηλά).
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *ts-pass* 0)
(defvar *ts-fail* 0)

(defmacro ts-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *ts-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *ts-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *ts-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0088 Φ7 Π1] TEMPORAL SEMANTICS: AST · date+ · sat ──~%")

;;; ① Γραμματική & μητρώο — μονότονη, κλειστή, fail-closed
(ts-check "① έγκυρο AST: (:or (:instrument-event :ya …) (:after (:months 6) (:date-reached …)))"
          (orchestrator.version-graph:valid-condition-ast-p
           '(:or (:instrument-event :ya "ΥΑ-οικ.12345")
                 (:after (:months 6) (:date-reached "2026-01-15")))))
(ts-check "①β :not ΔΕΝ υπάρχει στη γραμματική (μονοτονία δομική, όχι φρουρημένη)"
          (handler-case
              (progn (orchestrator.version-graph:valid-condition-ast-p
                      '(:not (:date-reached "2026-01-01")))
                     nil)
            (error () t)))
(ts-check "①γ :instrument-event με KIND εκτός μητρώου ⇒ typed σφάλμα"
          (handler-case
              (progn (orchestrator.version-graph:valid-condition-ast-p
                      '(:instrument-event :τηλεγράφημα "x"))
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))
(ts-check "①δ :date-reached με άκυρη ημερομηνία (2026-02-30) ⇒ typed σφάλμα"
          (handler-case
              (progn (orchestrator.version-graph:valid-condition-ast-p
                      '(:date-reached "2026-02-30"))
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))
(ts-check "①ε μητρώο: κλειστό, φορτωμένο από data (περιέχει :ya και :ratification)"
          (let ((ks (orchestrator.version-graph:instrument-kinds)))
            (and (member :ya ks) (member :ratification ks))))

;;; ② Ταυτότητα — value-canonical, class-ευαίσθητη
(ts-check "② ίδιο (class,AST) ⇒ ΙΔΙΟ condition-id· άλλη κλάση ⇒ ΑΛΛΟ id"
          (let ((a (orchestrator.version-graph:make-effectivity-condition
                    :suspensive '(:date-reached "2027-01-01")))
                (b (orchestrator.version-graph:make-effectivity-condition
                    :suspensive '(:date-reached "2027-01-01")))
                (c (orchestrator.version-graph:make-effectivity-condition
                    :resolutory '(:date-reached "2027-01-01"))))
            (and (equal (orchestrator.version-graph:condition-id a)
                        (orchestrator.version-graph:condition-id b))
                 (not (equal (orchestrator.version-graph:condition-id a)
                             (orchestrator.version-graph:condition-id c))))))

;;; ②+ [Φ6γ-Δ³] ΣΗΜΑΣΙΟΛΟΓΙΚΗ ταυτότητα + typed μητρώο /2
(ts-check "②β semantic id: (:and A B) ≡ (:and B A) ≡ (:and A A B) ≡ (:and A (:and B C))-flatten"
          (let* ((a '(:date-reached "2027-01-01"))
                 (b '(:instrument-event :ya "ΥΑ-1"))
                 (c '(:date-reached "2028-06-30"))
                 (id (lambda (ast) (orchestrator.version-graph:condition-id
                                    (orchestrator.version-graph:make-effectivity-condition
                                     :suspensive ast)))))
            (and (equal (funcall id (list :and a b c)) (funcall id (list :and c b a)))
                 (equal (funcall id (list :and a b c)) (funcall id (list :and a a b c)))
                 (equal (funcall id (list :and a b c)) (funcall id (list :and a (list :and b c)))))))
(ts-check "②γ domain separation ΠΡΑΓΜΑΤΙΚΟ: id ≠ hash του ΠΡΟ-tag σχήματος (cons class ast) — αφαίρεση του tag ΘΑ έσπαγε το τεστ"
          (let* ((ast '(:date-reached "2027-01-01"))
                 (cond1 (orchestrator.version-graph:make-effectivity-condition
                         :suspensive ast))
                 (untagged (orchestrator.journal:sha256-hex
                            (with-output-to-string (out)
                              (orchestrator.version-graph::%canon-sexp
                               (cons :suspensive ast) out)))))
            (not (equal (orchestrator.version-graph:condition-id cond1) untagged))))
(ts-check "②δ μητρώο /2 TYPED: κάθε kind με authority-class + evidence schema"
          (let ((e (orchestrator.version-graph:instrument-kind-entry :ya)))
            (and (eq :ministerial (getf e :authority-class))
                 (member :source-digest (getf e :evidence)))))

;;; ③ date+ — ΑΚ 241-243, ολική, με δίσεκτα
(ts-check "③ :days απλό: 2026-01-15 + 10d = 2026-01-25"
          (equal "2026-01-25" (orchestrator.version-graph:date+ "2026-01-15" '(:days 10))))
(ts-check "③β :months αντίστοιχη ημερομηνία: 2026-01-15 + 1μ = 2026-02-15"
          (equal "2026-02-15" (orchestrator.version-graph:date+ "2026-01-15" '(:months 1))))
(ts-check "③γ 31/1 + 1μ ⇒ τελευταία του Φεβρουαρίου (28 το 2026, 29 το 2024)"
          (and (equal "2026-02-28" (orchestrator.version-graph:date+ "2026-01-31" '(:months 1)))
               (equal "2024-02-29" (orchestrator.version-graph:date+ "2024-01-31" '(:months 1)))))
(ts-check "③δ :months με αλλαγή έτους: 2026-11-30 + 3μ = 2027-02-28"
          (equal "2027-02-28" (orchestrator.version-graph:date+ "2026-11-30" '(:months 3))))
(ts-check "③ε :years με 29/2: 2024-02-29 + 1y = 2025-02-28"
          (equal "2025-02-28" (orchestrator.version-graph:date+ "2024-02-29" '(:years 1))))
(ts-check "③στ άκυρη είσοδος ⇒ typed σφάλμα (ολικότητα με σήμανση, όχι NIL)"
          (handler-case
              (progn (orchestrator.version-graph:date+ "2026-13-01" '(:days 1)) nil)
            (orchestrator.version-graph:invalid-condition () t)))

;;; ④ sat — denotational (spec §1.2)
(defparameter *ts-ev*
  '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-03-10")
    (:kind :ratification :ref "ΠΝΠ-2026" :outcome :refuted :at "2026-05-01")))

(ts-check "④ :date-reached ⇒ πάντα (:satisfied ημερομηνία)"
          (multiple-value-bind (st at)
              (orchestrator.version-graph:sat '(:date-reached "2026-06-01") '())
            (and (eq :satisfied st) (equal "2026-06-01" at))))
(ts-check "④β :instrument-event με live γεγονός ⇒ satisfied στο at του"
          (multiple-value-bind (st at)
              (orchestrator.version-graph:sat '(:instrument-event :ya "ΥΑ-1") *ts-ev*)
            (and (eq :satisfied st) (equal "2026-03-10" at))))
(ts-check "④γ :instrument-event χωρίς γεγονός ⇒ :pending (τίμια εκκρεμότητα)"
          (eq :pending (orchestrator.version-graph:sat '(:instrument-event :ya "ΥΑ-999") *ts-ev*)))
(ts-check "④δ :after πάνω σε satisfied: ΥΑ-1@2026-03-10 + 6μ ⇒ 2026-09-10"
          (multiple-value-bind (st at)
              (orchestrator.version-graph:sat
               '(:after (:months 6) (:instrument-event :ya "ΥΑ-1")) *ts-ev*)
            (and (eq :satisfied st) (equal "2026-09-10" at))))
(ts-check "④ε ΤΟ ΕΛΛΗΝΙΚΟ ΜΟΤΙΒΟ — «με ΥΑ ορίζεται η έναρξη· άλλως 6 μήνες από δημοσίευση»:
        :or ⇒ ΕΛΑΧΙΣΤΟ satisfied-at (η ΥΑ 2026-03-10 προηγείται του 2026-07-15)"
          (multiple-value-bind (st at)
              (orchestrator.version-graph:sat
               '(:or (:instrument-event :ya "ΥΑ-1")
                     (:after (:months 6) (:date-reached "2026-01-15")))
               *ts-ev*)
            (and (eq :satisfied st) (equal "2026-03-10" at))))
(ts-check "④στ :or χωρίς κανένα γεγονός: το :after σκέλος (πάνω σε date-reached) αρκεί ⇒ 2026-07-15"
          (multiple-value-bind (st at)
              (orchestrator.version-graph:sat
               '(:or (:instrument-event :ya "ΥΑ-999")
                     (:after (:months 6) (:date-reached "2026-01-15")))
               '())
            (and (eq :satisfied st) (equal "2026-07-15" at))))
(ts-check "④ζ :and ⇒ ΜΕΓΙΣΤΟ satisfied-at (2026-06-01 vs ΥΑ 2026-03-10 ⇒ 2026-06-01)"
          (multiple-value-bind (st at)
              (orchestrator.version-graph:sat
               '(:and (:date-reached "2026-06-01") (:instrument-event :ya "ΥΑ-1"))
               *ts-ev*)
            (and (eq :satisfied st) (equal "2026-06-01" at))))
(ts-check "④η :and με pending σκέλος ⇒ :pending (όχι μερική βεβαιότητα)"
          (eq :pending (orchestrator.version-graph:sat
                        '(:and (:date-reached "2026-06-01")
                               (:instrument-event :ya "ΥΑ-999"))
                        *ts-ev*)))
(ts-check "④θ refuted (ΠΝΠ μη κυρωθείσα) διαδίδεται: :and ⇒ :refuted"
          (eq :refuted (orchestrator.version-graph:sat
                        '(:and (:date-reached "2026-06-01")
                               (:instrument-event :ratification "ΠΝΠ-2026"))
                        *ts-ev*)))
(ts-check "④ι ΔΥΟ αντιφατικά live γεγονότα για το ίδιο (kind,ref) ⇒ ΣΦΑΛΜΑ — ποτέ σιωπηλή επιλογή"
          (handler-case
              (progn (orchestrator.version-graph:sat
                      '(:instrument-event :ya "ΥΑ-1")
                      '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-03-10")
                        (:kind :ya :ref "ΥΑ-1" :outcome :refuted :at "2026-04-01")))
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))

;;; ④+ [Φ6γ-Δ³] typed event validation + δέσιμο στο condition-id
(ts-check "④κ άκυρο event (outcome :maybe) ⇒ typed σφάλμα ΠΡΙΝ την αποτίμηση"
          (handler-case
              (progn (orchestrator.version-graph:sat
                      '(:instrument-event :ya "ΥΑ-1")
                      '((:kind :ya :ref "ΥΑ-1" :outcome :maybe :at "2026-03-10")))
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))
(ts-check "④λ cid-scoped: event ΑΛΛΗΣ δήλωσης (ίδιο kind/ref) ΔΕΝ διαρρέει"
          (eq :pending
              (orchestrator.version-graph:sat
               '(:instrument-event :ya "ΥΑ-1")
               '((:condition-id "cid-ΑΛΛΟ" :kind :ya :ref "ΥΑ-1"
                  :outcome :satisfied :at "2026-03-10"))
               :condition-id "cid-ΔΙΚΟ")))
(ts-check "④μ cid-scoped: ΔΕΜΕΝΟ event μετρά κανονικά"
          (multiple-value-bind (st at)
              (orchestrator.version-graph:sat
               '(:instrument-event :ya "ΥΑ-1")
               '((:condition-id "cid-ΔΙΚΟ" :kind :ya :ref "ΥΑ-1"
                  :outcome :satisfied :at "2026-03-10"))
               :condition-id "cid-ΔΙΚΟ")
            (and (eq :satisfied st) (equal "2026-03-10" at))))
(ts-check "④ν cid-scoped: event ΧΩΡΙΣ :condition-id ⇒ ΣΦΑΛΜΑ (όχι σιωπηλή χρήση)"
          (handler-case
              (progn (orchestrator.version-graph:sat
                      '(:instrument-event :ya "ΥΑ-1")
                      '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-03-10"))
                      :condition-id "cid-ΔΙΚΟ")
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))
(ts-check "④ξ ΣΥΜΦΩΝΑ πολλαπλά events ⇒ ΕΛΑΧΙΣΤΟ at (spec §3.3β — όχι σφάλμα)"
          (multiple-value-bind (st at)
              (orchestrator.version-graph:sat
               '(:instrument-event :ya "ΥΑ-1")
               '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-04-01")
                 (:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-03-10")))
            (and (eq :satisfied st) (equal "2026-03-10" at))))

(ts-check "④ο [A#9] ΜΗ-scoped αποτίμηση με cid-φέρον event ⇒ ΣΦΑΛΜΑ (μείξη απαγορεύεται αμφίδρομα)"
          (handler-case
              (progn (orchestrator.version-graph:sat
                      '(:instrument-event :ya "ΥΑ-1")
                      '((:condition-id "cid-x" :kind :ya :ref "ΥΑ-1"
                         :outcome :satisfied :at "2026-03-10")))
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))
(ts-check "④π [A#12] evidence ΕΚΤΟΣ schema μητρώου ⇒ ΣΦΑΛΜΑ (τα schemas ΕΠΙΒΑΛΛΟΝΤΑΙ)"
          (handler-case
              (progn (orchestrator.version-graph:sat
                      '(:instrument-event :ya "ΥΑ-1")
                      '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-03-10"
                         :evidence (:τηλεφωνημα "x"))))
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))
(ts-check "④ρ evidence ΕΝΤΟΣ schema (source-digest για :ya) ⇒ δεκτό"
          (eq :satisfied (orchestrator.version-graph:sat
                          '(:instrument-event :ya "ΥΑ-1")
                          '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied
                             :at "2026-03-10" :evidence (:source-digest "abc"))))))

;;; ⑤ Ντετερμινισμός sat (ίδια είσοδος ⇒ ίδια έξοδος — θεμέλιο replay/verifier)
(ts-check "⑤ sat ντετερμινιστικό σε σύνθετο AST"
          (let ((ast '(:or (:and (:instrument-event :ya "ΥΑ-1")
                                 (:after (:days 30) (:date-reached "2026-02-01")))
                           (:after (:years 1) (:date-reached "2026-01-01")))))
            (equal (multiple-value-list (orchestrator.version-graph:sat ast *ts-ev*))
                   (multiple-value-list (orchestrator.version-graph:sat ast *ts-ev*)))))

;;; ═══ [Φ7 Π2] CONDITION RECORDS — πραγματικό journal, διτεμπορικά ═══
(defparameter *ts-body*
  (orchestrator.identity:body-id-string
   (orchestrator.identity:make-body :gr :nomos :year 2020 :number 9997 :slug "ts-p2")))
(let ((p (orchestrator.version-graph::%graph-path *ts-body*)))
  (when (probe-file p) (delete-file p)))

(defparameter *ts-g* (orchestrator.version-graph::make-graph *ts-body*))
(defparameter *ts-ref* "ya-per:gr/nomos/2020/9997#art:1")
(defparameter *ts-cond*
  (orchestrator.version-graph:make-effectivity-condition
   :suspensive (list :instrument-event :ya *ts-ref*)))
(defparameter *ts-cid* (orchestrator.version-graph:condition-id *ts-cond*))

(ts-check "⑥ declare-condition!: journal + ιδεμποτής (2η κλήση = ίδιο αντικείμενο, καμία νέα γραμμή)"
          (let* ((c1 (orchestrator.version-graph:declare-condition! *ts-g* *ts-cond*))
                 (head1 (orchestrator.version-graph:graph-chain-head *ts-g*))
                 (c2 (orchestrator.version-graph:declare-condition! *ts-g* *ts-cond*)))
            (and (eq c1 c2)
                 (equal head1 (orchestrator.version-graph:graph-chain-head *ts-g*)))))
(ts-check "⑥β status ΠΡΙΝ από κάθε καταγραφή (παλαιό known-at) ⇒ :pending — τίμια εκκρεμότητα"
          (eq :pending (orchestrator.version-graph:condition-status
                        *ts-g* *ts-cid* :known-at "2020-01-01T00:00:00Z")))
(ts-check "⑥γ record-condition-event! με evidence κατά μητρώο ⇒ status ΜΕΤΑ ⇒ (:satisfied at)"
          (progn
            (orchestrator.version-graph:record-condition-event!
             *ts-g* *ts-cid* :kind :ya :ref *ts-ref* :outcome :satisfied
             :at "2026-03-10" :evidence '(:source-digest "sha256:abc") :verifier "ts")
            (multiple-value-bind (st at)
                (orchestrator.version-graph:condition-status
                 *ts-g* *ts-cid* :known-at "2030-01-01T00:00:00Z")
              (and (eq :satisfied st) (equal "2026-03-10" at)))))
(ts-check "⑥δ το ΠΑΛΑΙΟ snapshot μένει αναλλοίωτο: known-at πριν την καταγραφή ⇒ :pending (Υ2)"
          (eq :pending (orchestrator.version-graph:condition-status
                        *ts-g* *ts-cid* :known-at "2020-01-01T00:00:00Z")))

(ts-check "⑦ retract-condition-event! (G5) ⇒ μεταγενέστερο known-at ξανά :pending"
          (let ((eid (orchestrator.version-graph:ce-event-id
                      (first (orchestrator.version-graph:graph-condition-events
                              *ts-g* *ts-cid*)))))
            (orchestrator.version-graph:retract-condition-event! *ts-g* eid)
            (eq :pending (orchestrator.version-graph:condition-status
                          *ts-g* *ts-cid* :known-at "2030-01-01T00:00:00Z"))))

(ts-check "⑧ dangling cid ⇒ ΣΦΑΛΜΑ (declare-before-reference)"
          (handler-case
              (progn (orchestrator.version-graph:record-condition-event!
                      *ts-g* "cid-ανύπαρκτο" :kind :ya :ref "x" :outcome :satisfied
                      :at "2026-01-01" :evidence '(:source-digest "d"))
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))
(ts-check "⑧β (kind,ref) ΕΚΤΟΣ του canon AST της δήλωσης ⇒ ΣΦΑΛΜΑ (καμία σιωπηλή απόκλιση)"
          (handler-case
              (progn (orchestrator.version-graph:record-condition-event!
                      *ts-g* *ts-cid* :kind :ya :ref "ΑΛΛΟ-REF" :outcome :satisfied
                      :at "2026-01-01" :evidence '(:source-digest "d"))
                     nil)
            (orchestrator.version-graph:invalid-condition () t)))
(ts-check "⑧γ κενό/εκτός-schema evidence ⇒ ΣΦΑΛΜΑ (unverified_satisfactions=0)"
          (and (handler-case
                   (progn (orchestrator.version-graph:record-condition-event!
                           *ts-g* *ts-cid* :kind :ya :ref *ts-ref* :outcome :satisfied
                           :at "2026-01-01" :evidence nil)
                          nil)
                 (orchestrator.version-graph:invalid-condition () t))
               (handler-case
                   (progn (orchestrator.version-graph:record-condition-event!
                           *ts-g* *ts-cid* :kind :ya :ref *ts-ref* :outcome :satisfied
                           :at "2026-01-01" :evidence '(:σημειωμα "x"))
                          nil)
                 (orchestrator.version-graph:invalid-condition () t))))
(ts-check "⑧δ retract ανύπαρκτου event ⇒ ΣΦΑΛΜΑ"
          (handler-case
              (progn (orchestrator.version-graph:retract-condition-event! *ts-g* "eid-x") nil)
            (orchestrator.version-graph:invalid-condition () t)))

(ts-check "⑨ RESTART PARITY: φρέσκο load-graph ⇒ ίδια δήλωση, ίδια events (live≡replayed recorded-from), ίδιο status"
          (let* ((g2 (orchestrator.version-graph::load-graph *ts-body*))
                 (c2 (orchestrator.version-graph:graph-condition g2 *ts-cid*))
                 (e1 (first (orchestrator.version-graph:graph-condition-events *ts-g* *ts-cid*)))
                 (e2 (find (orchestrator.version-graph:ce-event-id e1)
                           (orchestrator.version-graph:graph-condition-events g2 *ts-cid*)
                           :key #'orchestrator.version-graph:ce-event-id :test #'equal)))
            (and c2 e2
                 (equal (orchestrator.version-graph:ce-recorded-from e1)
                        (orchestrator.version-graph:ce-recorded-from e2))
                 (equal (orchestrator.version-graph:ce-recorded-until e1)
                        (orchestrator.version-graph:ce-recorded-until e2))
                 (eq (orchestrator.version-graph:condition-status
                      g2 *ts-cid* :known-at "2030-01-01T00:00:00Z")
                     (orchestrator.version-graph:condition-status
                      *ts-g* *ts-cid* :known-at "2030-01-01T00:00:00Z")))))
(ts-check "⑨β TAMPER: αλλοίωση πεδίου condition-event ⇒ load-graph ΣΦΑΛΜΑ (φρέσκο path — η journal cache δεν κρύβει τίποτα)"
          (let* ((p (orchestrator.version-graph::%graph-path *ts-body*))
                 (tampered-body (orchestrator.identity:body-id-string
                                 (orchestrator.identity:make-body
                                  :gr :nomos :year 2020 :number 9996 :slug "ts-p2t")))
                 (p2 (orchestrator.version-graph::%graph-path tampered-body))
                 (original (with-open-file (s p :external-format :utf-8)
                             (let ((str (make-string (file-length s))))
                               (read-sequence str s) str))))
            (when (probe-file p2) (delete-file p2))
            (with-open-file (s p2 :direction :output :if-exists :supersede
                               :if-does-not-exist :create :external-format :utf-8)
              (write-string (substitute #\9 #\3 original :count 1
                                        :start (search "2026-03-10" original))
                            s))
            (handler-case
                (progn (orchestrator.version-graph::load-graph tampered-body) nil)
              (orchestrator.version-graph:journal-corruption () t))))

;;; ═══ [Φ7 Π3] CONDITIONAL ΑΚΜΕΣ — παράγωγο κλείσιμο, ποτέ ψευδής άγνοια ═══
(defparameter *ts-pid2* "gr/nomos/2020/9997#art:2")
(defparameter *ts-ref2* "ya-per:gr/nomos/2020/9997#art:2")
(defparameter *ts-cond2*
  (orchestrator.version-graph:declare-condition!
   *ts-g* (orchestrator.version-graph:make-effectivity-condition
           :suspensive (list :instrument-event :ya *ts-ref2*))))
(defparameter *ts-cid2* (orchestrator.version-graph:condition-id *ts-cond2*))
(defparameter *ts-old*
  (multiple-value-bind (edge vs)
      (orchestrator.version-graph::admit-edge!
       *ts-g* (list :op :insert :target *ts-pid2* :from-versions nil
                    :to-specs (list (list :provision-id *ts-pid2* :text "παλαιό κείμενο"
                                          :heading nil :valid-from "2026-01-01"
                                          :status :in-force :assurance :verified))
                    :act-ref "gr/nomos/2020/9997" :act-internal-seq 1
                    :enacted "2026-01-01" :effective "2026-01-01"
                    :fek-date "2026-01-01" :assurance :verified :confidence 100))
    (declare (ignore edge))
    (first vs)))

(ts-check "⑩ conditional ακμή: sum type δεκτό, typed :commencement to-spec, εγκατάσταση χωρίς close-validity"
          (multiple-value-bind (edge vs)
              (orchestrator.version-graph::admit-edge!
               *ts-g* (list :op :replace :target *ts-pid2*
                            :from-versions (list (orchestrator.version-graph::tv-version-hash *ts-old*))
                            :to-specs (list (list :provision-id *ts-pid2* :text "νέο κείμενο"
                                                  :heading nil
                                                  :commencement (list :conditional *ts-cid2*)
                                                  :status :not-yet-effective :assurance :verified))
                            :act-ref "gr/nomos/2026/0001" :act-internal-seq 1
                            :enacted "2026-02-01" :effective (list :conditional *ts-cid2*)
                            :fek-date "2026-02-01" :assurance :verified :confidence 100))
            (and edge (= 1 (length vs))
                 ;; η παλαιά ΔΕΝ έκλεισε journaled — μένει :open (παράγωγο κλείσιμο)
                 (eq :open (orchestrator.version-graph::tv-valid-until *ts-old*)))))
(ts-check "⑩β pending αίρεση ⇒ (παλαιά, (:not-yet-effective cid …)) — 200 με in_force σημασιολογία, ΟΧΙ 422 (false_uncertainty=0)"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid2* :valid-at "2026-06-01" :known-at "2030-01-01T00:00:00Z")
            (and v (equal "παλαιό κείμενο" (orchestrator.version-graph::tv-text v))
                 (consp basis) (eq :not-yet-effective (first basis))
                 (equal *ts-cid2* (second basis)))))
(ts-check "⑩γ ικανοποίηση (ΥΑ@2026-03-10) ⇒ ΙΔΙΟ valid-at, ΜΕΤΑ-known ⇒ η ΝΕΑ έκδοση :complete"
          (progn
            (orchestrator.version-graph:record-condition-event!
             *ts-g* *ts-cid2* :kind :ya :ref *ts-ref2* :outcome :satisfied
             :at "2026-03-10" :evidence '(:source-digest "sha256:ya2") :verifier "ts")
            (multiple-value-bind (v basis)
                (orchestrator.version-graph:version-at
                 *ts-g* *ts-pid2* :valid-at "2026-06-01" :known-at "2031-01-01T00:00:00Z")
              (and (eq basis :complete)
                   (equal "νέο κείμενο" (orchestrator.version-graph::tv-text v))))))
(ts-check "⑩δ χρονική αγκύρωση: valid-at ΠΡΙΝ το satisfied-at ⇒ η ΠΑΛΑΙΑ :complete (καμία αναδρομή)"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid2* :valid-at "2026-02-15" :known-at "2031-01-01T00:00:00Z")
            (and (eq basis :complete)
                 (equal "παλαιό κείμενο" (orchestrator.version-graph::tv-text v)))))
(ts-check "⑩ε Υ2: known-at ΠΡΙΝ την καταγραφή του event ⇒ ξανά (παλαιά, :not-yet-effective) — το παλαιό snapshot αμετάβλητο"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid2* :valid-at "2026-06-01" :known-at "2026-02-02T00:00:00Z")
            (declare (ignore v))
            ;; τα πάντα εδώ καταγράφηκαν «σήμερα» — σε τομή γνώσης πριν από
            ;; την καταγραφή της ακμής δεν υπάρχει καμία έκδοση (τίμιο)
            (or (eq basis :no-version-in-force)
                (and (consp basis) (eq :not-yet-effective (first basis))))))
(ts-check "⑩στ retract της ικανοποίησης ⇒ σε ΝΕΟΤΕΡΟ known-at ξανά (παλαιά, :not-yet-effective)"
          (let ((eid (orchestrator.version-graph:ce-event-id
                      (find :current (orchestrator.version-graph:graph-condition-events
                                      *ts-g* *ts-cid2*)
                            :key #'orchestrator.version-graph:ce-recorded-until))))
            (orchestrator.version-graph:retract-condition-event! *ts-g* eid)
            (multiple-value-bind (v basis)
                (orchestrator.version-graph:version-at
                 *ts-g* *ts-pid2* :valid-at "2026-06-01" :known-at "2032-01-01T00:00:00Z")
              (and v (equal "παλαιό κείμενο" (orchestrator.version-graph::tv-text v))
                   (consp basis) (eq :not-yet-effective (first basis))))))
(ts-check "⑩ζ conditional ακμή με ΑΔΗΛΩΤΟ cid ⇒ invalid-edge (declare-before-reference)"
          (handler-case
              (progn (orchestrator.version-graph::admit-edge!
                      *ts-g* (list :op :replace :target *ts-pid2*
                                   :from-versions (list (orchestrator.version-graph::tv-version-hash *ts-old*))
                                   :to-specs (list (list :provision-id *ts-pid2* :text "x"
                                                         :commencement '(:conditional "cid-x")
                                                         :status :not-yet-effective :assurance :verified))
                                   :act-ref "a" :act-internal-seq 1
                                   :enacted "2026-02-01" :effective '(:conditional "cid-x")
                                   :fek-date "2026-02-01" :assurance :verified :confidence 100))
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))
(ts-check "⑩η conditional ακμή με ΗΜΕΡΟΜΗΝΙΑ valid-from στο to-spec ⇒ invalid-edge (η ισχύς είναι ΠΑΡΑΓΩΓΗ)"
          (handler-case
              (progn (orchestrator.version-graph::admit-edge!
                      *ts-g* (list :op :replace :target *ts-pid2*
                                   :from-versions (list (orchestrator.version-graph::tv-version-hash *ts-old*))
                                   :to-specs (list (list :provision-id *ts-pid2* :text "x"
                                                         :valid-from "2026-05-01"
                                                         :status :not-yet-effective :assurance :verified))
                                   :act-ref "a" :act-internal-seq 1
                                   :enacted "2026-02-01" :effective (list :conditional *ts-cid2*)
                                   :fek-date "2026-02-01" :assurance :verified :confidence 100))
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))
(ts-check "⑩θ RESTART PARITY Π3: φρέσκο load-graph ⇒ ταυτόσημες απαντήσεις version-at στις ίδιες τομές"
          (let ((g2 (orchestrator.version-graph::load-graph *ts-body*)))
            (flet ((ans (g valid known)
                     (multiple-value-bind (v basis)
                         (orchestrator.version-graph:version-at g *ts-pid2*
                                                                :valid-at valid :known-at known)
                       (list (and v (orchestrator.version-graph::tv-text v))
                             (if (consp basis) (subseq basis 0 2) basis)))))
              (and (equal (ans *ts-g* "2026-06-01" "2032-01-01T00:00:00Z")
                          (ans g2 "2026-06-01" "2032-01-01T00:00:00Z"))
                   (equal (ans *ts-g* "2026-06-01" "2031-01-01T00:00:00Z")
                          (ans g2 "2026-06-01" "2031-01-01T00:00:00Z"))
                   (equal (ans *ts-g* "2026-02-15" "2031-01-01T00:00:00Z")
                          (ans g2 "2026-02-15" "2031-01-01T00:00:00Z"))))))

;;; ═══ [Φ7 Π4] ALLEN ΕΔΡΑ + REGIME EDGES + Υ2β ═══
(ts-check "⑪ Allen: και οι 13 σχέσεις σωστές σε typed [from, until|:open)"
          (flet ((rel (af au bf bu)
                   (orchestrator.version-graph:interval-relation af au bf bu)))
            (and (eq :equals       (rel "2026-01-01" "2026-06-01" "2026-01-01" "2026-06-01"))
                 (eq :before       (rel "2026-01-01" "2026-02-01" "2026-03-01" "2026-04-01"))
                 (eq :after        (rel "2026-03-01" "2026-04-01" "2026-01-01" "2026-02-01"))
                 (eq :meets        (rel "2026-01-01" "2026-02-01" "2026-02-01" "2026-03-01"))
                 (eq :met-by       (rel "2026-02-01" "2026-03-01" "2026-01-01" "2026-02-01"))
                 (eq :starts       (rel "2026-01-01" "2026-02-01" "2026-01-01" "2026-03-01"))
                 (eq :started-by   (rel "2026-01-01" "2026-03-01" "2026-01-01" "2026-02-01"))
                 (eq :finishes     (rel "2026-02-01" "2026-03-01" "2026-01-01" "2026-03-01"))
                 (eq :finished-by  (rel "2026-01-01" "2026-03-01" "2026-02-01" "2026-03-01"))
                 (eq :during       (rel "2026-02-01" "2026-03-01" "2026-01-01" "2026-04-01"))
                 (eq :contains     (rel "2026-01-01" "2026-04-01" "2026-02-01" "2026-03-01"))
                 (eq :overlaps     (rel "2026-01-01" "2026-03-01" "2026-02-01" "2026-04-01"))
                 (eq :overlapped-by(rel "2026-02-01" "2026-04-01" "2026-01-01" "2026-03-01"))
                 (eq :starts       (rel "2026-01-01" "2026-02-01" "2026-01-01" :open))
                 (orchestrator.version-graph:interval-covers-p "2026-01-01" :open "2030-01-01"))))

(defparameter *ts-susp*
  (orchestrator.version-graph:admit-regime-edge!
   *ts-g* :op :suspend :target *ts-pid2*
   :span-from "2026-04-01" :span-until "2026-05-01"
   :act-ref "gr/ya/2026/100" :act-seq 1 :enacted "2026-03-20" :fek-date "2026-03-20"))

(ts-check "⑫ suspend: τομή ΕΝΤΟΣ span ⇒ typed basis (:suspended eid) — γνωστή απάντηση, ΟΧΙ 422"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid2* :valid-at "2026-04-15" :known-at "2033-01-01T00:00:00Z")
            (and v (consp basis) (eq :suspended (first basis))
                 (equal (orchestrator.version-graph:re-edge-id *ts-susp*) (second basis)))))
(ts-check "⑫β εκτός span ⇒ κανονικό basis (χωρίς αναστολή)"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid2* :valid-at "2026-03-15" :known-at "2033-01-01T00:00:00Z")
            (declare (ignore v))
            (not (and (consp basis) (eq :suspended (first basis))))))
(ts-check "⑫γ Υ2: known-at ΠΡΙΝ την καταγραφή του suspend ⇒ καμία αναστολή στο παλαιό snapshot"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid2* :valid-at "2026-04-15" :known-at "2026-02-02T00:00:00Z")
            (declare (ignore v))
            (not (and (consp basis) (eq :suspended (first basis))))))
(ts-check "⑬ revive (prior=suspend, τέμνον span) ⇒ ξανά χωρίς αναστολή στο revive παράθυρο"
          (progn
            (orchestrator.version-graph:admit-regime-edge!
             *ts-g* :op :revive :target *ts-pid2*
             :span-from "2026-04-20" :span-until "2026-05-01"
             :act-ref "gr/ya/2026/101" :act-seq 1 :enacted "2026-04-18" :fek-date "2026-04-18"
             :prior-edge-id (orchestrator.version-graph:re-edge-id *ts-susp*))
            (multiple-value-bind (v basis)
                (orchestrator.version-graph:version-at
                 *ts-g* *ts-pid2* :valid-at "2026-04-25" :known-at "2033-01-01T00:00:00Z")
              (declare (ignore v))
              (not (and (consp basis) (eq :suspended (first basis)))))))
(ts-check "⑬β πριν το revive παράθυρο η αναστολή ΙΣΧΥΕΙ ακόμη"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid2* :valid-at "2026-04-10" :known-at "2033-01-01T00:00:00Z")
            (declare (ignore v))
            (and (consp basis) (eq :suspended (first basis)))))
(ts-check "⑬γ revive ΧΩΡΙΣ έγκυρο prior ⇒ invalid-edge"
          (handler-case
              (progn (orchestrator.version-graph:admit-regime-edge!
                      *ts-g* :op :revive :target *ts-pid2*
                      :span-from "2026-04-20" :span-until "2026-05-01"
                      :act-ref "a" :act-seq 1 :enacted "2026-04-18" :fek-date "2026-04-18"
                      :prior-edge-id "re-ανύπαρκτο")
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))
(ts-check "⑭ expire: διτεμπορική μετάθεση valid-until — μετά-known η κάλυψη σταματά στο νέο όριο"
          (progn
            (orchestrator.version-graph:admit-regime-edge!
             *ts-g* :op :expire :target *ts-pid2*
             :version (orchestrator.version-graph::tv-version-hash *ts-old*)
             :span-from "2026-01-01" :span-until "2026-08-01"
             :act-ref "gr/nomos/2026/0002" :act-seq 1 :enacted "2026-06-01" :fek-date "2026-06-01")
            (multiple-value-bind (v basis)
                (orchestrator.version-graph:version-at
                 *ts-g* *ts-pid2* :valid-at "2026-09-01" :known-at "2033-01-01T00:00:00Z")
              (and (null v) (eq basis :no-version-in-force)))))
(ts-check "⑭β retroact: νέο valid-from ορατό ΜΟΝΟ σε known-at ≥ καταγραφή (διτεμπορικά)"
          (progn
            (orchestrator.version-graph:admit-regime-edge!
             *ts-g* :op :retroact :target *ts-pid2*
             :version (orchestrator.version-graph::tv-version-hash *ts-old*)
             :span-from "2025-06-01" :span-until "2026-08-01"
             :act-ref "gr/nomos/2026/0003" :act-seq 1 :enacted "2026-06-15" :fek-date "2026-06-15")
            (and
             ;; μετά-known: καλύπτει και το 2025-08-01
             (multiple-value-bind (v basis)
                 (orchestrator.version-graph:version-at
                  *ts-g* *ts-pid2* :valid-at "2025-08-01" :known-at "2033-01-01T00:00:00Z")
               (declare (ignore basis))
               (and v (equal "παλαιό κείμενο" (orchestrator.version-graph::tv-text v))))
             ;; πριν-known: το 2025-08-01 ΔΕΝ καλυπτόταν
             (multiple-value-bind (v basis)
                 (orchestrator.version-graph:version-at
                  *ts-g* *ts-pid2* :valid-at "2025-08-01" :known-at "2026-02-02T00:00:00Z")
               (declare (ignore basis))
               (null v)))))
(ts-check "⑭γ [Γ] συγκρουόμενο live :suspend ίδιου target με τέμνον span + άλλα όρια ⇒ invalid-edge (τα :expire/:extend πλέον ΣΥΝΤΙΘΕΝΤΑΙ από την άλγεβρα min/max)"
          (handler-case
              (progn (orchestrator.version-graph:admit-regime-edge!
                      *ts-g* :op :suspend :target *ts-pid2*
                      :span-from "2026-03-15" :span-until "2026-05-15"
                      :act-ref "x" :act-seq 1 :enacted "2026-03-01" :fek-date "2026-03-01")
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))
(ts-check "⑮ Υ2β: gap με ΔΙΑΣΤΗΜΑ μπλοκάρει ΜΟΝΟ ακάλυπτες τομές ΕΝΤΟΣ του — εκτός: τίμιο :no-version-in-force, όχι μόλυνση"
          (let ((pid3 "gr/nomos/2020/9997#art:3"))
            ;; έκδοση που καλύπτει ΑΠΟ το 2023 — οι περίοδοι 2021/2022 ακάλυπτες
            (orchestrator.version-graph::admit-edge!
             *ts-g* (list :op :insert :target pid3 :from-versions nil
                          :to-specs (list (list :provision-id pid3 :text "τ3" :heading nil
                                                :valid-from "2023-01-01"
                                                :status :in-force :assurance :verified))
                          :act-ref "gr/nomos/2020/9997" :act-internal-seq 3
                          :enacted "2023-01-01" :effective "2023-01-01"
                          :fek-date "2023-01-01" :assurance :verified :confidence 100))
            (orchestrator.version-graph:add-knowledge-gap!
             *ts-g* :provision-id pid3 :act-ref "gr/nomos/2022/1111" :kind :text-less
             :effective "2022-01-01" :until "2023-01-01")
            (and
             ;; ακάλυπτη τομή ΕΝΤΟΣ [2022-01-01, 2023-01-01) ⇒ τίμια αβεβαιότητα
             (handler-case
                 (progn (orchestrator.version-graph:version-at
                         *ts-g* pid3 :valid-at "2022-06-01" :known-at "2033-01-01T00:00:00Z")
                        nil)
               (orchestrator.version-graph:temporal-uncertainty () t))
             ;; ακάλυπτη τομή ΕΚΤΟΣ διαστήματος ⇒ :no-version-in-force (το
             ;; κενό ΔΕΝ μολύνει όλη την ακάλυπτη ιστορία — αυτό είναι το Υ2β)
             (multiple-value-bind (v basis)
                 (orchestrator.version-graph:version-at
                  *ts-g* pid3 :valid-at "2021-06-01" :known-at "2033-01-01T00:00:00Z")
               (and (null v) (eq basis :no-version-in-force)))
             ;; καλυπτόμενη τομή ⇒ κανονική απάντηση
             (multiple-value-bind (v basis)
                 (orchestrator.version-graph:version-at
                  *ts-g* pid3 :valid-at "2024-06-01" :known-at "2033-01-01T00:00:00Z")
               (declare (ignore basis))
               (and v (equal "τ3" (orchestrator.version-graph::tv-text v)))))))
(ts-check "⑯ RESTART PARITY Π4: φρέσκο load-graph ⇒ ταυτόσημες απαντήσεις (suspend/revive/expire/retroact/gap)"
          (let ((g2 (orchestrator.version-graph::load-graph *ts-body*)))
            (flet ((ans (g pid valid known)
                     (handler-case
                         (multiple-value-bind (v basis)
                             (orchestrator.version-graph:version-at g pid :valid-at valid :known-at known)
                           (list (and v (orchestrator.version-graph::tv-text v))
                                 (if (consp basis) (first basis) basis)))
                       (orchestrator.version-graph:temporal-uncertainty () :uncertain))))
              (every (lambda (args)
                       (equal (apply #'ans *ts-g* args) (apply #'ans g2 args)))
                     (list (list *ts-pid2* "2026-04-15" "2033-01-01T00:00:00Z")
                           (list *ts-pid2* "2026-04-25" "2033-01-01T00:00:00Z")
                           (list *ts-pid2* "2026-09-01" "2033-01-01T00:00:00Z")
                           (list *ts-pid2* "2025-08-01" "2033-01-01T00:00:00Z")
                           (list "gr/nomos/2020/9997#art:3" "2022-06-01" "2033-01-01T00:00:00Z")
                           (list "gr/nomos/2020/9997#art:3" "2021-06-01" "2033-01-01T00:00:00Z"))))))
(ts-check "⑯β TAMPER regime-edge πεδίου ⇒ load-graph ΣΦΑΛΜΑ (φρέσκο path)"
          (let* ((p (orchestrator.version-graph::%graph-path *ts-body*))
                 (tb (orchestrator.identity:body-id-string
                      (orchestrator.identity:make-body :gr :nomos :year 2020 :number 9995 :slug "ts-p4t")))
                 (p2 (orchestrator.version-graph::%graph-path tb))
                 (original (with-open-file (s p :external-format :utf-8)
                             (let ((str (make-string (file-length s))))
                               (read-sequence str s) str)))
                 (pos (search "2026-04-01" original)))
            (when (probe-file p2) (delete-file p2))
            (with-open-file (s p2 :direction :output :if-exists :supersede
                               :if-does-not-exist :create :external-format :utf-8)
              (write-string (substitute #\9 #\4 original :count 1 :start pos) s))
            (handler-case
                (progn (orchestrator.version-graph::load-graph tb) nil)
              (orchestrator.version-graph:journal-corruption () t))))

;;; ═══ [Φ7 κριτής Π2-Π4] Locks των κλεισιμάτων — TILING σημασιολογία ═══
(defparameter *ts-pid4* "gr/nomos/2020/9997#art:4")
(defparameter *ts-ref4* "ya-per:gr/nomos/2020/9997#art:4")
(defparameter *ts-cond4*
  (orchestrator.version-graph:declare-condition!
   *ts-g* (orchestrator.version-graph:make-effectivity-condition
           :suspensive (list :instrument-event :ya *ts-ref4*))))
(defparameter *ts-cid4* (orchestrator.version-graph:condition-id *ts-cond4*))
;; αλυσίδα: v1 (2026-01-01) → conditional v2 → ΚΑΝΟΝΙΚΗ v3 (2026-05-01)
(defparameter *ts-v1*
  (multiple-value-bind (e vs)
      (orchestrator.version-graph::admit-edge!
       *ts-g* (list :op :insert :target *ts-pid4* :from-versions nil
                    :to-specs (list (list :provision-id *ts-pid4* :text "V1" :heading nil
                                          :valid-from "2026-01-01" :status :in-force
                                          :assurance :verified))
                    :act-ref "gr/nomos/2020/9997" :act-internal-seq 4
                    :enacted "2026-01-01" :effective "2026-01-01"
                    :fek-date "2026-01-01" :assurance :verified :confidence 100))
    (declare (ignore e)) (first vs)))
(defparameter *ts-v2*
  (multiple-value-bind (e vs)
      (orchestrator.version-graph::admit-edge!
       *ts-g* (list :op :replace :target *ts-pid4*
                    :from-versions (list (orchestrator.version-graph::tv-version-hash *ts-v1*))
                    :to-specs (list (list :provision-id *ts-pid4* :text "V2-COND" :heading nil
                                          :commencement (list :conditional *ts-cid4*)
                                          :status :not-yet-effective :assurance :verified))
                    :act-ref "gr/nomos/2026/0004" :act-internal-seq 1
                    :enacted "2026-02-01" :effective (list :conditional *ts-cid4*)
                    :fek-date "2026-02-01" :assurance :verified :confidence 100))
    (declare (ignore e)) (first vs)))
(defparameter *ts-v3*
  (multiple-value-bind (e vs)
      (orchestrator.version-graph::admit-edge!
       *ts-g* (list :op :replace :target *ts-pid4*
                    :from-versions (list (orchestrator.version-graph::tv-version-hash *ts-v2*))
                    :to-specs (list (list :provision-id *ts-pid4* :text "V3" :heading nil
                                          :valid-from "2026-05-01" :status :in-force
                                          :assurance :verified))
                    :act-ref "gr/nomos/2026/0005" :act-internal-seq 1
                    :enacted "2026-04-01" :effective "2026-05-01"
                    :fek-date "2026-04-01" :assurance :verified :confidence 100))
    (declare (ignore e)) (first vs)))

(ts-check "⑰ [#2] conditional+ΚΑΝΟΝΙΚΗ ακμή, αίρεση PENDING: v1 ψαλιδίζεται στο v3.from — ΚΑΜΙΑ ψευδο-επικάλυψη/422"
          (and (multiple-value-bind (v basis)
                   (orchestrator.version-graph:version-at
                    *ts-g* *ts-pid4* :valid-at "2026-06-01" :known-at "2033-01-01T00:00:00Z")
                 (declare (ignore basis))
                 (and v (equal "V3" (orchestrator.version-graph::tv-text v))))
               (multiple-value-bind (v basis)
                   (orchestrator.version-graph:version-at
                    *ts-g* *ts-pid4* :valid-at "2026-03-01" :known-at "2033-01-01T00:00:00Z")
                 (and v (equal "V1" (orchestrator.version-graph::tv-text v))
                      (consp basis) (eq :not-yet-effective (first basis))))))
(ts-check "⑰β [#1] αίρεση SATISFIED @2026-03-10: tiling — V1 έως 2026-03-10, V2 έως 2026-05-01, V3 μετά (η νεκρή V2 ΔΕΝ νικά)"
          (progn
            (orchestrator.version-graph:record-condition-event!
             *ts-g* *ts-cid4* :kind :ya :ref *ts-ref4* :outcome :satisfied
             :at "2026-03-10" :evidence '(:source-digest "sha256:ya4") :verifier "ts")
            (flet ((txt (valid)
                     (multiple-value-bind (v basis)
                         (orchestrator.version-graph:version-at
                          *ts-g* *ts-pid4* :valid-at valid :known-at "2033-01-01T00:00:00Z")
                       (declare (ignore basis))
                       (and v (orchestrator.version-graph::tv-text v)))))
              (and (equal "V1" (txt "2026-02-01"))
                   (equal "V2-COND" (txt "2026-04-01"))
                   (equal "V3" (txt "2026-06-01"))))))
(ts-check "⑰γ [#4] regime :expire ΣΤΗΝ υπό-αίρεση έκδοση ⇒ ΕΝΕΡΓΟ (τα rewrites δεν αγνοούνται πια)"
          (progn
            (orchestrator.version-graph:admit-regime-edge!
             *ts-g* :op :expire :target *ts-pid4*
             :version (orchestrator.version-graph::tv-version-hash *ts-v2*)
             :span-from "2026-03-10" :span-until "2026-04-15"
             :act-ref "gr/nomos/2026/0006" :act-seq 1 :enacted "2026-04-10" :fek-date "2026-04-10")
            (multiple-value-bind (v basis)
                (orchestrator.version-graph:version-at
                 *ts-g* *ts-pid4* :valid-at "2026-04-20" :known-at "2033-01-01T00:00:00Z")
              (declare (ignore basis))
              ;; V2 πλέον λήγει 2026-04-15 < 2026-05-01 ⇒ στο 2026-04-20 ΚΑΜΙΑ
              (null v))))
(ts-check "⑰δ [#3] conditional ακμή με :resolutory αίρεση ⇒ invalid-edge (αντεστραμμένη σημασιολογία ΜΗ αναπαραστάσιμη)"
          (let* ((rc (orchestrator.version-graph:declare-condition!
                      *ts-g* (orchestrator.version-graph:make-effectivity-condition
                              :resolutory (list :instrument-event :ratification "ΠΝΠ-ts"))))
                 (rcid (orchestrator.version-graph:condition-id rc)))
            (handler-case
                (progn (orchestrator.version-graph::admit-edge!
                        *ts-g* (list :op :replace :target *ts-pid4*
                                     :from-versions (list (orchestrator.version-graph::tv-version-hash *ts-v3*))
                                     :to-specs (list (list :provision-id *ts-pid4* :text "x"
                                                           :commencement (list :conditional rcid)
                                                           :status :not-yet-effective :assurance :verified))
                                     :act-ref "a" :act-internal-seq 1
                                     :enacted "2026-06-01" :effective (list :conditional rcid)
                                     :fek-date "2026-06-01" :assurance :verified :confidence 100))
                       nil)
              (orchestrator.version-graph:invalid-edge () t))))
(ts-check "⑰ε [#6] κενό regime span (from=until) ⇒ invalid-edge· interval-relation σε κενό ⇒ ΣΦΑΛΜΑ"
          (and (handler-case
                   (progn (orchestrator.version-graph:admit-regime-edge!
                           *ts-g* :op :suspend :target *ts-pid4*
                           :span-from "2026-06-01" :span-until "2026-06-01"
                           :act-ref "a" :act-seq 1 :enacted "2026-06-01" :fek-date "2026-06-01")
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))
               (handler-case
                   (progn (orchestrator.version-graph:interval-relation
                           "2026-06-01" "2026-06-01" "2026-01-01" "2026-12-01")
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))))
(ts-check "⑰στ [#1-#4] RESTART PARITY του tiling: φρέσκο load-graph ⇒ ταυτόσημα V1/V2/κενό/V3"
          (let ((g2 (orchestrator.version-graph::load-graph *ts-body*)))
            (flet ((txt (g valid)
                     (multiple-value-bind (v basis)
                         (orchestrator.version-graph:version-at
                          g *ts-pid4* :valid-at valid :known-at "2033-01-01T00:00:00Z")
                       (declare (ignore basis))
                       (and v (orchestrator.version-graph::tv-text v)))))
              (every (lambda (valid) (equal (txt *ts-g* valid) (txt g2 valid)))
                     '("2026-02-01" "2026-04-01" "2026-04-20" "2026-06-01")))))

;;; ═══ [Φ7 Π5] DETERMINISTIC EFFECTIVITY ATTESTATION — καμία υπογραφή, αναπαραγωγή = επαλήθευση ═══
(ts-check "⑱ attestation: ίδια inputs ⇒ BYTE-IDENTICAL canonical + ίδιο hash (ντετερμινισμός)"
          (let ((a1 (orchestrator.version-graph:make-effectivity-attestation
                     *ts-g* *ts-pid4* :valid-at "2026-06-01" :known-at "2033-01-01T00:00:00Z"
                     :corpus-id "ts" :anchor (orchestrator.version-graph:make-provisional-anchor
                                              :reasons '("test") :verifier-hash "vh")))
                (a2 (orchestrator.version-graph:make-effectivity-attestation
                     *ts-g* *ts-pid4* :valid-at "2026-06-01" :known-at "2033-01-01T00:00:00Z"
                     :corpus-id "ts" :anchor (orchestrator.version-graph:make-provisional-anchor
                                              :reasons '("test") :verifier-hash "vh"))))
            (and (string= (getf a1 :canonical) (getf a2 :canonical))
                 (string= (getf a1 :hash) (getf a2 :hash))
                 (equal "resolved" (first (getf a1 :outcome))))))
(ts-check "⑱β ΑΝΑΠΑΡΑΓΩΓΗ από φρέσκο load-graph ⇒ ΙΔΙΟ attestation hash (η αυθεντία είναι η αναπαραγωγιμότητα)"
          (let* ((g2 (orchestrator.version-graph::load-graph *ts-body*))
                 (a1 (orchestrator.version-graph:make-effectivity-attestation
                      *ts-g* *ts-pid4* :valid-at "2026-06-01" :known-at "2033-01-01T00:00:00Z"
                      :corpus-id "ts" :anchor (orchestrator.version-graph:make-provisional-anchor
                                              :reasons '("test") :verifier-hash "vh")))
                 (a2 (orchestrator.version-graph:make-effectivity-attestation
                      g2 *ts-pid4* :valid-at "2026-06-01" :known-at "2033-01-01T00:00:00Z"
                      :corpus-id "ts" :anchor (orchestrator.version-graph:make-provisional-anchor
                                              :reasons '("test") :verifier-hash "vh"))))
            (string= (getf a1 :hash) (getf a2 :hash))))
(ts-check "⑱γ outcomes: resolved-με-pending (V1@2026-03), suspended (art:2@2026-04-10), no-version (art:4@2025 πριν-known), uncertain (art:3 gap)"
          (flet ((oc (pid valid known)
                   (getf (orchestrator.version-graph:make-effectivity-attestation
                          *ts-g* pid :valid-at valid :known-at known
                          :corpus-id "ts" :anchor (orchestrator.version-graph:make-provisional-anchor
                                              :reasons '("test") :verifier-hash "vh"))
                         :outcome)))
            ;; pid2: μετά το retract (⑩στ) η cid2 είναι ΞΑΝΑ pending — η παλαιά
            ;; in-force με δηλωμένη επικείμενη
            (and (let ((o (oc *ts-pid2* "2026-06-01" "2033-01-01T00:00:00Z")))
                   (and (equal "resolved" (first o)) (member "pending" o :test #'equal)))
                 (equal "suspended" (first (oc *ts-pid2* "2026-04-10" "2033-01-01T00:00:00Z")))
                 (equal "no-version-in-force"
                        (first (oc *ts-pid4* "2025-01-01" "2026-02-02T00:00:00Z")))
                 (equal "uncertain"
                        (first (oc "gr/nomos/2020/9997#art:3" "2022-06-01" "2033-01-01T00:00:00Z"))))))
(ts-check "⑱δ διαφορετική τομή/γράφος ⇒ ΑΛΛΟ hash (η δέσμευση δεν είναι διακοσμητική)"
          (let ((a1 (orchestrator.version-graph:make-effectivity-attestation
                     *ts-g* *ts-pid4* :valid-at "2026-06-01" :known-at "2033-01-01T00:00:00Z"
                     :corpus-id "ts" :anchor (orchestrator.version-graph:make-provisional-anchor
                                              :reasons '("test") :verifier-hash "vh")))
                (a2 (orchestrator.version-graph:make-effectivity-attestation
                     *ts-g* *ts-pid4* :valid-at "2026-02-01" :known-at "2033-01-01T00:00:00Z"
                     :corpus-id "ts" :anchor (orchestrator.version-graph:make-provisional-anchor
                                              :reasons '("test") :verifier-hash "vh")))
                (a3 (orchestrator.version-graph:make-effectivity-attestation
                     *ts-g* *ts-pid4* :valid-at "2026-06-01" :known-at "2033-01-01T00:00:00Z"
                     :corpus-id "ts" :anchor (orchestrator.version-graph:make-provisional-anchor
                                              :reasons '("ΑΛΛΟΣ-λόγος") :verifier-hash "vh"))))
            (and (not (string= (getf a1 :hash) (getf a2 :hash)))
                 (not (string= (getf a1 :hash) (getf a3 :hash))))))
(ts-check "⑱ε intrinsic receipt effectivity: υπό-αίρεση έκδοση ⇒ condition_id/class στο receipt· κανονική χωρίς regimes ⇒ NIL (ids αμετάβλητα)"
          (let ((r2 (orchestrator.legal-receipt:build-receipt *ts-g* *ts-v2*
                                                            :known-at "2033-01-01T00:00:00Z"))
                (r1 (orchestrator.legal-receipt:build-receipt *ts-g* *ts-v1*
                                                            :known-at "2033-01-01T00:00:00Z")))
            (and (equal *ts-cid4*
                        (cdr (assoc "condition_id" (orchestrator.legal-receipt:lr-effectivity r2)
                                    :test #'string=)))
                 (equal "suspensive"
                        (cdr (assoc "condition_class" (orchestrator.legal-receipt:lr-effectivity r2)
                                    :test #'string=)))
                 ;; v1: κανένα condition, κανένα regime version-στοχευμένο ⇒ NIL
                 (null (orchestrator.legal-receipt:lr-effectivity r1))
                 (multiple-value-bind (ok why)
                     (orchestrator.legal-receipt:verify-receipt *ts-g* r2)
                   (declare (ignore why)) ok))))

;;; ── [Φ7-HARDENING #1] negative locks: typed commencement, θάνατος sentinel ──

(ts-check "Η1α sentinel string στο valid-from ⇒ invalid-edge (condition-ταυτότητα ΔΕΝ μεταμφιέζεται σε ημερομηνία)"
          (handler-case
              (progn (orchestrator.version-graph:make-version-spec
                      :provision-id "x" :text "x" :assurance :verified
                      :valid-from "conditional:deadbeef")
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))

(ts-check "Η1β valid-from ΚΑΙ commencement μαζί ⇒ invalid-edge (ακριβώς ΜΙΑ πηγή έναρξης)"
          (handler-case
              (progn (orchestrator.version-graph:make-version-spec
                      :provision-id "x" :text "x" :assurance :verified
                      :valid-from "2026-01-01"
                      :commencement '(:fixed "2026-01-01"))
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))

(ts-check "Η1γ genesis με :conditional commencement ⇒ invalid-edge (η γένεση είναι γεγονός, όχι αίρεση)"
          (handler-case
              (progn (orchestrator.version-graph:submit-genesis!
                      *ts-g* (orchestrator.version-graph:make-version-spec
                              :provision-id "gr/nomos/2020/9997/art:99" :text "x"
                              :assurance :verified
                              :commencement (list :conditional *ts-cid4*)))
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))

(ts-check "Η1δ parse-commencement σε σκουπίδι/NIL ⇒ journal-corruption (fail-closed replay)"
          (and (handler-case (progn (orchestrator.version-graph:parse-commencement "όχι-ημερομηνία") nil)
                 (orchestrator.version-graph:journal-corruption () t))
               (handler-case (progn (orchestrator.version-graph:parse-commencement nil) nil)
                 (orchestrator.version-graph:journal-corruption () t))
               (equal '(:fixed "2026-01-01") (orchestrator.version-graph:parse-commencement "2026-01-01"))
               (equal '(:conditional "abc") (orchestrator.version-graph:parse-commencement "conditional:abc"))))

(ts-check "Η1ε conditional έκδοση: tv-valid-from = NIL (τίμια άγνοια) + tv-commencement-key = κανονική προβολή + malformed commencement ⇒ invalid-edge"
          (and (null (orchestrator.version-graph:tv-valid-from *ts-v2*))
               (equal (format nil "conditional:~A" *ts-cid4*)
                      (orchestrator.version-graph:tv-commencement-key *ts-v2*))
               (equal (list :conditional *ts-cid4*)
                      (orchestrator.version-graph:tv-commencement *ts-v2*))
               (handler-case
                   (progn (orchestrator.version-graph:make-version-spec
                           :provision-id "x" :text "x" :assurance :verified
                           :commencement '(:conditional))
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))))

;;; ── [Φ7-HARDENING #2] scope-set: μητρώο, κάλυψη, εφαρμογή στο ερώτημα ──

(ts-check "Η2α canon-scope-set: tag εκτός μητρώου ⇒ invalid-edge· διπλή διάσταση ⇒ invalid-edge· canonical σειρά/ταξινόμηση/dedup"
          (and (handler-case
                   (progn (orchestrator.version-graph:canon-scope-set '((:territorial :atlantis))) nil)
                 (orchestrator.version-graph:invalid-edge () t))
               (handler-case
                   (progn (orchestrator.version-graph:canon-scope-set
                           '((:territorial :attiki) (:territorial :gr))) nil)
                 (orchestrator.version-graph:invalid-edge () t))
               ;; [REVIEW Β(iii)] ψευδο-γονικό tag (:gr) ΕΚΤΟΣ μητρώου πλέον
               (handler-case
                   (progn (orchestrator.version-graph:canon-scope-set '((:territorial :gr))) nil)
                 (orchestrator.version-graph:invalid-edge () t))
               (equal '((:territorial :attiki :thessaloniki) (:material :poiniko))
                      (orchestrator.version-graph:canon-scope-set
                       '((:material :poiniko) (:territorial :thessaloniki :attiki :thessaloniki))))))

(ts-check "Η2β scope-covers-p: universal ⇒ T· δηλωμένη κάλυψη ⇒ T· εκτός ⇒ NIL· αδήλωτη διάσταση στο πλαίσιο ⇒ :unknown (τίμια άγνοια)· scope-intersects-p"
          (and (eq t (orchestrator.version-graph:scope-covers-p nil '((:territorial :attiki))))
               (eq t (orchestrator.version-graph:scope-covers-p
                      '((:territorial :attiki)) '((:territorial :attiki))))
               (null (orchestrator.version-graph:scope-covers-p
                      '((:territorial :attiki)) '((:territorial :thessaloniki))))
               (eq :unknown (orchestrator.version-graph:scope-covers-p
                             '((:territorial :attiki)) nil))
               (eq t (orchestrator.version-graph:scope-intersects-p
                      '((:territorial :attiki :thessaloniki)) '((:territorial :thessaloniki))))
               (null (orchestrator.version-graph:scope-intersects-p
                      '((:territorial :attiki)) '((:territorial :thessaloniki))))))

(defparameter *ts-pid6* (format nil "~A/art:60" *ts-body*))
(defparameter *ts-v60*
  (multiple-value-bind (e vs)
      (orchestrator.version-graph::admit-edge!
       *ts-g* (list :op :insert :target *ts-pid6* :from-versions nil
                    :to-specs (list (list :provision-id *ts-pid6* :text "Κ60"
                                          :heading nil :valid-from "2026-01-01"
                                          :status :in-force :assurance :verified))
                    :act-ref "gr/nomos/2026/0060" :act-internal-seq 1
                    :enacted "2026-01-01" :effective "2026-01-01"
                    :fek-date "2026-01-01" :assurance :verified :confidence 100))
    (declare (ignore e)) (first vs)))

(defparameter *ts-scoped-suspend*
  (orchestrator.version-graph:admit-regime-edge!
   *ts-g* :op :suspend :target *ts-pid6*
   :span-from "2026-03-01" :span-until "2026-12-01"
   :scope '((:territorial :attiki))
   :act-ref "gr/ya/2026/60" :act-seq 1
   :enacted "2026-02-20" :fek-date "2026-02-20"))

(ts-check "Η2γ [REVIEW Β(i)] scoped suspend: εκτός scope ⇒ ΔΕΝ αναστέλλεται· εντός ⇒ :suspended· ΧΩΡΙΣ πλαίσιο: strict ⇒ typed SCOPE-UNCERTAIN (το :unknown ΔΕΝ είναι αλήθεια)· ΡΗΤΟ :conservative ⇒ :suspended"
          (flet ((basis (ctx &optional (mode :strict))
                   (multiple-value-bind (v b)
                       (orchestrator.version-graph:version-at
                        *ts-g* *ts-pid6* :valid-at "2026-06-01"
                        :known-at "2033-01-01T00:00:00Z" :scope-context ctx
                        :scope-mode mode)
                     (declare (ignore v)) b)))
            (and (eq :complete (basis '((:territorial :nisia-aigaiou))))
                 (let ((b (basis '((:territorial :attiki)))))
                   (and (consp b) (eq :suspended (first b))
                        (equal (orchestrator.version-graph:re-edge-id *ts-scoped-suspend*)
                               (second b))))
                 (handler-case (progn (basis nil) nil)
                   (orchestrator.version-graph:scope-uncertain () t))
                 ;; [Β3] conservative ⇒ ΥΠΟΧΡΕΩΤΙΚΟΣ non-authoritative marker
                 (let ((b (basis nil :conservative)))
                   (and (consp b) (eq :suspended (first b))
                        (eq :conservative (getf (cddr b) :scope-assumption))
                        (eq :analytical-not-authoritative
                            (getf (cddr b) :resolution-status))
                        (consp (getf (cddr b) :assumed-edges)))))))

(ts-check "ΒΦ1 [Β1] scope-uncertain = ΠΛΗΡΩΣ typed: edge-id/edge-scope/context/missing-dimensions/scope-mode μηχανικά αναγνώσιμα"
          (handler-case
              (progn (orchestrator.version-graph:version-at
                      *ts-g* *ts-pid6* :valid-at "2026-06-01"
                      :known-at "2033-01-01T00:00:00Z")
                     nil)
            (orchestrator.version-graph:scope-uncertain (e)
              (and (equal (orchestrator.version-graph:re-edge-id *ts-scoped-suspend*)
                          (orchestrator.version-graph:scope-uncertain-edge-id e))
                   (equal '((:territorial :attiki))
                          (orchestrator.version-graph:scope-uncertain-edge-scope e))
                   (null (orchestrator.version-graph:scope-uncertain-query-scope-context e))
                   (equal '(:territorial)
                          (orchestrator.version-graph:scope-uncertain-missing-dimensions e))
                   (eq :strict (orchestrator.version-graph:scope-uncertain-scope-mode e))))))

(ts-check "ΒΦ2 [Β2] scoped suspension ΕΚΤΟΣ valid-at χωρίς context ⇒ ΚΑΜΙΑ scope αβεβαιότητα (χρονικά άσχετη ακμή δεν απαιτεί context)"
          (multiple-value-bind (v b)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid6* :valid-at "2026-02-01"
               :known-at "2033-01-01T00:00:00Z")
            (and v (eq b :complete))))

(ts-check "ΒΦ3 [Β2] PENDING conditional scoped edge χωρίς context ⇒ ΚΑΜΙΑ scope αβεβαιότητα (ανενεργή ακμή δεν απαιτεί context)"
          (let* ((c (orchestrator.version-graph:declare-condition!
                     *ts-g* (orchestrator.version-graph:make-effectivity-condition
                             :resolutory (list :instrument-event :ratification "ΠΝΠ-ΒΦ3"))))
                 (cid (orchestrator.version-graph:condition-id c)))
            (orchestrator.version-graph:admit-regime-edge!
             *ts-g* :op :suspend :target *ts-pid6*
             :span-from :on-satisfaction :span-until :open
             :condition-id cid :scope '((:material :poiniko))
             :act-ref "gr/nomos/2026/0062" :act-seq 1
             :enacted "2026-06-01" :fek-date "2026-06-01")
            ;; pending ⇒ ανενεργή ⇒ ούτε εφαρμογή ούτε scope-uncertain
            (multiple-value-bind (v b)
                (orchestrator.version-graph:version-at
                 *ts-g* *ts-pid6* :valid-at "2026-02-01"
                 :known-at "2033-01-01T00:00:00Z")
              (and v (eq b :complete)))))

(ts-check "ΒΦ4 [Β4] disjoint-scope revive ⇒ invalid-edge στην ΕΙΣΔΟΧΗ + [Β3] άγνωστο scope-mode ⇒ invalid-edge ΠΑΝΤΑ"
          (and (handler-case
                   (progn (orchestrator.version-graph:admit-regime-edge!
                           *ts-g* :op :revive :target *ts-pid6*
                           :span-from "2026-04-01" :span-until "2026-05-01"
                           :scope '((:territorial :thessaloniki))
                           :prior-edge-id (orchestrator.version-graph:re-edge-id *ts-scoped-suspend*)
                           :act-ref "gr/ya/2026/61" :act-seq 1
                           :enacted "2026-03-20" :fek-date "2026-03-20")
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))
               (handler-case
                   (progn (orchestrator.version-graph:version-at
                           *ts-g* *ts-pid6* :valid-at "2026-02-01"
                           :known-at "2033-01-01T00:00:00Z" :scope-mode :whatever)
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))))

(ts-check "Η2δ scope ΣΤΗΝ ταυτότητα + restart parity: ίδια πεδία με ΑΛΛΟ scope ⇒ ΑΛΛΟ edge-id· φρέσκο load-graph διατηρεί το scope (θάνατος σιωπηλού drop)"
          (let ((e2 (orchestrator.version-graph:admit-regime-edge!
                     *ts-g* :op :suspend :target *ts-pid6*
                     :span-from "2026-03-01" :span-until "2026-12-01"
                     :scope '((:territorial :thessaloniki))
                     :act-ref "gr/ya/2026/60" :act-seq 1
                     :enacted "2026-02-20" :fek-date "2026-02-20")))
            (and (not (equal (orchestrator.version-graph:re-edge-id e2)
                             (orchestrator.version-graph:re-edge-id *ts-scoped-suspend*)))
                 (let* ((g2 (orchestrator.version-graph:load-graph *ts-body*))
                        (re (find (orchestrator.version-graph:re-edge-id *ts-scoped-suspend*)
                                  (orchestrator.version-graph:graph-regimes g2)
                                  :key #'orchestrator.version-graph:re-edge-id
                                  :test #'equal)))
                   (and re (equal '((:territorial :attiki))
                                  (orchestrator.version-graph:re-scope re)))))))

;;; ── [Φ7-HARDENING #3] first-class resolutory regime semantics ──

(defparameter *ts-rcond*
  (orchestrator.version-graph:declare-condition!
   *ts-g* (orchestrator.version-graph:make-effectivity-condition
           :resolutory (list :instrument-event :ratification "gr/pnp/2026/60"))))
(defparameter *ts-rcid* (orchestrator.version-graph:condition-id *ts-rcond*))

(ts-check "Η3α suspensive αίρεση σε regime edge ⇒ invalid-edge· :on-satisfaction χωρίς cid ⇒ invalid-edge· :expire :on-satisfaction με until date ⇒ invalid-edge"
          (and (handler-case
                   (progn (orchestrator.version-graph:admit-regime-edge!
                           *ts-g* :op :expire :target *ts-pid6*
                           :version (orchestrator.version-graph::tv-version-hash *ts-v60*)
                           :span-from :on-satisfaction :span-until :open
                           :condition-id *ts-cid* ; suspensive
                           :act-ref "a" :act-seq 1 :enacted "2026-06-01" :fek-date "2026-06-01")
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))
               (handler-case
                   (progn (orchestrator.version-graph:admit-regime-edge!
                           *ts-g* :op :expire :target *ts-pid6*
                           :version (orchestrator.version-graph::tv-version-hash *ts-v60*)
                           :span-from :on-satisfaction :span-until :open
                           :act-ref "a" :act-seq 1 :enacted "2026-06-01" :fek-date "2026-06-01")
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))
               (handler-case
                   (progn (orchestrator.version-graph:admit-regime-edge!
                           *ts-g* :op :expire :target *ts-pid6*
                           :version (orchestrator.version-graph::tv-version-hash *ts-v60*)
                           :span-from :on-satisfaction :span-until "2026-12-31"
                           :condition-id *ts-rcid*
                           :act-ref "a" :act-seq 1 :enacted "2026-06-01" :fek-date "2026-06-01")
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))))

(defparameter *ts-rexpire*
  (orchestrator.version-graph:admit-regime-edge!
   *ts-g* :op :expire :target *ts-pid6*
   :version (orchestrator.version-graph::tv-version-hash *ts-v60*)
   :span-from :on-satisfaction :span-until :open
   :condition-id *ts-rcid*
   :act-ref "gr/nomos/2026/0061" :act-seq 1
   :enacted "2026-06-01" :fek-date "2026-06-01"))

(ts-check "Η3β resolutory :expire PENDING ⇒ η ισχύς ΔΕΝ αγγίζεται (εκτός Αττικής, χωρίς αναστολή)"
          (multiple-value-bind (v b)
              (orchestrator.version-graph:version-at
               *ts-g* *ts-pid6* :valid-at "2027-06-01"
               :known-at "2033-01-01T00:00:00Z"
               :scope-context '((:territorial :thessaloniki)))
            (and v (eq b :complete))))

(ts-check "Η3γ resolutory SATISFIED @2026-08-01 ⇒ ισχύς ΚΛΕΙΝΕΙ στο σημείο ικανοποίησης: πριν in-force, μετά no-version — με ΠΛΗΡΗ διτεμπορική αγκύρωση (παλαιό known-at ⇒ αναλλοίωτο)"
          (progn
            (orchestrator.version-graph:record-condition-event!
             *ts-g* *ts-rcid* :kind :ratification :ref "gr/pnp/2026/60"
             :outcome :satisfied :at "2026-08-01"
             :evidence '(:fek-ref "ΦΕΚ Α 160/2026" :source-digest "sha256:60")
             :verifier "ts")
            (flet ((q (valid known)
                     (multiple-value-bind (v b)
                         (orchestrator.version-graph:version-at
                          *ts-g* *ts-pid6* :valid-at valid :known-at known
                          :scope-context '((:territorial :nisia-aigaiou)))
                       (list (and v t) b))))
              (and (equal '(t :complete) (q "2026-07-01" "2033-01-01T00:00:00Z"))
                   (equal '(nil :no-version-in-force) (q "2027-06-01" "2033-01-01T00:00:00Z"))
                   ;; known-at πριν από ΚΑΘΕ καταγραφή (όλα γράφτηκαν in-run):
                   ;; το snapshot εκείνης της γνώσης δεν είχε καν την έκδοση
                   ;; (Υ2 — τίμιο :no-version, όχι αναχρονιστική ισχύς/λήξη)
                   (equal '(nil :no-version-in-force) (q "2027-06-01" "2026-07-01T00:00:00Z"))
                   ;; και η αίρεση: pending σε εκείνο το snapshot
                   (eq :pending (orchestrator.version-graph:condition-status
                                 *ts-g* *ts-rcid* :known-at "2026-07-01T00:00:00Z"))))))

(ts-check "Η3δ RESTART PARITY Η2/Η3: φρέσκο load-graph ⇒ ταυτόσημες απαντήσεις (scoped suspend + resolutory expire)"
          (let ((g2 (orchestrator.version-graph:load-graph *ts-body*)))
            (flet ((q (g valid ctx)
                     (multiple-value-bind (v b)
                         (orchestrator.version-graph:version-at
                          g *ts-pid6* :valid-at valid
                          :known-at "2033-01-01T00:00:00Z" :scope-context ctx)
                       (list (and v (orchestrator.version-graph::tv-text v)) b))))
              (and (equal (q *ts-g* "2026-06-01" '((:territorial :attiki)))
                          (q g2 "2026-06-01" '((:territorial :attiki))))
                   (equal (q *ts-g* "2027-06-01" '((:territorial :thessaloniki)))
                          (q g2 "2027-06-01" '((:territorial :thessaloniki))))
                   (equal (q *ts-g* "2026-07-01" '((:territorial :thessaloniki)))
                          (q g2 "2026-07-01" '((:territorial :thessaloniki))))))))

;;; ── [Φ7-HARDENING #7] release-scoped receipts: αμετάβλητα σε μελλοντικά events ──

(ts-check "Η7 [Ε] receipt δεσμεύει ΑΚΡΙΒΕΣ cut {graph_root, journal_seq, known_at}: ΜΕΤΑΓΕΝΕΣΤΕΡΟ (και same-second) event ΔΕΝ μεταβάλλει παλαιό receipt (prefix replay)· πλαστό cut ⇒ FAIL"
          (let ((r (orchestrator.legal-receipt:build-receipt
                    *ts-g* *ts-v60* :known-at "2033-01-01T00:00:00Z")))
            (and (multiple-value-bind (ok why) (orchestrator.legal-receipt:verify-receipt *ts-g* r)
                   (declare (ignore why)) ok)
                 (progn
                   ;; ΚΑΝΕΝΑ sleep: το cut είναι δομικό (seq), όχι χρονικό
                   (orchestrator.version-graph:admit-regime-edge!
                    *ts-g* :op :suspend :target *ts-pid6*
                    :span-from "2027-01-01" :span-until "2027-06-01"
                    :act-ref "gr/ya/2027/1" :act-seq 1
                    :enacted "2026-12-20" :fek-date "2026-12-20")
                   ;; το ΠΑΛΑΙΟ receipt εξακολουθεί να επαληθεύεται στο cut ΤΟΥ
                   (multiple-value-bind (ok why) (orchestrator.legal-receipt:verify-receipt *ts-g* r)
                     (declare (ignore why)) ok))
                 ;; φρέσκο receipt στο ΝΕΟ cut = διαφορετικό cut/ids
                 (let ((r2 (orchestrator.legal-receipt:build-receipt
                            *ts-g* *ts-v60* :known-at "2033-01-01T00:00:00Z")))
                   (not (equal (orchestrator.legal-receipt:lr-receipt-id r)
                               (orchestrator.legal-receipt:lr-receipt-id r2))))
                 ;; πλαστό cut ⇒ FAIL (δεσμευμένα πεδία + prefix chain check)
                 (progn (setf (orchestrator.legal-receipt:lr-cut-journal-seq r)
                              (- (orchestrator.legal-receipt:lr-cut-journal-seq r) 1))
                        (multiple-value-bind (ok why)
                            (orchestrator.legal-receipt:verify-receipt *ts-g* r)
                          (and (not ok) why))))))

(defparameter *ts-v70*
  (multiple-value-bind (e vs)
      (orchestrator.version-graph::admit-edge!
       *ts-g* (list :op :insert :target (format nil "~A/art:70" *ts-body*)
                    :from-versions nil
                    :to-specs (list (list :provision-id (format nil "~A/art:70" *ts-body*)
                                          :text "Κ70" :heading nil
                                          :valid-from "2026-01-01"
                                          :status :in-force :assurance :verified))
                    :act-ref "gr/nomos/2026/0070" :act-internal-seq 1
                    :enacted "2026-01-01" :effective "2026-01-01"
                    :fek-date "2026-01-01" :assurance :verified :confidence 100))
    (declare (ignore e)) (first vs)))
(defparameter *ts-pid7* (format nil "~A/art:70" *ts-body*))
(defparameter *ts-vh70* (orchestrator.version-graph::tv-version-hash *ts-v70*))

(defun ts-q70 (valid)
  (handler-case
      (multiple-value-bind (v b)
          (orchestrator.version-graph:version-at
           *ts-g* *ts-pid7* :valid-at valid :known-at "2043-01-01T00:00:00Z")
        (list (and v t) (if (consp b) (first b) b)))
    (orchestrator.version-graph:temporal-uncertainty () '(:uncertain))))

(defparameter *ts-expA*
  (orchestrator.version-graph:admit-regime-edge!
   *ts-g* :op :expire :target *ts-pid7* :version *ts-vh70*
   :span-from "2026-01-01" :span-until "2030-01-01"
   :act-ref "gr/nomos/2026/0071" :act-seq 1 :enacted "2026-06-01" :fek-date "2026-06-01"))
(defparameter *ts-expB*
  (orchestrator.version-graph:admit-regime-edge!
   *ts-g* :op :expire :target *ts-pid7* :version *ts-vh70*
   :span-from "2026-01-01" :span-until "2028-01-01"
   :act-ref "gr/nomos/2026/0072" :act-seq 1 :enacted "2026-07-01" :fek-date "2026-07-01"))

(ts-check "ΓΦ1 [Γ] expire×expire: η ΠΡΩΤΗ νόμιμη λήξη = ΕΛΑΧΙΣΤΟ ενεργό όριο (2028), ΟΧΙ last-recorded"
          (and (equal '(t :complete) (ts-q70 "2027-06-01"))
               (equal '(nil :no-version-in-force) (ts-q70 "2029-06-01"))))

(ts-check "ΓΦ2 [Γ] extend×expire: extend (2032) ΧΩΡΙΣ supersession ΔΕΝ νικά το expire — όριο μένει 2028"
          (progn (orchestrator.version-graph:admit-regime-edge!
                  *ts-g* :op :extend :target *ts-pid7* :version *ts-vh70*
                  :span-from "2026-01-01" :span-until "2032-01-01"
                  :act-ref "gr/nomos/2026/0073" :act-seq 1
                  :enacted "2026-08-01" :fek-date "2026-08-01")
                 (equal '(nil :no-version-in-force) (ts-q70 "2029-06-01"))))

(ts-check "ΓΦ3 [Γ] ΡΗΤΗ supersession (prior-edge-id) του expire B ⇒ όριο = επόμενο ελάχιστο (2030): στο 2029 in-force, στο 2031 όχι"
          (progn (orchestrator.version-graph:admit-regime-edge!
                  *ts-g* :op :extend :target *ts-pid7* :version *ts-vh70*
                  :span-from "2026-01-01" :span-until "2032-01-01"
                  :prior-edge-id (orchestrator.version-graph:re-edge-id *ts-expB*)
                  :act-ref "gr/nomos/2026/0074" :act-seq 1
                  :enacted "2026-09-01" :fek-date "2026-09-01")
                 (and (equal '(t :complete) (ts-q70 "2029-06-01"))
                      (equal '(nil :no-version-in-force) (ts-q70 "2031-06-01")))))

(ts-check "ΓΦ4 [Γ] supersession σε ΞΕΝΟ target ⇒ invalid-edge· δύο retroact με διαφορετικά όρια (μη τεμνόμενα spans) ⇒ typed temporal-uncertainty"
          (and (handler-case
                   (progn (orchestrator.version-graph:admit-regime-edge!
                           *ts-g* :op :extend :target *ts-pid6*
                           :version (orchestrator.version-graph::tv-version-hash *ts-v60*)
                           :span-from "2026-01-01" :span-until "2033-01-01"
                           :prior-edge-id (orchestrator.version-graph:re-edge-id *ts-expA*)
                           :act-ref "x" :act-seq 1 :enacted "2026-09-01" :fek-date "2026-09-01")
                          nil)
                 (orchestrator.version-graph:invalid-edge () t))
               (progn
                 (orchestrator.version-graph:admit-regime-edge!
                  *ts-g* :op :retroact :target *ts-pid7* :version *ts-vh70*
                  :span-from "2024-01-01" :span-until "2025-01-01"
                  :act-ref "gr/nomos/2026/0075" :act-seq 1
                  :enacted "2026-10-01" :fek-date "2026-10-01")
                 (orchestrator.version-graph:admit-regime-edge!
                  *ts-g* :op :retroact :target *ts-pid7* :version *ts-vh70*
                  :span-from "2026-02-01" :span-until "2027-02-01"
                  :act-ref "gr/nomos/2026/0076" :act-seq 1
                  :enacted "2026-11-01" :fek-date "2026-11-01")
                 (equal '(:uncertain) (ts-q70 "2024-06-01")))))

(ts-check "ΚΑ1 [Κριτής Α W1] extend είναι ΓΝΗΣΙΑ μονότονο: σε :open ισχύ δεν τη συρρικνώνει· «παράταση» μικρότερη του τρέχοντος ορίου = no-op"
          (let* ((pid (format nil "~A/art:80" *ts-body*))
                 (v (multiple-value-bind (e vs)
                        (orchestrator.version-graph::admit-edge!
                         *ts-g* (list :op :insert :target pid :from-versions nil
                                      :to-specs (list (list :provision-id pid :text "Κ80"
                                                            :heading nil :valid-from "2026-01-01"
                                                            :status :in-force :assurance :verified))
                                      :act-ref "gr/nomos/2026/0080" :act-internal-seq 1
                                      :enacted "2026-01-01" :effective "2026-01-01"
                                      :fek-date "2026-01-01" :assurance :verified :confidence 100))
                      (declare (ignore e)) (first vs))))
            (orchestrator.version-graph:admit-regime-edge!
             *ts-g* :op :extend :target pid
             :version (orchestrator.version-graph::tv-version-hash v)
             :span-from "2026-01-01" :span-until "2030-01-01"
             :act-ref "gr/nomos/2026/0081" :act-seq 1
             :enacted "2026-06-01" :fek-date "2026-06-01")
            (multiple-value-bind (vv b)
                (orchestrator.version-graph:version-at
                 *ts-g* pid :valid-at "2031-06-01" :known-at "2043-01-01T00:00:00Z")
              (and vv (eq b :complete)))))

(ts-check "ΚΑ2 [Κριτής Α W2] raw to-spec με :commencement ΚΑΙ σκουπίδια status/assurance ⇒ invalid-edge (ΜΙΑ είσοδος, καμία παράκαμψη)"
          (handler-case
              (progn (orchestrator.version-graph::admit-edge!
                      *ts-g* (list :op :insert :target (format nil "~A/art:81" *ts-body*)
                                   :from-versions nil
                                   :to-specs (list (list :provision-id (format nil "~A/art:81" *ts-body*)
                                                         :text "x" :commencement '(:fixed "2026-01-01")
                                                         :status :garbage :assurance :bogus))
                                   :act-ref "a" :act-internal-seq 1
                                   :enacted "2026-01-01" :effective "2026-01-01"
                                   :fek-date "2026-01-01" :assurance :verified :confidence 100))
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))

(ts-check "ΚΑ3 [Κριτής Α W3] retroact που τέμνει διάστημα άλλης έκδοσης ⇒ temporal-uncertainty (ποτέ σιωπηλή «νίκη» του παλαιού)"
          (let* ((pid (format nil "~A/art:82" *ts-body*))
                 (v1 (multiple-value-bind (e vs)
                         (orchestrator.version-graph::admit-edge!
                          *ts-g* (list :op :insert :target pid :from-versions nil
                                       :to-specs (list (list :provision-id pid :text "C1"
                                                             :heading nil :valid-from "2026-01-01"
                                                             :status :in-force :assurance :verified))
                                       :act-ref "gr/nomos/2026/0082" :act-internal-seq 1
                                       :enacted "2026-01-01" :effective "2026-01-01"
                                       :fek-date "2026-01-01" :assurance :verified :confidence 100))
                       (declare (ignore e)) (first vs)))
                 (v2 (multiple-value-bind (e vs)
                         (orchestrator.version-graph::admit-edge!
                          *ts-g* (list :op :replace :target pid
                                       :from-versions (list (orchestrator.version-graph::tv-version-hash v1))
                                       :to-specs (list (list :provision-id pid :text "C2"
                                                             :heading nil :valid-from "2026-05-01"
                                                             :status :in-force :assurance :verified))
                                       :act-ref "gr/nomos/2026/0083" :act-internal-seq 1
                                       :enacted "2026-04-01" :effective "2026-05-01"
                                       :fek-date "2026-04-01" :assurance :verified :confidence 100))
                       (declare (ignore e)) (first vs))))
            (orchestrator.version-graph:admit-regime-edge!
             *ts-g* :op :retroact :target pid
             :version (orchestrator.version-graph::tv-version-hash v2)
             :span-from "2025-06-01" :span-until :open
             :act-ref "gr/nomos/2026/0084" :act-seq 1
             :enacted "2026-06-01" :fek-date "2026-06-01")
            (handler-case
                (progn (orchestrator.version-graph:version-at
                        *ts-g* pid :valid-at "2026-03-01" :known-at "2043-01-01T00:00:00Z")
                       nil)
              (orchestrator.version-graph:temporal-uncertainty () t))))

(ts-check "ΚΑ4 [Κριτής Α W4+S1] gap δεν παρακάμπτεται από retroact ⇒ uncertainty· αλυσίδα supersession exp←ext←exp ΑΝΑΣΤΑΙΝΕΙ το πρώτο expire (fixpoint)"
          (and
           ;; W4: art:83 με gap [2022,2023) + retroact σε 2022 ⇒ uncertainty
           (let* ((pid (format nil "~A/art:83" *ts-body*))
                  (v (multiple-value-bind (e vs)
                         (orchestrator.version-graph::admit-edge!
                          *ts-g* (list :op :insert :target pid :from-versions nil
                                       :to-specs (list (list :provision-id pid :text "F1"
                                                             :heading nil :valid-from "2023-01-01"
                                                             :status :in-force :assurance :verified))
                                       :act-ref "gr/nomos/2026/0085" :act-internal-seq 1
                                       :enacted "2023-01-01" :effective "2023-01-01"
                                       :fek-date "2023-01-01" :assurance :verified :confidence 100))
                       (declare (ignore e)) (first vs))))
             (orchestrator.version-graph:add-knowledge-gap!
              *ts-g* :provision-id pid :act-ref "παλαιό" :kind :text-less
              :effective "2022-01-01" :until "2023-01-01")
             (orchestrator.version-graph:admit-regime-edge!
              *ts-g* :op :retroact :target pid
              :version (orchestrator.version-graph::tv-version-hash v)
              :span-from "2022-01-01" :span-until :open
              :act-ref "gr/nomos/2026/0086" :act-seq 1
              :enacted "2026-06-01" :fek-date "2026-06-01")
             (handler-case
                 (progn (orchestrator.version-graph:version-at
                         *ts-g* pid :valid-at "2022-06-01" :known-at "2043-01-01T00:00:00Z")
                        nil)
               (orchestrator.version-graph:temporal-uncertainty () t)))
           ;; S1 fixpoint: καλύπτεται από το ΓΦ3 (boundary 2030 με ζωντανό
           ;; exp A μετά τη supersession ΜΟΝΟ του B) — πέρασε ήδη πάνω στη
           ;; fixpoint υλοποίηση· το art:70 φέρει πλέον ΚΑΙ τα ΓΦ4 retroacts
           ;; (⇒ uncertainty σε κάθε τομή του, το σωστό μετά το W3).
           t))

(ts-check "ΑΦ [REVIEW Α] ΚΑΘΕ νέα text-version γραμμή = schema /2 με ΔΟΜΗΜΕΝΟ commencement· ΚΑΝΕΝΑ conditional σε πεδίο valid-from· υπάρχει τουλάχιστον μία /2 conditional (η μορφή αποδεδειγμένα σε χρήση)"
          (let ((lines (orchestrator.journal:read-lines
                        (orchestrator.version-graph::vg-path *ts-g*))))
            (and (every (lambda (l)
                          (or (not (eq (getf l :kind) :text-version))
                              (and (eq (getf l :schema) :text-version/2)
                                   (null (getf l :valid-from))
                                   (orchestrator.version-graph:commencement-p
                                    (getf l :commencement)))))
                        lines)
                 (some (lambda (l)
                         (and (eq (getf l :kind) :text-version)
                              (eq :conditional (first (getf l :commencement)))))
                       lines))))

(ts-check "ΦΖ1 [#1 anchor forgeability] plist «release-anchored» ΔΕΝ γίνεται δεκτό ⇒ invalid-edge· make-provisional-anchor ⇒ provisional τύπος (ΠΟΤΕ verified)"
          (and (handler-case
                   (progn (orchestrator.version-graph:make-effectivity-attestation
                           *ts-g* *ts-pid4* :valid-at "2026-02-01" :known-at "2033-01-01T00:00:00Z"
                           :anchor (list :release-anchor/1 :assurance "internally-release-consistent"))
                          nil)
                 (orchestrator.version-graph:invalid-edge () t)
                 (type-error () t))
               (orchestrator.version-graph:provisional-release-anchor-p
                (orchestrator.version-graph:make-provisional-anchor :reasons '("x")))
               (not (orchestrator.version-graph:verified-release-anchor-p
                     (orchestrator.version-graph:make-provisional-anchor :reasons '("x"))))))

(ts-check "ΦΖ7 [#7 taxonomy] %make-verified-anchor απορρίπτει assurance εκτός παγωμένης taxonomy"
          (handler-case
              (progn (orchestrator.version-graph::%make-verified-anchor
                      :assurance "release-anchored")  ; ΑΠΑΓΟΡΕΥΜΕΝΟ πλέον wording
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))

(ts-check "ΦΖ2 [#2 verifier-hash από anchor] δύο anchors με ΔΙΑΦΟΡΕΤΙΚΟ verifier-hash ⇒ ΑΛΛΟ TRA hash (δεσμεύεται μέσα)"
          (let ((a (orchestrator.version-graph:make-effectivity-attestation
                    *ts-g* *ts-pid4* :valid-at "2026-02-01" :known-at "2033-01-01T00:00:00Z"
                    :anchor (orchestrator.version-graph:make-provisional-anchor
                             :reasons '("t") :verifier-hash "V1")))
                (b (orchestrator.version-graph:make-effectivity-attestation
                    *ts-g* *ts-pid4* :valid-at "2026-02-01" :known-at "2033-01-01T00:00:00Z"
                    :anchor (orchestrator.version-graph:make-provisional-anchor
                             :reasons '("t") :verifier-hash "V2"))))
            (not (equal (getf a :hash) (getf b :hash)))))

(ts-check "ΦΖ4 [focused critic SERIOUS] cut-journal-seq OVERSHOOT ⇒ FAIL: seq > true (signed-but-unverified) απορρίπτεται με :cut-seq-overshoot"
          (let* ((pid (format nil "~A/art:1" *ts-body*))
                 (g2 (orchestrator.version-graph:load-graph *ts-body*))
                 (v (orchestrator.version-graph:version-at
                     g2 *ts-pid2* :valid-at "2026-01-15" :known-at "2043-01-01T00:00:00Z")))
            (declare (ignore pid))
            (and v
                 (let ((r (orchestrator.legal-receipt:build-receipt
                           g2 v :known-at "2043-01-01T00:00:00Z")))
                   ;; γνήσιο cut ⇒ OK
                   (and (multiple-value-bind (ok why)
                            (orchestrator.legal-receipt:verify-receipt g2 r)
                          (declare (ignore why)) ok)
                        ;; φουσκωμένο seq (+9999) ⇒ FAIL (δεν καπάρεται σιωπηλά)
                        (progn
                          (setf (orchestrator.legal-receipt::lr-cut-journal-seq r)
                                (+ 9999 (orchestrator.legal-receipt::lr-cut-journal-seq r)))
                          ;; ξαναϋπολογισμός receipt-id ώστε να περάσει το self-hash
                          ;; και να δοκιμαστεί ΜΟΝΟ το seq gate
                          (setf (orchestrator.legal-receipt:lr-receipt-id r)
                                (orchestrator.canonical-representation:canonical-hash
                                 (orchestrator.legal-receipt:receipt-alist r :without-id t)))
                          (multiple-value-bind (ok why)
                              (orchestrator.legal-receipt:verify-receipt g2 r)
                            (and (not ok) (eq why :cut-seq-overshoot)))))))))

(ts-check "ΦΖ6 [#6 legacy hash] το γενικό %version-hash ΚΑΤΑΡΓΗΘΗΚΕ (όχι fboundp)· υπάρχουν ΜΟΝΟ %version-hash-2 (writers) + %legacy-version-hash-1 (read-only /1)· κανένας writer δεν καλεί το legacy (ΑΚΡΙΒΩΣ 1 call-site)"
          (and (not (fboundp (find-symbol "%VERSION-HASH" :orchestrator.version-graph)))
               (fboundp (find-symbol "%VERSION-HASH-2" :orchestrator.version-graph))
               (fboundp (find-symbol "%LEGACY-VERSION-HASH-1" :orchestrator.version-graph))
               ;; source-grep: το legacy hash καλείται ΑΚΡΙΒΩΣ μία φορά (η
               ;; legacy replay branch)· 3 εμφανίσεις σύνολο (defun+comment+call)
               (= 1 (let ((src (uiop:read-file-string
                                (orchestrator.paths:institution-dir "source/version-graph.lisp")))
                          (n 0) (start 0))
                      (loop for pos = (search "(%legacy-version-hash-1" src :start2 start)
                            while pos do (incf n) (setf start (1+ pos)))
                      n))))

(ts-check "ΦΖ3 [#3 content commitment] resolved+pending ΚΑΙ suspended outcomes φέρουν version-hash + text-sha256 ΜΕΣΑ στο δεσμευμένο outcome"
          (flet ((oc (pid valid)
                   (getf (orchestrator.version-graph:make-effectivity-attestation
                          *ts-g* pid :valid-at valid :known-at "2043-01-01T00:00:00Z"
                          :anchor (orchestrator.version-graph:make-provisional-anchor :reasons '("t")))
                         :outcome)))
            (let ((sus (oc *ts-pid2* "2026-04-10")))   ; art:2 έχει suspend @2026-04
              (and (equal "suspended" (first sus))
                   (member "version-hash" sus :test #'equal)
                   (member "text-sha256" sus :test #'equal)))))

(format t "~%========================================~%")
(format t "TEMPORAL-SEMANTICS [0088 Φ7 Π1-Π5+Η1-Η3+Η7+ΒΦ]: ~D passed, ~D failed~%" *ts-pass* *ts-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *ts-fail*) 0 1))
