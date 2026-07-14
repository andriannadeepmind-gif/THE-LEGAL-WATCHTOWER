;;;; tests/as-known-e2e-test.lisp
;;;; ============================================================================
;;;; [0088 Φ5-κριτής #9] E2E GATE: πραγματικό journal → γράφος → HTTP service.
;;;; Καμία mock αλήθεια: γνήσιο replay, δύο known-at με διαφορετικές ορθές
;;;; απαντήσεις, restart/load parity (και στο recorded-from — Υ3), payload
;;;; tampering ⇒ ρήξη (Κ2), καραντίνα πριν/μετά το known-at (Υ2), άκυρες
;;;; χρονικές παράμετροι ⇒ typed 400 (Υ1), αποτυχία παλιού provider ενώ το
;;;; /as-known μένει πράσινο (Κ1), και JSON parser validation ΚΑΘΕ απάντησης (Υ4).
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *e2-pass* 0)
(defvar *e2-fail* 0)

(defmacro e2-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *e2-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *e2-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *e2-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0088 #9] AS-KNOWN E2E: journal → γράφος → HTTP ──~%")

;;; ───────────────── ΜΕΡΟΣ Α: συνθετικός γράφος, γνήσιο journal ─────────────────

(defparameter *e2-body*
  (orchestrator.identity:body-id-string
   (orchestrator.identity:make-body :gr :nomos :year 2020 :number 9999 :slug "e2e")))

;; καθαρό ξεκίνημα ΜΟΝΟ για το δικό μας σώμα (δεν αγγίζουμε άλλα journals)
(let ((p (orchestrator.version-graph::vg-path
          (orchestrator.version-graph:make-graph *e2-body*))))
  (when (probe-file p) (delete-file p)))

(defparameter *e2-g* (orchestrator.version-graph:make-graph *e2-body*))
(defparameter *e2-pid*
  (orchestrator.identity:provision-id-string
   (orchestrator.identity:article-provision-id
    (orchestrator.identity:make-body :gr :nomos :year 2020 :number 9999 :slug "e2e") "1")))

(defparameter *e2-v1*
  (orchestrator.version-graph:submit-genesis!
   *e2-g* (orchestrator.version-graph:make-version-spec
           :provision-id *e2-pid* :text "Αρχικό κείμενο άρθρου 1."
           :valid-from "2020-01-01" :assurance :attested-manual)
   :derivation "bootstrap:e2e"))

(defparameter +past+ "2001-01-01T00:00:00Z")   ; πριν καταγραφεί ΟΤΙΔΗΠΟΤΕ
(defparameter +future+ "9999-12-31T23:59:59Z") ; μετά από όλα

;;; ① Το ΙΔΙΟ ερώτημα με δύο known-at ⇒ ΔΥΟ διαφορετικές ορθές απαντήσεις
(e2-check "① valid 2021, known ΠΡΙΝ την καταγραφή ⇒ ΚΑΜΙΑ έκδοση (το σύστημα ΔΕΝ το ήξερε τότε)"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at *e2-g* *e2-pid*
                                                     :valid-at "2021-01-01" :known-at +past+)
            (and (null v) (eq :no-version-in-force basis))))
(e2-check "①β valid 2021, known ΜΕΤΑ ⇒ το κείμενο ΠΑΡΟΝ (:complete)"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at *e2-g* *e2-pid*
                                                     :valid-at "2021-01-01" :known-at +future+)
            (and (eq :complete basis)
                 (equal "Αρχικό κείμενο άρθρου 1."
                        (orchestrator.version-graph:tv-text v)))))

;;; ② Ακμή (μεταγενέστερη γνώση) + restart/replay ΤΑΥΤΟΤΗΤΑ (Υ3)
(defparameter *e2-edge*
  (orchestrator.version-graph:admit-edge!
   *e2-g* (orchestrator.version-graph:make-edge-spec
           :op :replace :target *e2-pid*
           :from-versions (list (orchestrator.version-graph:tv-version-hash *e2-v1*))
           :to-specs (list (orchestrator.version-graph:make-version-spec
                            :provision-id *e2-pid* :text "Νέο κείμενο άρθρου 1."
                            :valid-from "2024-01-01" :assurance :attested-manual))
           :act-ref "gr/nomos/2023/1" :act-internal-seq '(1 1)
           :enacted "2023-12-01" :effective "2024-01-01" :fek-date "2023-12-01")))

(defparameter *e2-reload* (orchestrator.version-graph:load-graph *e2-body*))

(e2-check "② restart (load-graph): ΙΔΙΑ κεφαλή αλυσίδας με τη ζωντανή"
          (equal (orchestrator.version-graph:graph-chain-head *e2-g*)
                 (orchestrator.version-graph:graph-chain-head *e2-reload*)))
(e2-check "②β restart: byte-identical κείμενο στην ίδια τομή (valid 2025, known τώρα)"
          (equal (orchestrator.version-graph:tv-text
                  (orchestrator.version-graph:version-at *e2-g* *e2-pid*
                                                         :valid-at "2025-06-01" :known-at +future+))
                 (orchestrator.version-graph:tv-text
                  (orchestrator.version-graph:version-at *e2-reload* *e2-pid*
                                                         :valid-at "2025-06-01" :known-at +future+))))
(e2-check "②γ [Υ3] live edge recorded-from ≡ replayed edge recorded-from (ΟΧΙ ±1s drift)"
          (let ((live (orchestrator.version-graph:ae-edge-id *e2-edge*)))
            (equal (orchestrator.version-graph::ae-recorded-from *e2-edge*)
                   (orchestrator.version-graph::ae-recorded-from
                    (gethash live (orchestrator.version-graph::vg-edges *e2-reload*))))))
(e2-check "②δ [Υ3] live version recorded-from ≡ replayed (κάθε record)"
          (every (lambda (pair)
                   (destructuring-bind (h . v) pair
                     (equal (orchestrator.version-graph:tv-recorded-from v)
                            (orchestrator.version-graph:tv-recorded-from
                             (gethash h (orchestrator.version-graph::vg-versions *e2-reload*))))))
                 (let (acc) (maphash (lambda (k v) (push (cons k v) acc))
                                     (orchestrator.version-graph::vg-versions *e2-g*))
                      acc)))

;;; ③ [Κ2] Payload tampering: αλλαγή ΕΝΟΣ πεδίου με αμετάβλητο record-id/chain ⇒ ΡΗΞΗ
(defparameter *e2-tampered-body*
  (orchestrator.identity:body-id-string
   (orchestrator.identity:make-body :gr :nomos :year 2020 :number 9998 :slug "e2t")))
(let* ((src (orchestrator.version-graph::vg-path (orchestrator.version-graph:make-graph *e2-body*)))
       (dst (orchestrator.version-graph::vg-path (orchestrator.version-graph:make-graph *e2-tampered-body*)))
       (content (uiop:read-file-string src :external-format :utf-8)))
  (when (probe-file dst) (delete-file dst))
  (ensure-directories-exist dst)
  (alexandria:write-string-into-file
   ;; πειράζουμε ΜΟΝΟ το κείμενο — record-id, payload-hash, chain μένουν ίδια
   (cl-ppcre:regex-replace-all "Αρχικό κείμενο" content "ΠΑΡΑΧΑΡΑΓΜΕΝΟ κείμενο")
   dst :if-exists :supersede :external-format :utf-8))
(e2-check "③ [Κ2] αλλοιωμένο text με ίδιο record-id/chain ⇒ load-graph ΣΦΑΛΜΑ (payload δέσμευση)"
          (handler-case (progn (orchestrator.version-graph:load-graph *e2-tampered-body*) nil)
            (error () t)))

;;; ④ [Υ2] Καραντίνα: πριν/μετά το known-at
(orchestrator.version-graph:quarantine!
 *e2-g* (list :target *e2-pid* :op :replace :note "ύποπτη πράξη") :unknown-text)
(e2-check "④ καραντίνα καταγεγραμμένη ΤΩΡΑ: known-at στο ΠΑΡΕΛΘΟΝ ⇒ ΔΕΝ δηλητηριάζει το τότε snapshot"
          (multiple-value-bind (v basis)
              (orchestrator.version-graph:version-at *e2-g* *e2-pid*
                                                     :valid-at "2021-01-01" :known-at +past+)
            (declare (ignore v))
            (eq :no-version-in-force basis)))   ; όχι temporal-uncertainty
(e2-check "④β ίδιο ερώτημα με known-at ΜΕΤΑ την καταγραφή ⇒ ΡΗΤΗ temporal-uncertainty"
          (handler-case
              (progn (orchestrator.version-graph:version-at *e2-g* *e2-pid*
                                                            :valid-at "2021-01-01" :known-at +future+)
                     nil)
            (orchestrator.version-graph:temporal-uncertainty () t)))

;;; ⑤ [Υ1] Typed χρόνος στον πυρήνα
(e2-check "⑤ valid-at 2026-99-99 ⇒ typed σφάλμα (γνήσιος γρηγοριανός έλεγχος)"
          (handler-case
              (progn (orchestrator.version-graph:version-at *e2-g* *e2-pid*
                                                            :valid-at "2026-99-99" :known-at +future+)
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))
(e2-check "⑤β known-at χωρίς Z/μη-instant ⇒ typed σφάλμα (καμία λεξικογραφική ανοχή)"
          (handler-case
              (progn (orchestrator.version-graph:version-at *e2-g* *e2-pid*
                                                            :valid-at "2021-01-01" :known-at "zzzz")
                     nil)
            (orchestrator.version-graph:invalid-edge () t)))
(e2-check "⑤γ 2024-02-29 (δίσεκτο) δεκτό, 2023-02-29 ΟΧΙ"
          (and (orchestrator.version-graph:legal-date-p "2024-02-29")
               (not (orchestrator.version-graph:legal-date-p "2023-02-29"))))
(e2-check "⑤δ [κριτής Ε1] Unicode ψηφία (fullwidth ５, Arabic-Indic ٥) ΑΠΟΡΡΙΠΤΟΝΤΑΙ — ASCII-only canonical"
          (and (not (orchestrator.version-graph:legal-date-p
                     (concatenate 'string (string (code-char #xFF15)) "026-01-01")))
               (not (orchestrator.version-graph:legal-instant-p
                     (concatenate 'string (string (code-char #x0665)) "026-01-01T00:00:00Z")))
               (orchestrator.version-graph:legal-date-p "2026-01-01")))

;;; ─────────── ΜΕΡΟΣ Β: ΠΛΗΡΕΣ HTTP E2E πάνω στο ΠΡΑΓΜΑΤΙΚΟ syntagma ───────────

(format t "~%  … κατασκευή syntagma runtime (πραγματικός γράφος + provider) …~%")
;; καθαρό store για τα 6 σώματα δεν χρειάζεται — μας αρκεί το syntagma journal
(let ((dir (orchestrator.paths:institution-dir "deployment/data/version-graph/")))
  (declare (ignorable dir)))
(defparameter *e2-syn-graph* (%ensure-graph "syntagma"))
(defparameter *e2-doc* (nth-value 1 (build-consolidated-for "syntagma")))

(defparameter *e2-multi*
  (orchestrator.corpus-service:make-multi-corpus-service
   (list (orchestrator.corpus-service:make-corpus-runtime
          :name "constitution" :corpus-id "syntagma"
          :doc-provider (lambda (&optional as-of)
                          (if as-of (document-as-of "syntagma" as-of) *e2-doc*))
          :as-known-provider (%as-known-provider-for "syntagma"))
         ;; σώμα με ΣΠΑΣΜΕΝΟ παλιό provider — το /as-known του ΔΕΝ επιτρέπεται
         ;; να εξαρτάται από αυτόν (Κ1 route-first)
         (orchestrator.corpus-service:make-corpus-runtime
          :name "broken" :corpus-id "syntagma"
          :doc-provider (lambda (&optional as-of)
                          (declare (ignore as-of))
                          (error "ο παλιός consolidated provider ΚΑΗΚΕ"))
          :as-known-provider (%as-known-provider-for "syntagma")))))

(defparameter *e2-h* (orchestrator.corpus-service:multi-service-handler *e2-multi*))

(defun e2-req (path)
  (let* ((qpos (position #\? path))
         (pure (if qpos (subseq path 0 qpos) path))
         (query (when qpos
                  (loop for kv in (uiop:split-string (subseq path (1+ qpos)) :separator '(#\&))
                        for eq = (position #\= kv)
                        when eq collect (cons (subseq kv 0 eq) (subseq kv (1+ eq)))))))
    (orchestrator.http:make-http-request :method "GET" :path pure :query query)))
(defun e2-get (path) (funcall *e2-h* (e2-req path)))
(defun e2-status (r) (orchestrator.http:http-response-status r))
(defun e2-body-of (r) (orchestrator.http:http-response-body r))
(defun e2-json (r)
  "Κάθε /as-known απάντηση ΠΕΡΝΑ από πραγματικό JSON parser (Υ4 lock)."
  (jonathan:parse (e2-body-of r) :as :alist))

;;; ⑥ Δύο known-at μέσα από ΟΛΟ το stack ⇒ διαφορετικές ορθές απαντήσεις
(e2-check "⑥ /as-known άρθρο 2, known ΤΩΡΑ ⇒ 200, basis complete, valid_from 1975-06-11 (JSON-parsed)"
          (let ((r (e2-get "/constitution/as-known?article=2&valid=2020-01-01&known=9999-12-31T23:59:59Z")))
            (and (= 200 (e2-status r))
                 (let ((j (e2-json r)))
                   (and (equal "complete" (cdr (assoc "basis" j :test #'string=)))
                        (equal "1975-06-11" (cdr (assoc "valid_from" j :test #'string=)))
                        (plusp (length (cdr (assoc "text" j :test #'string=)))))))))
(e2-check "⑥β ΙΔΙΟ άρθρο, known 2001 (πριν το import) ⇒ 404 «καμία έκδοση» — το σύστημα ΔΕΝ το ήξερε τότε"
          (let ((r (e2-get "/constitution/as-known?article=2&valid=2020-01-01&known=2001-01-01T00:00:00Z")))
            (and (= 404 (e2-status r))
                 (search "no version covers" (e2-body-of r))
                 (e2-json r))))
(e2-check "⑥γ άρθρο 16, valid 1990, known ΤΩΡΑ ⇒ 422 δηλωμένη αβεβαιότητα (κενό γνώσης) — JSON parsed"
          (let ((r (e2-get "/constitution/as-known?article=16&valid=1990-01-01&known=9999-12-31T23:59:59Z")))
            (and (= 422 (e2-status r))
                 (let ((j (e2-json r)))
                   (search "temporal uncertainty" (cdr (assoc "error" j :test #'string=)))))))
(e2-check "⑥δ άρθρο 16, valid 1990, known 2001 (το κενό ΔΕΝ ήταν καταγεγραμμένο) ⇒ 404 όχι 422 (Υ2 στο HTTP)"
          (let ((r (e2-get "/constitution/as-known?article=16&valid=1990-01-01&known=2001-01-01T00:00:00Z")))
            (and (= 404 (e2-status r)) (e2-json r))))

;;; ⑦ [Υ1 boundary] Άκυρες χρονικές παράμετροι ⇒ typed 400, ΠΟΤΕ 500
(e2-check "⑦ valid=2026-99-99 ⇒ 400 (JSON-parsed, με why)"
          (let ((r (e2-get "/constitution/as-known?article=2&valid=2026-99-99&known=9999-12-31T23:59:59Z")))
            (and (= 400 (e2-status r))
                 (cdr (assoc "why" (e2-json r) :test #'string=)))))
(e2-check "⑦β known=zzzz ⇒ 400 typed"
          (= 400 (e2-status (e2-get "/constitution/as-known?article=2&valid=2020-01-01&known=zzzz"))))
(e2-check "⑦γ [κριτής Ε1] fullwidth ψηφίο στο known ⇒ 400 (ΟΧΙ 200 με μη-canonical string στην απάντηση)"
          (= 400 (e2-status
                  (e2-get (concatenate 'string
                                       "/constitution/as-known?article=2&valid=2020-01-01&known="
                                       (string (code-char #xFF12)) "026-01-01T00:00:00Z")))))

;;; ⑧ [Κ1] Ο παλιός provider ΚΑΙΓΕΤΑΙ — το /as-known μένει πράσινο
(e2-check "⑧ route-first: /broken/as-known ⇒ 200 ενώ ο consolidated provider σκάει"
          (let ((r (e2-get "/broken/as-known?article=2&valid=2020-01-01&known=9999-12-31T23:59:59Z")))
            (and (= 200 (e2-status r)) (e2-json r))))
(e2-check "⑧β έλεγχος αντίθεσης: /broken/corpus.jsonl πράγματι αποτυγχάνει (ο provider ΕΙΝΑΙ σπασμένος)"
          (handler-case (progn (e2-get "/broken/corpus.jsonl") nil)
            (error () t)))
(e2-check "⑧γ /broken/robots.txt ⇒ 200 (κανένα route χωρίς ανάγκη doc δεν αγγίζει τον provider)"
          (= 200 (e2-status (e2-get "/broken/robots.txt"))))

;;; ⑨ [Φ6] ΘΑΝΑΤΟΙ με grep-gate: οι νεκρές temporal έδρες ΔΕΝ ανασταίνονται
(format t "~%── [0088 Φ6] Θάνατοι παλαιών temporal εδρών ──~%")
(e2-check "⑨ eli-temporal-metadata: αρχείο ΔΙΑΓΡΑΜΜΕΝΟ, πακέτο ΑΝΥΠΑΡΚΤΟ (η δεύτερη πηγή amendments νεκρή)"
          (and (not (probe-file (orchestrator.paths:institution-dir "source/eli-temporal-metadata.lisp")))
               (not (find-package :orchestrator.eli-temporal))))
(e2-check "⑨β consolidate: ΚΑΜΙΑ αναφορά-κλήση στο νεκρό fallback (μόνο config = η ΜΙΑ πηγή)"
          (let ((src (uiop:read-file-string
                      (orchestrator.paths:institution-dir
                       "systems/orchestrator-engine-sbcl/stages/consolidate.lisp")
                      :external-format :utf-8)))
            (not (search "(find-package :orchestrator.eli-temporal" src))))
(e2-check "⑨γ legal-temporal: η L3 versioning μηχανή ΝΕΚΡΗ (temporal-version/point-in-time/allen απόντα)· η ημερολογιακή αριθμητική ΖΕΙ"
          (and (null (find-symbol "MAKE-TEMPORAL-VERSION" :orchestrator.temporal))
               (null (find-symbol "POINT-IN-TIME" :orchestrator.temporal))
               (null (find-symbol "ALLEN-RELATION" :orchestrator.temporal))
               (find-symbol "DATE-PLUS-DAYS" :orchestrator.temporal)
               (equal "2026-03-01"
                      (funcall (find-symbol "DATE-PLUS-DAYS" :orchestrator.temporal)
                               "2026-02-28" 1))))

(format t "~%========================================~%")
(format t "AS-KNOWN-E2E [0088 #9]: ~D passed, ~D failed~%" *e2-pass* *e2-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *e2-fail*) 0 1))
