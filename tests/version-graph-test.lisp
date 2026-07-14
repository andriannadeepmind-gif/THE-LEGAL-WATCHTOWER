;;;; tests/version-graph-test.lisp
;;;; ============================================================================
;;;; [0088] Φ2 — Ο διτεμπορικός γράφος εκδόσεων: G1 replay-then-append, τύπος
;;;; χωρίς NIL-effective (TEMP-02 δομικά νεκρό), καραντίνα ΩΣ ΤΥΠΟΣ αόρατη στην
;;;; επιλογή, recorded ΣΤΟ predicate (TEMP-03 νεκρό), retract διατηρεί as-known,
;;;; chain-hash replay από τον δίσκο, ντετερμινισμός hashes.
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *vg-pass* 0)
(defvar *vg-fail* 0)

(defmacro vg-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *vg-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *vg-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *vg-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0088] Φ2 VERSION GRAPH: διτεμπορική αλήθεια, fail-closed ──~%")

(defparameter *vg-stamp* (get-universal-time))
(defun vg-body (tag) (format nil "test/vg-~D-~A" *vg-stamp* tag))

;;; ① Ο ΤΥΠΟΣ αρνείται τον άγνωστο χρόνο — η κλάση TEMP-02 δεν κατασκευάζεται
(vg-check "① edge-spec με effective NIL/κακή μορφή ⇒ invalid-edge (δομικά αδύνατο, όχι φρουρός)"
          (flet ((dies (&rest args)
                   (handler-case (progn (apply #'orchestrator.version-graph:make-edge-spec args) nil)
                     (orchestrator.version-graph:invalid-edge () t))))
            (and (dies :op :replace :target "x" :enacted "2020-01-01" :effective nil
                       :fek-date "2020-01-01" :act-ref "a" :act-internal-seq '(1 1))
                 (dies :op :replace :target "x" :enacted "2020-01-01" :effective "άγνωστη"
                       :fek-date "2020-01-01" :act-ref "a" :act-internal-seq '(1 1))
                 (dies :op :replace :target "x" :enacted "2020-01-01" :effective "2020-1-1"
                       :fek-date "2020-01-01" :act-ref "a" :act-internal-seq '(1 1))
                 ;; χωρίς act-internal-seq (tie-break G2) ⇒ επίσης αδύνατο
                 (dies :op :replace :target "x" :enacted "2020-01-01" :effective "2020-02-01"
                       :fek-date "2020-01-01" :act-ref "a" :act-internal-seq nil))))

;;; ② Γένεση + αντικατάσταση + διτεμπορικά ερωτήματα
(defparameter *g* (orchestrator.version-graph:make-graph (vg-body "main")))
(defparameter *pid* "gr/syntagma#art:16")
(defparameter *v1*
  (orchestrator.version-graph:submit-genesis!
   *g* (orchestrator.version-graph:make-version-spec
        :provision-id *pid* :text "Αρχικό κείμενο." :valid-from "1975-06-11"
        :assurance :attested-manual)))
(vg-check "② genesis: έκδοση με valid-from 1975, :open, recorded-from πραγματικό, previous :genesis"
          (and (equal "1975-06-11" (orchestrator.version-graph:tv-valid-from *v1*))
               (eq :open (orchestrator.version-graph:tv-valid-until *v1*))
               (stringp (orchestrator.version-graph:tv-recorded-from *v1*))
               (eq :genesis (orchestrator.version-graph:tv-previous-version-hash *v1*))))
(vg-check "②β genesis σε ΚΑΤΕΙΛΗΜΜΕΝΗ διάταξη ⇒ ΣΦΑΛΜΑ (G4 — καμία σιωπηλή σύγκρουση)"
          (handler-case
              (progn (orchestrator.version-graph:submit-genesis!
                      *g* (orchestrator.version-graph:make-version-spec
                           :provision-id *pid* :text "άλλο" :valid-from "1980-01-01"
                           :assurance :attested-manual))
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))

(sleep 1.2)  ; διακριτά recorded stamps για τον transaction-time μάρτυρα

(defparameter *edge+versions*
  (multiple-value-list
   (orchestrator.version-graph:admit-edge!
    *g* (orchestrator.version-graph:make-edge-spec
         :op :replace :target *pid*
         :from-versions (list (orchestrator.version-graph:tv-version-hash *v1*))
         :to-specs (list (orchestrator.version-graph:make-version-spec
                          :provision-id *pid* :text "Αναθεωρημένο κείμενο."
                          :valid-from "2001-04-17" :assurance :extracted-verified))
         :act-ref "gr/psifisma/2001#fekA84" :act-internal-seq '(1 3)
         :enacted "2001-04-06" :effective "2001-04-17" :fek-date "2001-04-06"
         :source-span '(:artifact-digest "sha256:test" :page 4)))))
(defparameter *edge* (first *edge+versions*))
(defparameter *v2* (first (second *edge+versions*)))

(vg-check "③ G1 admit: ακμή δεκτή, v1 έκλεισε στο effective ΜΕ supersession (το παλιό record κρατά :open για as-known), v2 previous=v1"
          (and (orchestrator.version-graph:amendment-edge-p *edge*)
               ;; supersession: το ΑΡΧΙΚΟ record κρατά :open αλλά έπαψε να είναι
               ;; τρέχουσα γνώση· υπάρχει υπερκείμενο record ίδιου hash με το κλείσιμο
               (eq :open (orchestrator.version-graph:tv-valid-until *v1*))
               (stringp (orchestrator.version-graph:tv-recorded-until *v1*))
               (find-if (lambda (r) (and (equal (orchestrator.version-graph:tv-version-hash r)
                                                (orchestrator.version-graph:tv-version-hash *v1*))
                                         (equal "2001-04-17" (orchestrator.version-graph:tv-valid-until r))
                                         (eq :current (orchestrator.version-graph:tv-recorded-until r))))
                        (orchestrator.version-graph:graph-versions-of *g* *pid*))
               (equal (orchestrator.version-graph:tv-version-hash *v1*)
                      (orchestrator.version-graph:tv-previous-version-hash *v2*))
               (= 64 (length (orchestrator.version-graph:ae-edge-id *edge*)))))

(vg-check "④ valid-time: πριν την ισχύ ⇒ v1 (:complete), μετά ⇒ v2 — με known-at τώρα"
          (let ((now "9999-12-31T23:59:59Z"))
            (flet ((vh (v) (orchestrator.version-graph:tv-version-hash v)))
              (and (equal (vh *v1*) (vh (orchestrator.version-graph:version-at
                                         *g* *pid* :valid-at "1990-01-01" :known-at now)))
                   (equal (vh *v2*) (vh (orchestrator.version-graph:version-at
                                         *g* *pid* :valid-at "2010-01-01" :known-at now)))))))

(vg-check "④β TRANSACTION-time: known-at = πριν καταγραφεί η ακμή ⇒ ο γράφος απαντά ό,τι ΗΞΕΡΕ τότε (v1 ισχύον ακόμη και για μελλοντικό valid-at ΔΕΝ εμφανίζεται — :no-version)"
          (let ((known-then (orchestrator.version-graph:tv-recorded-from *v1*)))
            (flet ((vh (v) (orchestrator.version-graph:tv-version-hash v)))
              ;; τότε: v1 γνωστό και :open ⇒ valid 2010 ⇒ v1 (η ΤΟΤΕ αλήθεια!)
              (and (equal (vh *v1*) (vh (orchestrator.version-graph:version-at
                                         *g* *pid* :valid-at "2010-01-01" :known-at known-then)))
                   ;; τώρα: v1 κλειστό στο 2001-04-17 ⇒ valid 2010 ⇒ v2
                   (equal (vh *v2*) (vh (orchestrator.version-graph:version-at
                                         *g* *pid* :valid-at "2010-01-01" :known-at "9999-12-31T23:59:59Z")))))))

(vg-check "④γ version-at ΧΩΡΙΣ known-at ⇒ ΣΦΑΛΜΑ (κανένα σιωπηλό «τώρα»)"
          (handler-case
              (progn (orchestrator.version-graph:version-at *g* *pid* :valid-at "2010-01-01") nil)
            (error () t)))

;;; ⑤ G5 retract-knowledge: as-known διατηρείται, η τρέχουσα γνώση ανακαλείται
(vg-check "⑤ retract v2 ⇒ known-at μετά την ανάκληση: ΚΑΜΙΑ έκδοση για valid 2010 (τίμιο κενό)· το journal ΔΕΝ ξαναγράφτηκε"
          (progn
            (orchestrator.version-graph:retract-knowledge!
             *g* (orchestrator.version-graph:tv-version-hash *v2*) :reason "test-retract")
            (multiple-value-bind (v basis)
                (orchestrator.version-graph:version-at *g* *pid*
                                                       :valid-at "2010-01-01" :known-at "9999-12-31T23:59:59Z")
              (and (null v) (eq :no-version-in-force basis)))))

;;; ⑥ Καραντίνα — ΤΥΠΟΣ, αόρατος στην επιλογή, ΟΡΑΤΟΣ ως αβεβαιότητα
(defparameter *g2* (orchestrator.version-graph:make-graph (vg-body "quar")))
(defparameter *q-pid* "gr/syntagma#art:5")
(orchestrator.version-graph:submit-genesis!
 *g2* (orchestrator.version-graph:make-version-spec
       :provision-id *q-pid* :text "Κείμενο 5." :valid-from "1975-06-11"
       :assurance :attested-manual))
(vg-check "⑥ λάθος before-hash ⇒ (values NIL quarantined :conflicted-before-hash) — ΠΟΤΕ εφαρμογή"
          (multiple-value-bind (edge q)
              (orchestrator.version-graph:admit-edge!
               *g2* (orchestrator.version-graph:make-edge-spec
                     :op :replace :target *q-pid*
                     :from-versions '("λάθος-hash")
                     :to-specs (list (orchestrator.version-graph:make-version-spec
                                      :provision-id *q-pid* :text "νέο" :valid-from "2019-11-25"
                                      :assurance :extracted-verified))
                     :act-ref "x" :act-internal-seq '(1 1)
                     :enacted "2019-11-25" :effective "2019-11-25" :fek-date "2019-11-25"))
            (and (null edge)
                 (orchestrator.version-graph:quarantined-edge-p q)
                 (eq :conflicted-before-hash (orchestrator.version-graph:qe-reason q)))))
(vg-check "⑥β διάταξη με καραντίνα ⇒ version-at σηματοδοτεί temporal-uncertainty (όχι ψευδής βεβαιότητα)"
          (handler-case
              (progn (orchestrator.version-graph:version-at *g2* *q-pid*
                                                            :valid-at "2020-01-01" :known-at "9999-12-31T23:59:59Z")
                     nil)
            (orchestrator.version-graph:temporal-uncertainty () t)))
(vg-check "⑥γ δομική πράξη χωρίς Φ2 replay (:renumber) ⇒ ΡΗΤΗ καραντίνα :unsupported-op"
          (multiple-value-bind (edge q)
              (orchestrator.version-graph:admit-edge!
               *g2* (orchestrator.version-graph:make-edge-spec
                     :op :renumber :target *q-pid* :from-versions '("x") :to-specs '()
                     :act-ref "x" :act-internal-seq '(1 1)
                     :enacted "2020-01-01" :effective "2020-01-01" :fek-date "2020-01-01"))
            (and (null edge) (eq :unsupported-op (orchestrator.version-graph:qe-reason q)))))
(vg-check "⑥δ άγνωστη διάταξη ⇒ unknown-provision (τίμια άγνοια, όχι NIL)"
          (handler-case
              (progn (orchestrator.version-graph:version-at *g2* "gr/syntagma#art:999"
                                                            :valid-at "2020-01-01" :known-at "9999-12-31T23:59:59Z")
                     nil)
            (orchestrator.version-graph:unknown-provision () t)))

;;; ⑦ :repeal — tombstone με status, όχι εξαφάνιση
(defparameter *g3* (orchestrator.version-graph:make-graph (vg-body "repeal")))
(let ((v (orchestrator.version-graph:submit-genesis!
          *g3* (orchestrator.version-graph:make-version-spec
                :provision-id "gr/kodikas/2019/4619#art:100" :text "Ποινή."
                :valid-from "2019-07-01" :assurance :extracted-verified))))
  (vg-check "⑦ repeal ⇒ νέα έκδοση status :repealed, το ΙΔΙΟ κείμενο διατηρείται (ιστορία, όχι διαγραφή)"
            (multiple-value-bind (edge vs)
                (orchestrator.version-graph:admit-edge!
                 *g3* (orchestrator.version-graph:make-edge-spec
                       :op :repeal :target "gr/kodikas/2019/4619#art:100"
                       :from-versions (list (orchestrator.version-graph:tv-version-hash v))
                       :to-specs (list (orchestrator.version-graph:make-version-spec
                                        :provision-id "gr/kodikas/2019/4619#art:100"
                                        :text "Ποινή." :valid-from "2024-01-01"
                                        :status :repealed :assurance :extracted-verified))
                       :act-ref "gr/nomos/2023/5090#a5" :act-internal-seq '(5 1)
                       :enacted "2023-12-01" :effective "2024-01-01" :fek-date "2023-12-01"))
              (and edge (eq :repealed (orchestrator.version-graph:tv-status (first vs)))))))

;;; ⑧ Το journal ΕΙΝΑΙ η αλήθεια: replay από δίσκο ⇒ ίδια κεφαλή· παραποίηση ⇒ ρήξη
(vg-check "⑧ load-graph (πλήρες replay) ⇒ ΙΔΙΑ chain κεφαλή + ίδιες εκδόσεις + ίδια καραντίνα"
          (let ((fresh (orchestrator.version-graph:load-graph (vg-body "quar"))))
            (and (equal (orchestrator.version-graph::vg-chain *g2*)
                        (orchestrator.version-graph::vg-chain fresh))
                 (= (length (orchestrator.version-graph:graph-versions-of *g2* *q-pid*))
                    (length (orchestrator.version-graph:graph-versions-of fresh *q-pid*)))
                 (= (length (orchestrator.version-graph:graph-quarantine *g2*))
                    (length (orchestrator.version-graph:graph-quarantine fresh))))))
(vg-check "⑧β verify-chain: (values T κεφαλή πλήθος>0)"
          (multiple-value-bind (ok head n)
              (orchestrator.version-graph:verify-chain (vg-body "main"))
            (and ok (stringp head) (> n 3))))
(vg-check "⑧γ παραποιημένη γραμμή (λάθος chain) ⇒ load-graph ΣΦΑΛΜΑ με το ακριβές σημείο"
          (let ((body (vg-body "tamper")))
            (let ((g (orchestrator.version-graph:make-graph body)))
              (orchestrator.version-graph:submit-genesis!
               g (orchestrator.version-graph:make-version-spec
                  :provision-id "gr/syntagma#art:1" :text "α" :valid-from "1975-06-11"
                  :assurance :attested-manual))
              ;; ξένη γραμμή με ΨΕΥΤΙΚΗ αλυσίδα κατευθείαν στο journal
              (orchestrator.journal:append-line
               (orchestrator.version-graph::vg-path g)
               (list :kind :retract :record-id "tampered" :version "x"
                     :chain "ΨΕΥΤΙΚΗ" :at "2026-01-01T00:00:00Z"))
              ;; [κριτής Ε2] ξένη/παραποιημένη γραμμή = journal-corruption
              ;; (server-integrity), ΟΧΙ invalid-edge (client input)
              (handler-case (progn (orchestrator.version-graph:load-graph body) nil)
                (orchestrator.version-graph:journal-corruption () t)))))

;;; ⑨ Ντετερμινισμός ταυτοτήτων: ίδιο περιεχόμενο ⇒ ίδια version/edge hashes
(vg-check "⑨ δύο ανεξάρτητοι γράφοι, ίδιες πράξεις ⇒ ΙΔΙΑ version-hashes (bit-reproducible σύνολο)"
          (flet ((build (tag)
                   (let* ((g (orchestrator.version-graph:make-graph (vg-body tag)))
                          (v (orchestrator.version-graph:submit-genesis!
                              g (orchestrator.version-graph:make-version-spec
                                 :provision-id "gr/syntagma#art:2" :text "Σεβασμός."
                                 :valid-from "1975-06-11" :assurance :attested-manual))))
                     (multiple-value-bind (edge vs)
                         (orchestrator.version-graph:admit-edge!
                          g (orchestrator.version-graph:make-edge-spec
                             :op :replace :target "gr/syntagma#art:2"
                             :from-versions (list (orchestrator.version-graph:tv-version-hash v))
                             :to-specs (list (orchestrator.version-graph:make-version-spec
                                              :provision-id "gr/syntagma#art:2" :text "Σεβασμός v2."
                                              :valid-from "2001-04-17" :assurance :extracted-verified))
                             :act-ref "a" :act-internal-seq '(1 1)
                             :enacted "2001-04-06" :effective "2001-04-17" :fek-date "2001-04-06"))
                       (list (orchestrator.version-graph:tv-version-hash v)
                             (orchestrator.version-graph:ae-edge-id edge)
                             (orchestrator.version-graph:tv-version-hash (first vs)))))))
            (equal (build "det-a") (build "det-b"))))

;;; ⑩ snapshot-at: ρητές λίστες — τίποτα σιωπηλά απόν
(vg-check "⑩ snapshot-at στο *g2*: η art:5 στα uncertain (καραντίνα), όχι σιωπηλά απούσα"
          (multiple-value-bind (snap uncertain quarantine)
              (orchestrator.version-graph:snapshot-at *g2* :valid-at "2020-01-01"
                                                           :known-at "9999-12-31T23:59:59Z")
            (declare (ignore snap))
            (and (assoc *q-pid* uncertain :test #'equal)
                 (plusp (length quarantine)))))

(format t "~%========================================~%")
(format t "VERSION-GRAPH [0088 Φ2]: ~D passed, ~D failed~%" *vg-pass* *vg-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *vg-fail*) 0 1))
