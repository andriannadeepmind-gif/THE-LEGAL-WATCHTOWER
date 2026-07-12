;;;; tests/capability-api-test.lisp
;;;; Transport-agnostic API-projection: /api/<name> → typed coercion → invoke.
;;;; Δρομολόγηση, coercion τύπων (query strings), fail-closed statuses, catalog.

(in-package :orchestrator.capability-api)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(clrhash orchestrator.capability:*capabilities*)
(orchestrator.capability:define-capability :ask
  :summary "δοκιμαστική ask" :params ((:q :string t)) :result :string :trust :trusted
  :fn (lambda (&key q) (format nil "απάντηση: ~A" q)))
(orchestrator.capability:define-capability :add
  :summary "άθροισμα" :params ((:a :integer t) (:b :integer t)) :result :integer :trust :trusted
  :fn (lambda (&key a b) (+ a b)))
(orchestrator.capability:define-capability :flag
  :summary "boolean" :params ((:on :boolean t)) :result :boolean :trust :advisor
  :fn (lambda (&key on) (if on "ΑΝΟΙΧΤΟ" "ΚΛΕΙΣΤΟ")))

(format t "~%== [1] δρομολόγηση + επιτυχία ==~%")
(multiple-value-bind (st pl) (api-dispatch "/api/ask" '(("q" . "γεια")))
  (ck "200 σε έγκυρο /api/ask" (and (eql 200 st) (string= "απάντηση: γεια" (getf pl :result))))
  (ck "payload φέρει trust" (string= "trusted" (getf pl :trust))))
(multiple-value-bind (st pl) (api-dispatch "/chat" nil)
  (declare (ignore pl))
  (ck "μη-/api → :not-api" (eq :not-api st)))

(format t "~%== [2] coercion τύπων (query strings → typed) ==~%")
(multiple-value-bind (st pl) (api-dispatch "/api/add" '(("a" . "40") ("b" . "2")))
  (ck "integer coercion: 40+2=42" (and (eql 200 st) (eql 42 (getf pl :result)))))
(multiple-value-bind (st pl) (api-dispatch "/api/flag" '(("on" . "ναι")))
  (ck "boolean coercion «ναι»→t" (and (eql 200 st) (string= "ΑΝΟΙΧΤΟ" (getf pl :result)))))
(multiple-value-bind (st pl) (api-dispatch "/api/flag" '(("on" . "0")))
  (ck "boolean coercion «0»→nil" (and (eql 200 st) (string= "ΚΛΕΙΣΤΟ" (getf pl :result)))))

(format t "~%== [3] fail-closed statuses ==~%")
(multiple-value-bind (st pl) (api-dispatch "/api/nope" nil)
  (ck "404 σε άγνωστη δυνατότητα" (and (eql 404 st) (getf pl :error))))
(multiple-value-bind (st pl) (api-dispatch "/api/ask" nil)
  (ck "400 σε λείπον υποχρεωτικό" (and (eql 400 st) (getf pl :error))))
(multiple-value-bind (st pl) (api-dispatch "/api/add" '(("a" . "χ") ("b" . "2")))
  (ck "400 σε άκυρο integer (όχι crash)" (and (eql 400 st) (getf pl :error))))

(format t "~%== [4] catalog (αυτο-περιγραφή για UI/MCP) ==~%")
(multiple-value-bind (st pl) (api-catalog)
  (let ((caps (getf pl :capabilities)))
    (ck "200 + 3 δυνατότητες" (and (eql 200 st) (= 3 (length caps))))
    (ck "ντετερμινιστική σειρά (add,ask,flag)"
        (equal '("add" "ask" "flag") (mapcar (lambda (c) (getf c :name)) caps)))
    (ck ":flag δηλώνεται advisor"
        (string= "advisor" (getf (find "flag" caps :key (lambda (c) (getf c :name)) :test #'string=) :trust)))))

(format t "~%== [5] require-trust: ΔΟΜΙΚΗ επιβολή «κανένα advisor σε trusted επιφάνεια» ==~%")
;; Χωρίς require-trust: advisor εκτελείται (η projection είναι γενική υποδομή) — ίδιο με [2].
(multiple-value-bind (st pl) (api-dispatch "/api/flag" '(("on" . "ναι")))
  (ck "χωρίς require-trust: advisor :flag εκτελείται (200)" (and (eql 200 st) (getf pl :result))))
;; Με require-trust t (ό,τι περνά ο cockpit): advisor ΑΡΝΕΙΤΑΙ (403) — δεν φτάνει στο :fn.
(multiple-value-bind (st pl) (api-dispatch "/api/flag" '(("on" . "ναι")) :require-trust t)
  (ck "require-trust t: advisor :flag → 403 (δεν εκτελείται)"
      (and (eql 403 st) (getf pl :error))))
;; Με require-trust t: trusted δυνατότητα περνά κανονικά.
(multiple-value-bind (st pl) (api-dispatch "/api/add" '(("a" . "40") ("b" . "2")) :require-trust t)
  (ck "require-trust t: trusted :add περνά (200)" (and (eql 200 st) (eql 42 (getf pl :result)))))
;; catalog με require-trust t: ΔΕΝ διαφημίζει advisor caps (καμία διαρροή ύπαρξης).
(multiple-value-bind (st pl) (api-catalog :require-trust t)
  (let ((names (mapcar (lambda (c) (getf c :name)) (getf pl :capabilities))))
    (ck "catalog require-trust t: μόνο trusted (add,ask· όχι flag)"
        (and (eql 200 st) (equal '("add" "ask") names)))))

(format t "~%========================================~%")
(format t "capability-api: ~D passed, ~D failed~%" *p* *f*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *f*) 0 1))
