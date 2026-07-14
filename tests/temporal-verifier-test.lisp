;;;; tests/temporal-verifier-test.lisp
;;;; ============================================================================
;;;; [0088 Φ7 Π6] N-VERSION AGREEMENT GATE: η Lisp έδρα παράγει vectors
;;;; (canon-sexp, date+, condition-ids, sat, event/regime hashes, attestation)
;;;; και ο ΑΝΕΞΑΡΤΗΤΟΣ pure-stdlib python verifier (deployment/verify/
;;;; verify-temporal.py) τα ΕΠΑΝΥΠΟΛΟΓΙΖΕΙ από το spec — κάθε διαφωνία FAIL.
;;;; Χωρίς python3: ΡΗΤΟ SKIP (στο docker το gate είναι σκληρό — python3 παρόν).
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *tv-pass* 0)
(defvar *tv-fail* 0)

(defmacro tv-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *tv-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *tv-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *tv-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0088 Φ7 Π6] TEMPORAL N-VERSION AGREEMENT (Lisp ⇄ python) ──~%")

;;; ── JSON emitter (ελάχιστος, για τα vectors — strings με πλήρες escaping) ──
(defun %tvj-esc (s)
  (with-output-to-string (o)
    (loop for c across s
          do (cond ((char= c #\") (write-string "\\\"" o))
                   ((char= c #\\) (write-string "\\\\" o))
                   ((< (char-code c) 32) (format o "\\u~4,'0X" (char-code c)))
                   (t (write-char c o))))))

(defun %tvj-sx (x)
  "Tagged JSON αναπαράσταση sexp τιμής (συμβόλαιο του verify-temporal.py)."
  (etypecase x
    (null "{\"t\":\"nil\"}")
    (keyword (format nil "{\"t\":\"kw\",\"v\":\"~A\"}" (%tvj-esc (symbol-name x))))
    (string (format nil "{\"t\":\"s\",\"v\":\"~A\"}" (%tvj-esc x)))
    (integer (format nil "{\"t\":\"i\",\"v\":~D}" x))
    (cons (format nil "{\"t\":\"l\",\"v\":[~{~A~^,~}]}" (mapcar #'%tvj-sx x)))))

(defun %tvj-str (s) (format nil "\"~A\"" (%tvj-esc s)))
(defun %tvj-arr (items) (format nil "[~{~A~^,~}]" items))

(defun %tv-canon (x)
  (with-output-to-string (o) (orchestrator.version-graph::%canon-sexp x o)))

;;; ── Πραγματικός μίνι-γράφος για sat/attestation vectors (body 9993) ──
(defparameter *tv-body*
  (orchestrator.identity:body-id-string
   (orchestrator.identity:make-body :gr :nomos :year 2020 :number 9993 :slug "tv-p6")))
(let ((p (orchestrator.version-graph::%graph-path *tv-body*)))
  (when (probe-file p) (delete-file p)))
(defparameter *tv-g* (orchestrator.version-graph::make-graph *tv-body*))
(defparameter *tv-pid* "gr/nomos/2020/9993#art:1")
(defparameter *tv-ref* "ya-per:gr/nomos/2020/9993#art:1")
(defparameter *tv-cond*
  (orchestrator.version-graph:declare-condition!
   *tv-g* (orchestrator.version-graph:make-effectivity-condition
           :suspensive (list :instrument-event :ya *tv-ref*))))
(defparameter *tv-cid* (orchestrator.version-graph:condition-id *tv-cond*))
(defparameter *tv-v1*
  (multiple-value-bind (e vs)
      (orchestrator.version-graph::admit-edge!
       *tv-g* (list :op :insert :target *tv-pid* :from-versions nil
                    :to-specs (list (list :provision-id *tv-pid* :text "Κείμενο v1 «αρχικό»"
                                          :heading nil :valid-from "2026-01-01"
                                          :status :in-force :assurance :verified))
                    :act-ref "gr/nomos/2020/9993" :act-internal-seq 1
                    :enacted "2026-01-01" :effective "2026-01-01"
                    :fek-date "2026-01-01" :assurance :verified :confidence 100))
    (declare (ignore e)) (first vs)))
(orchestrator.version-graph::admit-edge!
 *tv-g* (list :op :replace :target *tv-pid*
              :from-versions (list (orchestrator.version-graph::tv-version-hash *tv-v1*))
              :to-specs (list (list :provision-id *tv-pid* :text "Κείμενο v2 υπό αίρεση"
                                    :heading nil
                                    :commencement (list :conditional *tv-cid*)
                                    :status :not-yet-effective :assurance :verified))
              :act-ref "gr/nomos/2026/0100" :act-internal-seq 1
              :enacted "2026-02-01" :effective (list :conditional *tv-cid*)
              :fek-date "2026-02-01" :assurance :verified :confidence 100))
(orchestrator.version-graph:record-condition-event!
 *tv-g* *tv-cid* :kind :ya :ref *tv-ref* :outcome :satisfied
 :at "2026-03-10" :evidence '(:source-digest "sha256:tv") :verifier "tv")
(orchestrator.version-graph:admit-regime-edge!
 *tv-g* :op :suspend :target *tv-pid*
 :span-from "2026-07-01" :span-until "2026-08-01"
 :act-ref "gr/ya/2026/900" :act-seq 1 :enacted "2026-06-20" :fek-date "2026-06-20")

;;; ── Δόμηση vectors ──
(defparameter *tv-ev*
  '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-03-10")
    (:kind :ratification :ref "ΠΝΠ-1" :outcome :refuted :at "2026-05-01")))

(defun %tv-ev-json (e &key cid)
  (format nil "{\"kind\":~A,\"ref\":~A,\"outcome\":~A,\"at\":~A~@[,\"cid\":~A~]}"
          (%tvj-str (string-downcase (symbol-name (getf e :kind))))
          (%tvj-str (getf e :ref))
          (%tvj-str (string-downcase (symbol-name (getf e :outcome))))
          (%tvj-str (getf e :at))
          (and cid (%tvj-str cid))))

(defun %tv-sat-json (ast events &key cid expect)
  "Vector sat: expect από ΤΗΝ ΕΔΡΑ (ή [\"error\"])."
  (let ((exp (or expect
                 (multiple-value-bind (st at)
                     (apply #'orchestrator.version-graph:sat ast events
                            (when cid (list :condition-id cid)))
                   (if at
                       (%tvj-arr (list (%tvj-str (string-downcase (symbol-name st)))
                                       (%tvj-str at)))
                       (%tvj-arr (list (%tvj-str (string-downcase (symbol-name st))))))))))
    (format nil "{\"ast\":~A,\"events\":~A~@[,\"cid\":~A~],\"expect\":~A}"
            (%tvj-sx ast)
            (%tvj-arr (mapcar (lambda (e) (%tv-ev-json e :cid (getf e :condition-id))) events))
            (and cid (%tvj-str cid))
            exp)))

(defparameter *tv-vectors-path* "/tmp/lawmax-temporal-vectors.json")

(let* ((canon-cases
         (list nil :ya "απλό" "με \"quotes\" και \\backslash" 42
               (list :and (list :date-reached "2027-01-01") "μικτό" 7)))
       (dateplus-cases
         '(("2026-01-15" "days" 10) ("2026-01-15" "months" 1)
           ("2026-01-31" "months" 1) ("2024-01-31" "months" 1)
           ("2026-11-30" "months" 3) ("2024-02-29" "years" 1)
           ("2026-12-25" "days" 10) ("2023-02-28" "years" 1)))
       (cid-asts
         (list (list :suspensive '(:and (:date-reached "2027-01-01")
                                        (:instrument-event :ya "ΥΑ-1")
                                        (:date-reached "2027-01-01")))
               (list :resolutory '(:instrument-event :ratification "ΠΝΠ-1"))
               (list :suspensive '(:or (:instrument-event :ya "ΥΑ-1")
                                       (:after (:months 6) (:date-reached "2026-01-15"))))))
       (json
         (with-output-to-string (o)
           (format o "{\"canon\":~A,"
                   (%tvj-arr (mapcar (lambda (x)
                                       (format nil "{\"sx\":~A,\"expect\":~A}"
                                               (%tvj-sx x) (%tvj-str (%tv-canon x))))
                                     canon-cases)))
           (format o "\"dateplus\":~A,"
                   (%tvj-arr (mapcar (lambda (c)
                                       (destructuring-bind (d unit n) c
                                         (format nil "{\"date\":~A,\"unit\":~A,\"n\":~D,\"expect\":~A}"
                                                 (%tvj-str d) (%tvj-str unit) n
                                                 (%tvj-str (orchestrator.version-graph:date+
                                                            d (list (intern (string-upcase unit) :keyword) n))))))
                                     dateplus-cases)))
           (format o "\"condition_id\":~A,"
                   (%tvj-arr (mapcar (lambda (c)
                                       (destructuring-bind (class ast) c
                                         (let ((cond (orchestrator.version-graph:make-effectivity-condition class ast)))
                                           (format nil "{\"class\":~A,\"ast\":~A,\"canon\":~A,\"expect\":~A}"
                                                   (%tvj-str (string-downcase (symbol-name class)))
                                                   (%tvj-sx ast)
                                                   (%tvj-str (%tv-canon (orchestrator.version-graph:condition-ast cond)))
                                                   (%tvj-str (orchestrator.version-graph:condition-id cond))))))
                                     cid-asts)))
           (format o "\"sat\":~A,"
                   (%tvj-arr
                    (list (%tv-sat-json '(:date-reached "2026-06-01") '())
                          (%tv-sat-json '(:instrument-event :ya "ΥΑ-1") *tv-ev*)
                          (%tv-sat-json '(:instrument-event :ya "ΥΑ-999") *tv-ev*)
                          (%tv-sat-json '(:after (:months 6) (:instrument-event :ya "ΥΑ-1")) *tv-ev*)
                          (%tv-sat-json '(:or (:instrument-event :ya "ΥΑ-999")
                                              (:after (:months 6) (:date-reached "2026-01-15")))
                                        '())
                          (%tv-sat-json '(:and (:date-reached "2026-06-01")
                                               (:instrument-event :ratification "ΠΝΠ-1"))
                                        *tv-ev*)
                          ;; σύμφωνα πολλαπλά ⇒ ελάχιστο at
                          (%tv-sat-json '(:instrument-event :ya "ΥΑ-1")
                                        '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-04-01")
                                          (:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-03-10")))
                          ;; cid-scoped: ξένο cid αποκλείεται
                          (%tv-sat-json '(:instrument-event :ya "ΥΑ-1")
                                        '((:condition-id "cid-x" :kind :ya :ref "ΥΑ-1"
                                           :outcome :satisfied :at "2026-03-10"))
                                        :cid "cid-δικό"
                                        :expect "[\"pending\"]")
                          ;; αντιφατικά ⇒ error ΚΑΙ στις δύο υλοποιήσεις
                          (%tv-sat-json '(:instrument-event :ya "ΥΑ-1")
                                        '((:kind :ya :ref "ΥΑ-1" :outcome :satisfied :at "2026-03-10")
                                          (:kind :ya :ref "ΥΑ-1" :outcome :refuted :at "2026-04-01"))
                                        :expect "[\"error\"]"))))
           (let ((ed (orchestrator.version-graph::%evidence-digest '(:source-digest "sha256:tv"))))
             (format o "\"event_hash\":~A,"
                     (%tvj-arr
                      (list (format nil "{\"cid\":~A,\"kind\":\"ya\",\"ref\":~A,\"outcome\":\"satisfied\",\"at\":\"2026-03-10\",\"evidence_digest\":~A,\"expect\":~A}"
                                    (%tvj-str *tv-cid*) (%tvj-str *tv-ref*) (%tvj-str ed)
                                    (%tvj-str (orchestrator.version-graph::%condition-event-hash
                                               *tv-cid* :ya *tv-ref* :satisfied "2026-03-10" ed)))))))
           (format o "\"regime_hash\":~A,"
                   (%tvj-arr
                    (list (format nil "{\"op\":\"suspend\",\"target\":~A,\"version\":null,\"span_from\":\"2026-07-01\",\"span_until\":\"2026-08-01\",\"scope\":null,\"cid\":null,\"act_ref\":\"gr/ya/2026/900\",\"act_seq\":1,\"enacted\":\"2026-06-20\",\"fek_date\":\"2026-06-20\",\"prior\":null,\"expect\":~A}"
                                  (%tvj-str *tv-pid*)
                                  (%tvj-str (orchestrator.version-graph::%regime-hash
                                             :suspend *tv-pid* nil "2026-07-01" "2026-08-01"
                                             nil nil "gr/ya/2026/900" 1 "2026-06-20" "2026-06-20" nil)))
                          ;; [Φ7-HARDENING #2/#3] scoped + resolutory (:on-satisfaction)
                          (format nil "{\"op\":\"expire\",\"target\":~A,\"version\":\"vh-x\",\"span_from\":\"on-satisfaction\",\"span_until\":\"open\",\"scope\":{\"t\":\"l\",\"v\":[{\"t\":\"l\",\"v\":[{\"t\":\"kw\",\"v\":\"TERRITORIAL\"},{\"t\":\"kw\",\"v\":\"ATTIKI\"}]}]},\"cid\":\"cid-r\",\"act_ref\":\"gr/nomos/2026/901\",\"act_seq\":1,\"enacted\":\"2026-06-20\",\"fek_date\":\"2026-06-20\",\"prior\":null,\"expect\":~A}"
                                  (%tvj-str *tv-pid*)
                                  (%tvj-str (orchestrator.version-graph::%regime-hash
                                             :expire *tv-pid* "vh-x" :on-satisfaction :open
                                             '((:territorial :attiki)) "cid-r"
                                             "gr/nomos/2026/901" 1 "2026-06-20" "2026-06-20" nil))))))
           (flet ((att-json (valid)
                    (let* ((a (orchestrator.version-graph:make-effectivity-attestation
                               *tv-g* *tv-pid* :valid-at valid :known-at "2033-01-01T00:00:00Z"
                               :corpus-id "tv" :release-root "rr-tv" :verifier-hash "vh-tv")))
                      (format nil "{\"fields\":{\"corpus_id\":\"tv\",\"provision\":~A,\"valid_at\":~A,\"known_at\":\"2033-01-01T00:00:00Z\",\"outcome\":~A,\"condition_states\":~A,\"regime_edge_ids\":~A,\"receipt_id\":\"\",\"release_root\":\"rr-tv\",\"graph_chain_head\":~A,\"verifier_hash\":\"vh-tv\"},\"canonical\":~A,\"hash\":~A}"
                              (%tvj-str *tv-pid*) (%tvj-str valid)
                              (%tvj-arr (mapcar #'%tvj-str (getf a :outcome)))
                              (%tvj-arr (mapcar (lambda (row) (%tvj-arr (mapcar #'%tvj-str row)))
                                                (getf a :condition-states)))
                              (%tvj-arr (mapcar #'%tvj-str (getf a :regime-edge-ids)))
                              (%tvj-str (getf a :graph-chain-head))
                              (%tvj-str (getf a :canonical))
                              (%tvj-str (getf a :hash))))))
             (format o "\"attestation\":~A}"
                     (%tvj-arr (list (att-json "2026-06-01")      ; resolved
                                     (att-json "2026-07-15"))))))))  ; suspended
  (with-open-file (s *tv-vectors-path* :direction :output :if-exists :supersede
                     :if-does-not-exist :create :external-format :utf-8)
    (write-string json s)))

(tv-check "① vectors γράφτηκαν από τις έδρες (canon/date+/ids/sat/hashes/attestation ×2)"
          (probe-file *tv-vectors-path*))

;;; ── Εκτέλεση του ανεξάρτητου python verifier ──
(let ((py (ignore-errors
            (uiop:run-program (list "python3" "--version")
                              :output :string :ignore-error-status t))))
  (if (null py)
      (progn
        (format t "  SKIP python3 ΑΠΟΝ σε αυτό το περιβάλλον — το N-version gate~%")
        (format t "       τρέχει ΣΚΛΗΡΟ στο docker (python3 εγκατεστημένο εκεί).~%"))
      (multiple-value-bind (out err code)
          (uiop:run-program
           (list "python3"
                 (namestring (orchestrator.paths:institution-dir
                              "deployment/verify/verify-temporal.py"))
                 *tv-vectors-path*)
           :output :string :error-output :string :ignore-error-status t)
        (format t "~A" out)
        (tv-check "② N-VERSION AGREEMENT: python επανυπολογισμός ΟΛΩΝ ⇒ 0 διαφωνίες"
                  (and (zerop code) (search "0 διαφωνίες" out)))
        (when (plusp code)
          (format t "  python stderr: ~A~%" err)))))

(format t "~%========================================~%")
(format t "TEMPORAL-VERIFIER [0088 Φ7 Π6]: ~D passed, ~D failed~%" *tv-pass* *tv-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *tv-fail*) 0 1))
