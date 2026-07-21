;;;; tests/capability-gate-test.lisp
;;;; ============================================================================
;;;; [ΤΑΒΑΝΙ #1] CAPABILITY RATCHET LOCK — το ΜΕΤΡΟ φυλάσσεται από πύλη
;;;; ============================================================================
;;;; Κλειδώνει: (α) ντετερμινισμό της ΜΙΑΣ έδρας μετρικών· (β) πράσινο της πύλης
;;;; απέναντι στο ΠΡΑΓΜΑΤΙΚΟ committed baseline· (γ) ΟΛΑ τα fail-closed μονοπάτια
;;;; με αρνητικά fixtures (οπισθοδρόμηση, drift dataset, απόν baseline — το
;;;; τελευταίο ήταν ΠΡΑΓΜΑΤΙΚΟ false-green που έπιασε το proof και κλείστηκε
;;;; στην έδρα)· (δ) auto-membership στην ολομέλεια + registry 25 + ισότητα
;;;; runtime-set ≡ registry. Τρέχει με φορτωμένο orchestrator-cli.

(in-package :orchestrator.cli)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %cg-quiet (fn)
  (let* ((o (make-string-output-stream))
         (c (let ((*standard-output* o)) (funcall fn))))
    (values c (get-output-stream-string o))))

(format t "~%== [ΤΑΒΑΝΙ #1] Ντετερμινισμός + committed baseline ==~%")
(let ((m1 (%capability-metrics))
      (m2 (%capability-metrics)))
  (check "%capability-metrics ντετερμινιστικό (2 runs EQUAL)" (equal m1 m2))
  (check "scorecard schema :capability-scorecard/1"
         (eq :capability-scorecard/1 (getf m1 :schema)))
  (check "① μηχανή-σε-gold = 100% (ο νόμος του gold)"
         (let ((ev (getf m1 :legal-eval)))
           (= (getf ev :engine-ok) (getf ev :engine-total)))))
(multiple-value-bind (c out) (%cg-quiet #'run-capability-gate)
  (check "--capability-gate vs COMMITTED baseline ⇒ ΠΡΑΣΙΝΟ (0)" (eql 0 c))
  (check "…εκπέμπει machine-readable scorecard (anchors)"
         (and (search "CAPABILITY-SCORECARD" out) (search "END-SCORECARD" out))))

(format t "~%== [ΤΑΒΑΝΙ #1] Fail-closed μονοπάτια (αρνητικά fixtures) ==~%")
(let ((tmp (merge-pathnames (format nil "cap-base-test-~D.sexp" (get-universal-time))
                            (uiop:temporary-directory))))
  (unwind-protect
       (let ((*capability-baseline-path* tmp))
         ;; φρέσκο baseline στο temp ⇒ πράσινο
         (%cg-quiet (lambda () (run-capability-baseline "2026-07-21")))
         (check "temp baseline ⇒ πύλη πράσινη"
                (eql 0 (%cg-quiet #'run-capability-gate)))
         ;; TAMPER: hit1+1 (ανέφικτο) ⇒ ΚΟΚΚΙΝΟ με «ΟΠΙΣΘΟΔΡΟΜΗΣΗ»
         (let* ((b (orchestrator.safe-read:read-data-file tmp))
                (jd (copy-list (getf b :judge)))
                (b2 (copy-list b)))
           (setf (getf jd :hit1) (1+ (getf jd :hit1))
                 (getf b2 :judge) jd)
           (orchestrator.journal:write-file-atomic
            tmp (orchestrator.safe-read:data-to-string b2)))
         (multiple-value-bind (c out) (%cg-quiet #'run-capability-gate)
           (check "οπισθοδρόμηση (baseline hit1+1) ⇒ ΚΟΚΚΙΝΟ" (eql 1 c))
           (check "…με ρητή αιτία ΟΠΙΣΘΟΔΡΟΜΗΣΗ" (and (search "ΟΠΙΣΘΟΔΡΟΜΗΣΗ" out) t)))
         ;; STAMP DRIFT ⇒ ΚΟΚΚΙΝΟ με «drift νομολογίας»
         (%cg-quiet (lambda () (run-capability-baseline "2026-07-21")))
         (let* ((b (orchestrator.safe-read:read-data-file tmp))
                (b2 (copy-list b)))
           (setf (getf b2 :judge-dataset-stamp) "sha256:deadbeef")
           (orchestrator.journal:write-file-atomic
            tmp (orchestrator.safe-read:data-to-string b2)))
         (multiple-value-bind (c out) (%cg-quiet #'run-capability-gate)
           (check "dataset drift ⇒ ΚΟΚΚΙΝΟ" (eql 1 c))
           (check "…με ρητή αιτία drift νομολογίας" (and (search "drift νομολογίας" out) t)))
         ;; ΑΠΟΝ baseline ⇒ ΚΟΚΚΙΝΟ (το false-green που κλείστηκε στην έδρα)
         (delete-file tmp)
         (check "ΑΠΟΝ baseline ⇒ ΚΟΚΚΙΝΟ — ποτέ σιωπηλό πράσινο με μηδέν ελέγχους"
                (eql 1 (%cg-quiet #'run-capability-gate))))
    (ignore-errors (delete-file tmp))))

(format t "~%== [ΤΑΒΑΝΙ #1] Ολομέλεια + registry ==~%")
(let ((names '()))
  (maphash (lambda (k v) (declare (ignore v))
             (when (and (> (length k) 5)
                        (string= "-gate" k :start2 (- (length k) 5)))
               (push k names)))
           *commands*)
  (check "«--capability-gate» μέλος της ολομέλειας (auto-membership)"
         (and (member "--capability-gate" names :test #'string=) t))
  (let ((reg (orchestrator.safe-read:read-data-file
              (merge-pathnames "deployment/verify/gate-registry.sexp"
                               (orchestrator.paths:institution-root)))))
    (check "registry 25 πύλες, περιέχει :capability-gate"
           (and (= 25 (length (getf reg :gates)))
                (member :capability-gate (getf reg :gates)) t))
    (check "runtime gate-set ≡ registry (ακριβής ισότητα συνόλων)"
           (equal (sort (mapcar (lambda (n)
                                  (intern (string-upcase (string-left-trim "-" n)) :keyword))
                                names)
                        #'string< :key #'symbol-name)
                  (sort (copy-list (getf reg :gates)) #'string< :key #'symbol-name)))))

(format t "~%========================================~%")
(format t "CAPABILITY-GATE tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
