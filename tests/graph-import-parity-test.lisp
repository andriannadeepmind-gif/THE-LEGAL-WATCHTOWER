;;;; tests/graph-import-parity-test.lisp
;;;; ============================================================================
;;;; [0088] Φ3 — IMPORT + FOLD-PARITY GATE: και τα 6 σώματα στον διτεμπορικό
;;;; γράφο, snapshot ≡ consolidated μονοπάτι BYTE-προς-BYTE ανά άρθρο
;;;; (unclassified_divergences=0), κενά γνώσης ΔΗΛΩΜΕΝΑ, χρονική τιμιότητα:
;;;; προ-αναθεώρησης ερώτημα σε τροποποιημένο άρθρο ⇒ temporal-uncertainty
;;;; (ο θάνατος της TEMP-04 αναπαραγωγής), chain επαληθεύσιμη με replay.
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *gp-pass* 0)
(defvar *gp-fail* 0)

(defmacro gp-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *gp-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *gp-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *gp-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0088] Φ3 IMPORT + FOLD-PARITY: 6 σώματα στον γράφο ──~%")

;; καθαρό store ανά εκτέλεση — τα journals είναι runtime κατασκευάσματα
(let ((dir (orchestrator.paths:institution-dir "deployment/data/version-graph/")))
  (when (probe-file dir)
    (uiop:delete-directory-tree (uiop:ensure-directory-pathname dir)
                                :validate (constantly t) :if-does-not-exist :ignore)))

(defparameter *gp-graphs* '())
(defparameter *gp-expected*
  '(("syntagma" . 124) ("poinikos" . 529) ("kpoinikis" . 595)
    ("astikos" . 2040) ("kpolitikis" . 1102) ("kdioikitikis" . 304)))

;;; ① Import και των 6 σωμάτων + parity 0 αποκλίσεων το καθένα
(dolist (pair *gp-expected*)
  (destructuring-bind (cid . expected-count) pair
    (multiple-value-bind (graph report) (import-corpus->graph! cid)
      (push (cons cid graph) *gp-graphs*)
      (gp-check (format nil "① ~A: import ~D άρθρων (αναμενόμενα ~D), 0 παραλείψεις"
                        cid (getf report :imported) expected-count)
                (and (= expected-count (getf report :imported))
                     (null (getf report :skipped))))
      (multiple-value-bind (div checked) (graph-parity-report cid graph)
        (dolist (d (subseq div 0 (min 5 (length div))))
          (format t "    ✗ απόκλιση: ~S~%" d))
        (gp-check (format nil "①β ~A FOLD-PARITY: ~D άρθρα ελέγχθηκαν, ΜΗΔΕΝ αποκλίσεις (byte-ίδιο κείμενο)"
                          cid checked)
                  (and (= checked expected-count) (null div)))))))

;;; ② Χρονική τιμιότητα Συντάγματος — ο θάνατος της TEMP-04 αναπαραγωγής
(let ((g (cdr (assoc "syntagma" *gp-graphs* :test #'equal))))
  (gp-check "② κενά γνώσης δηλωμένα: >70 gaps (κάθε αναθεώρηση × άρθρο των 4 records)"
            (> (length (orchestrator.version-graph:graph-gaps g)) 70))
  (gp-check "②β άρθρο 16 (αναθ. 1986+2001+2008): valid-at 1990 ⇒ ΡΗΤΗ temporal-uncertainty — ΟΧΙ το σημερινό κείμενο με ψευδή βεβαιότητα"
            (handler-case
                (progn (orchestrator.version-graph:version-at
                        g "gr/syntagma#art:16"
                        :valid-at "1990-01-01" :known-at "9999-12-31T23:59:59Z")
                       nil)
              (orchestrator.version-graph:temporal-uncertainty () t)))
  (gp-check "②γ άρθρο 16 ΣΗΜΕΡΑ ⇒ κείμενο παρόν, valid-from = τελευταία αναθεώρηση (2019-11-25 — το 16 είναι και στη λίστα του 2019), ΟΧΙ το ψευδές 1975"
            (multiple-value-bind (v basis)
                (orchestrator.version-graph:version-at
                 g "gr/syntagma#art:16"
                 :valid-at (subseq (orchestrator.journal:iso-now) 0 10)
                 :known-at "9999-12-31T23:59:59Z")
              (and (eq :complete basis) v
                   (equal "2019-11-25" (orchestrator.version-graph:tv-valid-from v)))))
  (gp-check "②δ ΑΘΙΚΤΟ άρθρο (art:2 — σε κανένα αναθεωρητικό record): valid-at 1990 ⇒ κείμενο ΠΑΡΟΝ με valid-from 1975-06-11"
            (multiple-value-bind (v basis)
                (orchestrator.version-graph:version-at
                 g "gr/syntagma#art:2"
                 :valid-at "1990-01-01" :known-at "9999-12-31T23:59:59Z")
              (and (eq :complete basis) v
                   (equal "1975-06-11" (orchestrator.version-graph:tv-valid-from v)))))
  (gp-check "②ε lettered 5Α (εισήχθη 2001): valid-from = 2019-11-25 (τελευταία αναθ. που το άγγιξε — art 5 στη λίστα 2019)· προ-2001 ⇒ uncertainty ή κενό, ΠΟΤΕ κείμενο"
            (handler-case
                (progn (orchestrator.version-graph:version-at
                        g "gr/syntagma#art:5Α"
                        :valid-at "1995-01-01" :known-at "9999-12-31T23:59:59Z")
                       ;; αν δεν σήμανε uncertainty: αποδεκτό ΜΟΝΟ (values NIL …)
                       (multiple-value-bind (v basis)
                           (orchestrator.version-graph:version-at
                            g "gr/syntagma#art:5Α"
                            :valid-at "1995-01-01" :known-at "9999-12-31T23:59:59Z")
                         (declare (ignore basis)) (null v)))
              (orchestrator.version-graph:temporal-uncertainty () t))))

;;; ③ Η αλυσίδα κάθε σώματος επαληθεύεται με ΠΛΗΡΕΣ replay από τον δίσκο
(dolist (pair *gp-graphs*)
  (destructuring-bind (cid . graph) pair
    (gp-check (format nil "③ ~A: verify-chain (πλήρες replay) ⇒ ΙΔΙΑ κεφαλή με τη ζωντανή" cid)
              (multiple-value-bind (ok head n)
                  (orchestrator.version-graph:verify-chain
                   (orchestrator.version-graph:graph-body graph))
                (and ok (> n 0)
                     (equal head (orchestrator.version-graph::vg-chain graph)))))))

;;; ④ Επανεισαγωγή = ΣΦΑΛΜΑ (καμία σιωπηλή διπλοεισαγωγή)
(gp-check "④ import ξανά στο ίδιο journal ⇒ ΡΗΤΟ σφάλμα"
          (handler-case (progn (import-corpus->graph! "syntagma") nil)
            (error () t)))

;;; ⑤ [Φ5] text-as-known — η διτεμπορική απάντηση από τον ΔΙΣΚΟ (load-graph)
(gp-check "⑤ text-as-known(syntagma art:2, σήμερα, τώρα): κείμενο ≡ γράφου, basis :complete"
          (let ((r (text-as-known "syntagma" "2"
                                  :valid-at (subseq (orchestrator.journal:iso-now) 0 10)
                                  :known-at "9999-12-31T23:59:59Z")))
            (and (eq :complete (getf r :basis))
                 (stringp (getf r :text)) (plusp (length (getf r :text)))
                 (equal "1975-06-11" (getf r :valid-from)))))
(gp-check "⑤β text-as-known(art:16, valid 1990) ⇒ temporal-uncertainty ΚΑΙ από το δισκο-φορτωμένο μονοπάτι"
          (handler-case
              (progn (text-as-known "syntagma" "16"
                                    :valid-at "1990-01-01" :known-at "9999-12-31T23:59:59Z")
                     nil)
            (orchestrator.version-graph:temporal-uncertainty () t)))

;;; ⑥ [Φ5/PCL-02] corpus-temporal-commitment — η δέσμευση που μπαίνει στο census-2
(gp-check "⑥ commitment(syntagma): graph_root = κεφαλή verify-chain, 124 receipts, ρίζα RFC-6962 αναπαραγώγιμη"
          (let ((tc (corpus-temporal-commitment "syntagma")))
            (multiple-value-bind (ok head n)
                (orchestrator.version-graph:verify-chain (getf tc :body))
              (declare (ignore n))
              (and ok
                   (equal head (getf tc :graph-root))
                   (= 124 (getf tc :receipt-count))
                   (stringp (getf tc :receipt-set-root))
                   (plusp (length (getf tc :receipt-set-root)))))))
(gp-check "⑥β commitment ντετερμινιστικό: δεύτερη κλήση ⇒ ΙΔΙΕΣ ρίζες (ίδιο journal, ίδια τομή)"
          (let ((a (corpus-temporal-commitment "syntagma"))
                (b (corpus-temporal-commitment "syntagma")))
            (and (equal (getf a :graph-root) (getf b :graph-root))
                 (equal (getf a :receipt-set-root) (getf b :receipt-set-root)))))

;;; ⑦ [Φ5γ/TRUST-01] grounded-impact — συλλογισμός ΜΟΝΟ πάνω σε receipts
(let ((tc (corpus-temporal-commitment "syntagma"))
      (doc (nth-value 1 (build-consolidated-for "syntagma"))))
  (gp-check "⑦ grounded-impact ΧΩΡΙΣ τομή/γράφο ⇒ TYPED ungrounded-reasoning (όχι γενικό error)"
            (handler-case
                (progn (orchestrator.reasoning:grounded-impact doc "syntagma" "16") nil)
              (orchestrator.reasoning:ungrounded-reasoning () t)))
  ;; μη-ταυτολογικό: βρες άρθρο με ΠΡΑΓΜΑΤΙΚΕΣ εισερχόμενες παραπομπές, ώστε
  ;; το impact set να είναι ΜΗ ΚΕΝΟ και η θεμελίωση να ασκηθεί σε αληθινά μέλη
  (defparameter *gp-cited*
    (let ((facts (orchestrator.reasoning:reference-facts doc "syntagma")))
      (or (fifth (first facts))
          (error "κανένα citation fact στο σύνταγμα — αδύνατο"))))
  (gp-check (format nil "⑦β grounded-impact(~A — έχει εισερχόμενες παραπομπές): impact ΜΗ ΚΕΝΟ και ΚΑΘΕ συμπέρασμα φέρει receipt-id που επαληθεύεται στον γράφο" *gp-cited*)
            (multiple-value-bind (grounded ungrounded)
                (orchestrator.reasoning:grounded-impact
                 doc "syntagma" *gp-cited*
                 :body (getf tc :typed-body) :graph (getf tc :graph)
                 :receipts (getf tc :receipts)
                 :valid-at (getf tc :valid-at) :known-at (getf tc :known-at))
              (format t "    (θεμελιωμένα ~D, αθεμελίωτα ~D)~%"
                      (length grounded) (length ungrounded))
              (and (plusp (length grounded))
                   ;; [κριτής Β 4.2] στη ΣΗΜΕΡΙΝΗ τομή ΟΛΟ το impact set θεμελιώνεται:
                   ;; μηδέν ungrounded — όχι απλώς «≥1 θεμελιωμένο»
                   (zerop (length ungrounded))
                   (every (lambda (g)
                            (let ((r (find (getf g :provision-id) (getf tc :receipts)
                                           :key #'orchestrator.legal-receipt:lr-provision-id
                                           :test #'equal)))
                              (and r
                                   (equal (getf g :receipt-id)
                                          (orchestrator.legal-receipt:lr-receipt-id r))
                                   (orchestrator.legal-receipt:verify-receipt (getf tc :graph) r))))
                          grounded))))
  (gp-check "⑦γ grounded-impact με valid-at σε κενό γνώσης (1990/άρθρο 16) ⇒ TYPED ungrounded-reasoning — όχι συλλογισμός πάνω σε αβέβαιο θεμέλιο"
            (handler-case
                (progn (orchestrator.reasoning:grounded-impact
                        doc "syntagma" "16"
                        :body (getf tc :typed-body) :graph (getf tc :graph)
                        :receipts (getf tc :receipts)
                        :valid-at "1990-01-01" :known-at "9999-12-31T23:59:59Z")
                       nil)
              (orchestrator.reasoning:ungrounded-reasoning () t))))

(format t "~%========================================~%")
(format t "GRAPH-IMPORT-PARITY [0088 Φ3+Φ5]: ~D passed, ~D failed~%" *gp-pass* *gp-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *gp-fail*) 0 1))
