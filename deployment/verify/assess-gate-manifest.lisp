;;;; deployment/verify/assess-gate-manifest.lisp
;;;; ============================================================================
;;;; MACHINE-READABLE GATE-PLENARY MANIFEST ASSESSOR ([κύκλος-2 #7])
;;;; ============================================================================
;;;; Η ΑΝΩΤΑΤΗ μορφή της κρίσης ολομέλειας: ΟΧΙ text-grep πάνω σε «gate: ΠΕΡΑΣΕ» γραμμές
;;;; (που δεν ελέγχει duplicates/exact-set/completion), αλλά parse του canonical data-only
;;;; manifest (:gate-plenary/1) που εκπέμπει το run-all-gates, με ΑΥΣΤΗΡΟ enforcement:
;;;;   • :completed t   — θετική απόδειξη ολοκλήρωσης (crash στη μέση ⇒ κανένα manifest ⇒ FAIL)·
;;;;   • ΑΚΡΙΒΗΣ set-equality με το canonical gate-registry.sexp (καμία λείπει/επιπλέον)·
;;;;   • κανένα duplicate gate·
;;;;   • ΑΚΡΙΒΩΣ μία ετυμηγορία ∈ {:passed :failed} ανά πύλη·
;;;;   • baseline exceptions (π.χ. advisor-gate env-only) — δηλωμένες, ΟΧΙ σιωπηλές·
;;;;   • ο πραγματικός docker exit περνιέται ΞΕΧΩΡΙΣΤΑ (αν != 0 ⇒ FAIL, όπως ο plenary assessor).
;;;;
;;;; Χρήση: sbcl --script assess-gate-manifest.lisp <gates-log> <docker-exit> [registry] [baseline-csv]
;;;; Εξοδος: κωδικός 0 = PASS· μη-μηδενικός = διακριτή αιτία (CI false-green killer).
;;;; Self-contained: μικρός data-only reader (*read-eval* nil + #-deny) — καμία εξάρτηση.

(in-package :cl-user)

(defun die (code fmt &rest args)
  (format *error-output* "~&assess-gate-manifest: ~A~%" (apply #'format nil fmt args))
  (sb-ext:exit :code code))

;; ── μικρή data-only ανάγνωση (ίδιες εγγυήσεις με safe-read: *read-eval* nil + #-deny) ──
(defun %deny (s c) (declare (ignore s c)) (error "reader-macro εκτός data-only"))
(defparameter +rt+
  (let ((rt (copy-readtable nil)))
    (set-macro-character #\# #'%deny t rt)
    (set-macro-character #\` #'%deny nil rt)
    (set-macro-character #\' #'%deny nil rt)
    rt))
(defun read-data (string)
  (let ((*read-eval* nil) (*readtable* +rt+) (*package* (find-package :keyword))
        (*read-default-float-format* 'double-float))
    (with-input-from-string (s string) (read s nil nil))))

(defun slurp (path)
  (with-open-file (s path :external-format :utf-8 :if-does-not-exist nil)
    (unless s (return-from slurp nil))
    (let ((buf (make-string (file-length s)))) (subseq buf 0 (read-sequence buf s)))))

;; ── extract το manifest string ανάμεσα στα anchors (line-anchored) ──
(defparameter +begin+ "════ GATE-PLENARY-MANIFEST ════")
(defparameter +end+ "════ END-MANIFEST ════")
(defun extract-manifest (log)
  (let ((b (search +begin+ log)))
    (unless b (die 3 "απών GATE-PLENARY-MANIFEST anchor (καμία απόδειξη ολοκλήρωσης — πιθανό crash)"))
    (let* ((after (+ b (length +begin+)))
           (e (search +end+ log :start2 after)))
      (unless e (die 3 "απών END-MANIFEST anchor (κολοβό manifest)"))
      (string-trim '(#\Space #\Tab #\Newline #\Return) (subseq log after e)))))

(defun getf* (pl k) (getf pl k))

(let* ((args (cdr sb-ext:*posix-argv*))
       (log-path (or (first args) (die 2 "usage: <gates-log> <docker-exit> [registry] [baseline-csv]")))
       (docker-exit-str (or (second args) (die 2 "λείπει το docker-exit όρισμα")))
       (registry-path (or (third args) "deployment/verify/gate-registry.sexp"))
       (baseline (let ((s (fourth args)))
                   (when (and s (plusp (length s)))
                     (mapcar (lambda (x) (intern (string-upcase (string-trim " " x)) :keyword))
                             (loop with start = 0 for pos = (position #\, s :start start)
                                   collect (subseq s start pos) while pos do (setf start (1+ pos))))))))
  ;; 0. πραγματικός docker exit (περνιέται ΞΕΧΩΡΙΣΤΑ — crash δεν κρύβεται πίσω από manifest)
  (let ((dex (or (ignore-errors (parse-integer docker-exit-str)) (die 2 "μη-αριθμητικό docker-exit"))))
    (unless (zerop dex) (die 4 "docker exit=~D (η ολομέλεια δεν ολοκληρώθηκε καθαρά)" dex)))
  ;; 1. canonical registry
  (let* ((reg-str (or (slurp registry-path) (die 2 "απών gate-registry: ~A" registry-path)))
         (reg (read-data reg-str))
         (canonical (getf* reg :gates)))
    (unless (eq (getf* reg :schema) :gate-registry/1) (die 2 "gate-registry: άγνωστο schema"))
    (unless (and (listp canonical) canonical) (die 2 "gate-registry: κενό :gates"))
    ;; 2. manifest από το log
    (let* ((log (or (slurp log-path) (die 2 "απών gates-log: ~A" log-path)))
           (m (read-data (extract-manifest log))))
      (unless (eq (getf* m :schema) :gate-plenary/1) (die 3 "manifest: άγνωστο schema"))
      (let ((pl m))
        ;; υπό *package* :keyword το γραμμένο `t` διαβάζεται ως :T (canonicalize bool)
        (unless (member (getf* pl :completed) '(t :t)) (die 3 "manifest: :completed δεν είναι T"))
        (let* ((results (getf* pl :results))
               (gates (mapcar #'first results)))
          (unless (listp results) (die 3 "manifest: :results δεν είναι λίστα"))
          ;; 3. κανένα duplicate
          (unless (= (length gates) (length (remove-duplicates gates)))
            (die 5 "manifest: duplicate gate στα :results"))
          ;; 4. ακριβώς μία ετυμηγορία ∈ {:passed :failed} ανά πύλη
          (dolist (r results)
            (unless (and (consp r) (= 2 (length r)) (keywordp (first r))
                         (member (second r) '(:passed :failed)))
              (die 5 "manifest: κακοσχηματισμένη εγγραφή ~S (περίμενα (:gate :passed|:failed))" r)))
          ;; 5. ΑΚΡΙΒΗΣ set-equality με canonical registry
          (let ((missing (set-difference canonical gates))
                (extra (set-difference gates canonical)))
            (when missing (die 6 "manifest: ΛΕΙΠΟΥΝ πύλες vs registry: ~S" missing))
            (when extra (die 6 "manifest: ΕΠΙΠΛΕΟΝ πύλες vs registry: ~S" extra)))
          ;; 6. ετυμηγορίες: κάθε :failed πρέπει να είναι δηλωμένη baseline-exception, αλλιώς FAIL
          (let ((unexpected-failed
                  (loop for (g v) in results
                        when (and (eq v :failed) (not (member g baseline))) collect g)))
            (when unexpected-failed
              (die 7 "ΑΠΕΤΥΧΑΝ πύλες εκτός baseline: ~S (baseline: ~S)" unexpected-failed baseline)))
          (format t "~&assess-gate-manifest: PASS — ~D πύλες, set-equality με registry, ~
                     completed=T, docker-exit=0~@[, baseline-failed=~S~]~%"
                  (length gates) (intersection baseline (mapcar #'first
                                   (remove-if-not (lambda (r) (eq (second r) :failed)) results))))
          (sb-ext:exit :code 0))))))
