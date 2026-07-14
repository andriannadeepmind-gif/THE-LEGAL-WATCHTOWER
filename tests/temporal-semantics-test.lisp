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

(format t "~%========================================~%")
(format t "TEMPORAL-SEMANTICS [0088 Φ7 Π1+Π2]: ~D passed, ~D failed~%" *ts-pass* *ts-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *ts-fail*) 0 1))
