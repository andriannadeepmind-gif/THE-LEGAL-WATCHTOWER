;;;; systems/orchestrator-cli/provenance-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΠΡΟΕΛΕΥΣΗΣ — «static knowledge χωρίς runtime trace = μισή αυτοεπίγνωση»
;;;; ============================================================================
;;;;
;;;; Καταναλωτής των orchestrator.trace/provenance (πηγή αλήθειας)· εδώ οι όψεις
;;;; CLI (--trace-*) και το κλείδωμα: ΖΩΝΤΑΝΗ απόδειξη ότι συμπέρασμα, ανάκληση
;;;; έννομης κατάστασης, επαλήθευση, ταυτότητα άρθρου, τέχνημα, σκιά/υιοθέτηση
;;;; και εντολές αφήνουν ίχνος δεμένο σε συμβόλαιο/συστατικό/απόδειξη — και
;;;; ΑΡΝΗΤΙΚΑ: πλαστά/ξεπερασμένα/ανιχνοθέτητα ίχνη πιάνονται, αλλιώς κόκκινο.

(in-package :orchestrator.cli)

;;; ── ΜΗΤΡΩΟ ΕΝΟΡΓΑΝΩΣΗΣ: ποιος αφήνει ίχνος και πώς (η μία δήλωση) ──────
(dolist (n '("subsume" "run-inference" "verify-guard" "parse-article-id"
             "draft-memo" "build-article-uri"))
  (orchestrator.trace:register-traced! n :how :direct))
(loop for (n . via) in '(("evaluate-deontic" . "subsume")
                         ("explain" . "run-inference") ("query" . "run-inference")
                         ("meta-eval" . "run-inference") ("guards-pass-p" . "run-inference")
                         ("conclusion-status" . "subsume") ("norm-gaps" . "subsume")
                         ("proof-grade" . "subsume")
                         ("classify-deontic-sentence" . "evaluate-deontic")
                         ("gap-questions" . "draft-memo")
                         ("parse-narrative" . "--command-span")
                         ("dialectic-report" . "--command-span")
                         ("critical-facts" . "--command-span")
                         ("minimal-blockers" . "--command-span")
                         ("run-shadow-knowledge" . nil) ("run-adopt-knowledge" . nil))
      do (if via (orchestrator.trace:register-traced! n :via via)
             (orchestrator.trace:register-traced! n :how :direct)))

;;; ── ΕΝΤΟΛΕΣ ΕΡΩΤΗΜΑΤΩΝ ΙΧΝΟΥΣ ──────────────────────────────────────────

(defun %print-tevent (ev)
  (let ((links (orchestrator.exec-provenance:resolve-event ev)))
    (format t "~%#~D ~(~A~) [~(~A~)]~@[ · εντολή ~A~]~@[ · γονέας #~D~]~%"
            (orchestrator.trace:tevent-id ev) (orchestrator.trace:tevent-kind ev)
            (orchestrator.trace:tevent-severity ev)
            (orchestrator.trace:tevent-command ev)
            (orchestrator.trace:tevent-parent ev))
    (when (orchestrator.trace:tevent-symbol ev)
      (format t "  εκτέλεση: ~A::~A (~A)~%"
              (orchestrator.trace:tevent-package ev)
              (orchestrator.trace:tevent-symbol ev)
              (orchestrator.trace:tevent-source ev)))
    (when (getf links :contract)
      (format t "  συμβόλαιο: ~A · ικανότητα: ~A · ρόλος: ~A · συστατικό: ~A~%"
              (getf links :contract) (getf links :capability)
              (getf links :role) (getf links :component-id)))
    (loop for (k v) on (orchestrator.trace:tevent-data ev) by #'cddr
          do (format t "  ~(~A~): ~S~%" k v))))

(defun run-trace-last ()
  "--trace-last : το τελευταίο γεγονός ίχνους, πλήρως δεμένο."
  (let ((ev (orchestrator.trace:last-event)))
    (if ev (progn (%print-tevent ev) 0)
        (progn (format t "Κανένα ίχνος σε αυτή τη συνεδρία.~%") 1))))

(defun run-trace (args)
  "--trace <id> : ένα γεγονός ίχνους + τα παιδιά του."
  (let* ((id (ignore-errors (parse-integer (first args))))
         (ev (and id (orchestrator.trace:find-event id))))
    (if (null ev)
        (progn (format t "Κανένα ίχνος #~A.~%" (first args)) 1)
        (progn (%print-tevent ev)
               (dolist (child (remove-if-not
                               (lambda (e) (eql (orchestrator.trace:tevent-parent e) id))
                               (orchestrator.trace:all-events)))
                 (format t "  └─ παιδί #~D ~(~A~) ~A~%"
                         (orchestrator.trace:tevent-id child)
                         (orchestrator.trace:tevent-kind child)
                         (or (orchestrator.trace:tevent-symbol child) "")))
               0))))

(defun run-trace-filter (&key kind command symbol label)
  (let ((evs (orchestrator.trace:events-where :kind kind :command command
                                              :symbol symbol :limit 10)))
    (if (null evs)
        (progn (format t "Κανένα ίχνος για ~A.~%" label) 1)
        (progn (mapc #'%print-tevent evs) 0))))

(defun run-trace-capability (args)
  "--trace-capability <ικανότητα> : τα ίχνη των παρόχων της."
  (let* ((cap (orchestrator.self-model:find-capability (format nil "~{~A~^ ~}" args))))
    (if (null cap)
        (progn (format t "Άγνωστη ικανότητα.~%") 1)
        (let ((evs (remove-if-not
                    (lambda (e)
                      (member (orchestrator.trace:tevent-symbol e)
                              (orchestrator.self-model:capability-functions cap)
                              :test #'equal))
                    (orchestrator.trace:all-events))))
          (if evs (progn (mapc #'%print-tevent (last evs 10)) 0)
              (progn (format t "Κανένα ίχνος παρόχων της «~A» ακόμη.~%"
                             (orchestrator.self-model:capability-name cap)) 1))))))

(defun run-trace-component (args)
  "--trace-component <component-id> : τα ίχνη ενός συστατικού (symbol:pkg::name)."
  (let* ((id (format nil "~{~A~^ ~}" args))
         (evs (remove-if-not
               (lambda (e)
                 (equal id (getf (orchestrator.exec-provenance:resolve-event e) :component-id)))
               (orchestrator.trace:all-events))))
    (if evs (progn (mapc #'%print-tevent (last evs 10)) 0)
        (progn (format t "Κανένα ίχνος για το συστατικό «~A».~%" id) 1))))

(register-command "--trace-last" (lambda (a) (declare (ignore a)) (run-trace-last)))
(register-command "--trace"      (lambda (a) (run-trace a)))
(register-command "--trace-last-conclusion"
  (lambda (a) (declare (ignore a))
    (if (orchestrator.exec-provenance:last-conclusion-report) 0 1)))
(register-command "--trace-capability" (lambda (a) (run-trace-capability a)))
(register-command "--trace-component" (lambda (a) (run-trace-component a)))
(register-command "--trace-command"
  (lambda (a) (run-trace-filter :kind :command :command (first a)
                                :label (or (first a) "εντολές"))))
(register-command "--trace-proof"
  (lambda (a) (declare (ignore a)) (run-trace-filter :kind :conclusion :label "αποδείξεις")))
(register-command "--trace-legal-state"
  (lambda (a) (declare (ignore a)) (run-trace-filter :kind :legal-state :label "έννομες καταστάσεις")))

;;; ── Η ΠΥΛΗ ──────────────────────────────────────────────────────────────

(defun run-provenance-gate ()
  "--provenance-gate : operative self-knowledge, κλειδωμένο — 100% ή κόκκινο."
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΠΡΟΕΛΕΥΣΗΣ: η εκτέλεση αφήνει αλήθεια πίσω της ──~%")
      (orchestrator.component-scan:build-component-registry!)
      ;; ① παραγωγικός νομικός τρόπος: τουλάχιστον :legal-critical ενεργό
      (check "① προφίλ ιχνών ≥ :legal-critical (παραγωγικός νομικός τρόπος)"
             (member orchestrator.trace:*trace-profile* '(:legal-critical :full-debug)))
      ;; ② ΖΩΝΤΑΝΟ συμπέρασμα: subsume ⇒ ίχνος :conclusion με απόδειξη,
      ;;    δεμένο σε συμβόλαιο/ικανότητα/συστατικό, και last-conclusion δείχνει εκεί.
      (let ((n0 (orchestrator.trace:event-count)))
        (let ((*standard-output* (make-broadcast-stream)))
          (orchestrator.subsumption:subsume
           '((:γεγονός :π :αφαιρεί :κινητό) (:κατηγορία :κινητό :κινητό-πράγμα))))
        (let* ((ev (find :conclusion (orchestrator.trace:all-events)
                         :key #'orchestrator.trace:tevent-kind :from-end t))
               (links (and ev (orchestrator.exec-provenance:resolve-event ev))))
          (check "② subsume ⇒ ίχνος :conclusion (γεγονότα, κανόνες, θέσεις, δεσμός απόδειξης)"
                 (and ev (> (orchestrator.trace:event-count) n0)
                      (getf (orchestrator.trace:tevent-data ev) :proofs-p)))
          (check "③ το ίχνος δένεται: συμβόλαιο=subsume · ικανότητα=υπαγωγή · συστατικό γνωστό στο μητρώο"
                 (and links (equal (getf links :contract) "subsume")
                      (equal (getf links :capability) "υπαγωγή")
                      (getf links :component-known)))
          (check "④ trace-last-conclusion δείχνει σε ΑΥΤΗ την εκτέλεση"
                 (and ev (eql (orchestrator.trace:last-conclusion-id)
                              (orchestrator.trace:tevent-id ev))))
          ;; ⑤ ασφάλεια: το γεγονός είναι ΜΟΝΟ δεδομένα — σειριοποιείται και
          ;;    ξαναδιαβάζεται με *read-eval* ΚΛΕΙΣΤΟ, χωρίς απώλεια.
          (check "⑤ data-only: το ίχνος σειριοποιείται/ξαναδιαβάζεται με *read-eval*=NIL"
                 (let* ((d (orchestrator.trace:tevent-data ev))
                        (s (prin1-to-string d))
                        (back (let ((*read-eval* nil)) (read-from-string s))))
                   (equal d back)))))
      ;; ⑥ ΑΝΑΚΛΗΣΗ έννομης κατάστασης: «μάθε πώληση ⇒ αποσύρεται κατοχή» ΜΕ ίχνος
      (let ((e (orchestrator.inference:make-inference-engine)))
        (orchestrator.inference:add-facts
         e '((:γεννά :αγορά :κατοχή :Α) (:σβήνει :πώληση :κατοχή :Α)
             (:συμβάν :ε1 :αγορά "2026-01-10") (:σημείο-κρίσης "2026-03-01")))
        (orchestrator.inference:run-inference e)
        (orchestrator.inference:add-facts e '((:συμβάν :ε2 :πώληση "2026-02-01")))
        (orchestrator.inference:run-inference e)
        (let ((st (car (last (orchestrator.trace:events-where :kind :legal-state)))))
          (check "⑥ η ανάκληση αφήνει ίχνος :legal-state — η κατοχή ΑΠΟΣΥΡΕΤΑΙ ορατά"
                 (and st (some (lambda (f) (and (consp f) (eq (first f) :ισχύει)))
                               (getf (orchestrator.trace:tevent-data st) :withdrawn))))))
      ;; ⑦ η ανεξάρτητη επαλήθευση άφησε ίχνη :verification (πιστοποιητικά ημερομηνιών)
      (check "⑦ verify-guard ⇒ ίχνη :verification, καθένα με ρητή ετυμηγορία (:ok)"
             (let ((vs (orchestrator.trace:events-where :kind :verification)))
               (and vs (every (lambda (v)
                                (member :ok (orchestrator.trace:tevent-data v)))
                              vs))))
      ;; ⑧ ταυτότητα άρθρου: κάθε runtime χρήση αφήνει ίχνος· ωμός αριθμός = ΟΡΑΤΟ χρέος
      (orchestrator.article-id:parse-article-id "100Α")
      (let ((orchestrator.uris:*canonical-config*
              (if (gethash "base_uri" orchestrator.uris:*canonical-config*)
                  orchestrator.uris:*canonical-config*
                  (let ((h (make-hash-table :test 'equal)))
                    (setf (gethash "base_uri" h) "https://gate.test") h))))
        (orchestrator.uris:build-article-uri 100))
      (check "⑧ parse-article-id ⇒ :identity · build-article-uri(ωμός ακέραιος) ⇒ :identity-debt"
             (and (orchestrator.trace:events-where :kind :identity :symbol "parse-article-id")
                  (orchestrator.trace:events-where :kind :identity-debt
                                                   :symbol "build-article-uri")))
      ;; ⑨ ρίζα-εντολή: ο συνταγματικός φραγμός = γονικό span με exit + ετυμηγορία,
      ;;    και τα εσωτερικά ίχνη ΚΛΗΡΟΝΟΜΟΥΝ τον γονέα (parent linkage).
      (let ((*standard-output* (make-broadcast-stream)))
        (execute-command "--προέλευση-δοκιμή"
                         (lambda (a) (declare (ignore a))
                           (orchestrator.subsumption:subsume
                            '((:γεγονός :π :αφαιρεί :κινητό)
                              (:κατηγορία :κινητό :κινητό-πράγμα)))
                           0)
                         '()))
      (let* ((cmd (car (last (orchestrator.trace:events-where
                              :kind :command :command "--προέλευση-δοκιμή"))))
             (concl (car (last (orchestrator.trace:events-where :kind :conclusion)))))
        (check "⑨ εντολή ⇒ ρίζα-span (exit + συνταγματική ετυμηγορία)· το συμπέρασμα παιδί της"
               (and cmd concl
                    (eql 0 (getf (orchestrator.trace:tevent-data cmd) :exit))
                    (eq :allowed (getf (orchestrator.trace:tevent-data cmd) :constitutional))
                    (eql (orchestrator.trace:tevent-parent concl)
                         (orchestrator.trace:tevent-id cmd)))))
      ;; ⑩ σκιά/υιοθέτηση: η κρίση της σκιώδους πύλης αφήνει ίχνος :adoption
      (let ((*standard-output* (make-broadcast-stream)))
        (execute-command "--shadow-knowledge" (find-command "--shadow-knowledge")
                         '()))   ; χωρίς ορίσματα: τίμιο exit 1 — ο δρόμος περνά από τη ρίζα
      (check "⑩ το μονοπάτι σκιάς/υιοθέτησης περνά από ρίζα-span εντολής (ίχνος με exit)"
             (let ((cmd (car (last (orchestrator.trace:events-where
                                    :kind :command :command "--shadow-knowledge")))))
               (and cmd (getf (orchestrator.trace:tevent-data cmd) :exit))))
      ;; ⑪ ΚΑΛΥΨΗ: κάθε legal-critical :function συμβόλαιο αφήνει ίχνος —
      ;;    άμεσα, μέσω γονικού span, ή ΡΗΤΟ χρέος. ΣΙΩΠΗΛΟ σύνολο = ∅.
      (multiple-value-bind (traced via debts silent)
          (orchestrator.exec-provenance:trace-coverage)
        (check (format nil "⑪ κάλυψη ενοργάνωσης: ~D άμεσα · ~D μέσω γονέα · ~D ρητά χρέη · ~D ΣΙΩΠΗΛΑ"
                       (length traced) (length via) (length debts) (length silent))
               (null silent)))
      ;; ⑫ επικυρωτής προέλευσης στο ΖΩΝΤΑΝΟ ρεύμα: 0 παραβάσεις
      (let ((v (orchestrator.exec-provenance:validate-provenance :registry-built-p t)))
        (check (format nil "⑫ επικυρωτής προέλευσης (ζωντανό ρεύμα): ~D παραβάσεις" (length v))
               (null v))
        (dolist (m v) (format t "      ✗ ~A~%" m)))
      ;; ⑬-⑮ ΑΡΝΗΤΙΚΑ (σκιώδες μαγαζί — το πραγματικό ρεύμα δεν αγγίζεται)
      (check "⑬ πλαστό ίχνος με σύμβολο ΧΩΡΙΣ συμβόλαιο/χρέος ⇒ παράβαση"
             (let ((orchestrator.trace::*events*
                     (make-array 8 :adjustable t :fill-pointer 0)))
               (orchestrator.trace:emit! :conclusion
                :symbol "ghost-executor" :package "nowhere"
                :data '(:proofs-p t))
               (some (lambda (m) (search "ghost-executor" m))
                     (orchestrator.exec-provenance:validate-provenance))))
      (check "⑭ συμπέρασμα ΧΩΡΙΣ δεσμό απόδειξης ⇒ παράβαση (tracing ≠ provenance)"
             (let ((orchestrator.trace::*events*
                     (make-array 8 :adjustable t :fill-pointer 0)))
               (orchestrator.trace:emit! :conclusion
                :symbol "subsume" :package "orchestrator.subsumption"
                :data '(:positions-p t :proofs-p nil))
               (some (lambda (m) (search "απόδειξη" m))
                     (orchestrator.exec-provenance:validate-provenance))))
      (check "⑮ ίχνος με ΞΕΠΕΡΑΣΜΕΝΟ hash πηγής ⇒ παράβαση (μητρώο ≠ δίσκος)"
             (let ((orchestrator.trace::*events*
                     (make-array 8 :adjustable t :fill-pointer 0)))
               (orchestrator.trace:emit! :verification
                :symbol "verify-guard" :package "orchestrator.metaeval"
                :source "source/guard-metaeval.lisp"
                :data '(:ok t :source-hash "ψεύτικο-hash"))
               (some (lambda (m) (search "ΞΕΠΕΡΑΣΜΕΝΟ" m))
                     (orchestrator.exec-provenance:validate-provenance))))
      ;; ⑯ ανενόργανη εκτέλεση ΑΝΙΧΝΕΥΕΤΑΙ: με προφίλ :off το συμπέρασμα δεν
      ;;    αφήνει ίχνος ΚΑΙ ο επικυρωτής καταγγέλλει το προφίλ — ποτέ σιωπηλά.
      (check "⑯ προφίλ :off ⇒ καμία εγγραφή ΚΑΙ ο επικυρωτής το καταγγέλλει"
             (let ((n0 (orchestrator.trace:event-count)))
               (let ((orchestrator.trace:*trace-profile* :off))
                 (let ((*standard-output* (make-broadcast-stream)))
                   (orchestrator.subsumption:subsume '((:γεγονός :π :αφαιρεί :κινητό))))
                 (and (= n0 (orchestrator.trace:event-count))
                      (some (lambda (m) (search ":off" m))
                            (orchestrator.exec-provenance:validate-provenance
                             :events '())))))))
    (format t "~%── ΠΥΛΗ ΠΡΟΕΛΕΥΣΗΣ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--provenance-gate" (lambda (a) (declare (ignore a)) (run-provenance-gate)))

(orchestrator.self-model:declare-capability! "εκτελεστική-προέλευση"
 :description "runtime execution provenance: κάθε κρίσιμη εκτέλεση δεμένη σε συμβόλαιο/συστατικό/απόδειξη/πύλη"
 :package :orchestrator.trace
 :functions '("emit!" "validate-provenance" "last-conclusion-report" "trace-coverage")
 :gate "--provenance-gate" :depends-on '("συστατικά" "συμβόλαια"))

(orchestrator.contracts:defcontract "runtime-provenance-protocol" :protocol
 :package :orchestrator.trace :system "orchestrator-infrastructure"
 :capability "εκτελεστική-προέλευση" :role "έλεγχος"
 :purpose "legal execution provenance: ίχνη data-only, append-only, με προφίλ κόστους, δεμένα σε συμβόλαια/συστατικά/αποδείξεις"
 :inputs '("κρίσιμες εκτελέσεις (συμπεράσματα, καταστάσεις, επαληθεύσεις, ταυτότητες, τεχνήματα, πύλες, εντολές)")
 :outputs '("γεγονότα ίχνους" "trace-last-conclusion" "παραβάσεις προέλευσης")
 :preconditions '("παραγωγικός νομικός τρόπος: προφίλ ≥ :legal-critical")
 :postconditions '("συμπέρασμα χωρίς δεσμό απόδειξης = παράβαση" "κρίσιμη εκτέλεση χωρίς συμβόλαιο = παράβαση")
 :side-effects '("εγγραφή γεγονότων ίχνους (μόνο δεδομένα)")
 :legal-critical t :policy-level :φραγή
 :audit "το ίδιο το ίχνος ΕΙΝΑΙ το audit — append-only, μονότονα ids, χωρίς eval"
 :rollback "append-only: τα ίχνη δεν σβήνονται ούτε ξαναγράφονται"
 :failure-modes '("διαρκές αρχείο ιχνών εκτός συνεδρίας = ΔΗΛΩΜΕΝΟ ΧΡΕΟΣ")
 :tests '("--provenance-gate"))
