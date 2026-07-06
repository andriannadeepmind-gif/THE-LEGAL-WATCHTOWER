;;;; systems/orchestrator-cli/event-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΤΗΣ ΙΣΤΟΡΙΑΣ (Α5): event calculus — κλειδωμένα σενάρια χρόνου
;;;; ============================================================================
;;;;
;;;; Κάθε σενάριο: γεγονότα → run-inference (ΟΛΟΙ οι κανόνες, όπως ζει το
;;;; σύστημα — όχι ειδικό υποσύνολο) → (:ισχύει …) με απόδειξη που φέρει
;;;; ΑΝΕΞΑΡΤΗΤΑ ΕΠΑΛΗΘΕΥΜΕΝΑ πιστοποιητικά ημερομηνιών. Νέα πύλη = αυτόματα
;;;; μέλος της ολομέλειας --gates (μητρώο «-gate»).

(in-package :orchestrator.cli)

(defun %ec-run (facts)
  "Φρέσκια μηχανή με ΟΛΟΥΣ τους κανόνες του συστήματος πάνω στα FACTS."
  (let ((e (orchestrator.inference:make-inference-engine)))
    (orchestrator.inference:add-facts e facts)
    (orchestrator.inference:run-inference e)
    e))

(defparameter +ec-domain+
  '((:γεννά :αγορά :κατοχή :Α)
    (:σβήνει :πώληση :κατοχή :Α))
  "Γνώση πεδίου της πύλης: η αγορά γεννά κατοχή του Α, η πώληση τη σβήνει.")

(defun run-event-gate ()
  "--event-gate : η αντίληψη ιστορίας, κλειδωμένη — 100% ή κόκκινο."
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label))))
             (holds-p (facts)
               (plusp (length (orchestrator.inference:query
                               (%ec-run facts) '(:ισχύει :κατοχή :Α ?τ))))))
      (format t "~%── ΠΥΛΗ ΙΣΤΟΡΙΑΣ (Α5): event calculus στο WFS ──~%")
      ;; ① γένεση πριν την κρίση ⇒ ισχύει
      (check "αγορά 10/01, κρίση 01/03 ⇒ η κατοχή ΙΣΧΥΕΙ"
             (holds-p (append +ec-domain+
                              '((:συμβάν :ε1 :αγορά "2026-01-10")
                                (:σημείο-κρίσης "2026-03-01")))))
      ;; ② διακοπή πριν την κρίση ⇒ ΔΕΝ ισχύει (clipping)
      (check "αγορά 10/01, πώληση 01/02, κρίση 01/03 ⇒ ΔΕΝ ισχύει"
             (not (holds-p (append +ec-domain+
                                   '((:συμβάν :ε1 :αγορά "2026-01-10")
                                     (:συμβάν :ε2 :πώληση "2026-02-01")
                                     (:σημείο-κρίσης "2026-03-01"))))))
      ;; ③ κρίση ΠΡΙΝ τη διακοπή ⇒ ισχύει (η ιστορία έχει κατεύθυνση)
      (check "ίδια συμβάντα, κρίση 20/01 (πριν την πώληση) ⇒ ΙΣΧΥΕΙ"
             (holds-p (append +ec-domain+
                              '((:συμβάν :ε1 :αγορά "2026-01-10")
                                (:συμβάν :ε2 :πώληση "2026-02-01")
                                (:σημείο-κρίσης "2026-01-20")))))
      ;; ④ επανα-θεμελίωση ΜΕΤΑ τη διακοπή ⇒ ισχύει ξανά
      (check "αγορά→πώληση→ΕΠΑΝΑΓΟΡΑ 15/02, κρίση 01/03 ⇒ ΙΣΧΥΕΙ ξανά"
             (holds-p (append +ec-domain+
                              '((:συμβάν :ε1 :αγορά "2026-01-10")
                                (:συμβάν :ε2 :πώληση "2026-02-01")
                                (:συμβάν :ε3 :αγορά "2026-02-15")
                                (:σημείο-κρίσης "2026-03-01")))))
      ;; ⑤ σύμβαση ορίων: λήξη ΤΗΝ ημέρα της κρίσης μετρά ⇒ ΔΕΝ ισχύει
      (check "πώληση ΤΗΝ ημέρα της κρίσης ⇒ ΔΕΝ ισχύει (δηλωμένη σύμβαση ορίων)"
             (not (holds-p (append +ec-domain+
                                   '((:συμβάν :ε1 :αγορά "2026-01-10")
                                     (:συμβάν :ε2 :πώληση "2026-03-01")
                                     (:σημείο-κρίσης "2026-03-01"))))))
      ;; ⑥ μελλοντικό συμβάν ΔΕΝ θεμελιώνει (καμία μαντεία)
      (check "αγορά ΜΕΤΑ την κρίση ⇒ ΔΕΝ ισχύει — το μέλλον δεν αποδεικνύει παρόν"
             (not (holds-p (append +ec-domain+
                                   '((:συμβάν :ε1 :αγορά "2026-04-01")
                                     (:σημείο-κρίσης "2026-03-01"))))))
      ;; ⑦ η απόδειξη φέρει τα ΑΝΕΞΑΡΤΗΤΑ ΕΠΑΛΗΘΕΥΜΕΝΑ πιστοποιητικά ημερομηνιών
      (check "η απόδειξη του (:ισχύει …) φέρει πιστοποιητικά DATE<= με :επαλήθευση :ανεξάρτητη"
             (let* ((e (%ec-run (append +ec-domain+
                                        '((:συμβάν :ε1 :αγορά "2026-01-10")
                                          (:σημείο-κρίσης "2026-03-01")))))
                    (s (string-upcase
                        (format nil "~S"
                                (orchestrator.inference:explain
                                 (orchestrator.inference:engine-jtms e)
                                 '(:ισχύει :κατοχή :Α "2026-03-01"))))))
               (and (search "DATE<=" s) (search "ΊΧΝΟ" s)
                    (search "ΑΝΕΞΆΡΤΗΤ" s))))
      ;; ⑧ ανάκληση truth maintenance: μαθαίνεται πώληση ⇒ το συμπέρασμα
      ;;    αποσύρεται ΜΟΝΟ ΤΟΥ στην ίδια μηχανή (όχι νέα μηχανή)
      (check "νέα γνώση (πώληση) στην ΙΔΙΑ μηχανή ⇒ η κατοχή αποσύρεται μόνη της"
             (let ((e (%ec-run (append +ec-domain+
                                       '((:συμβάν :ε1 :αγορά "2026-01-10")
                                         (:σημείο-κρίσης "2026-03-01"))))))
               (and (plusp (length (orchestrator.inference:query
                                    e '(:ισχύει :κατοχή :Α ?τ))))
                    (progn
                      (orchestrator.inference:add-facts
                       e '((:συμβάν :ε2 :πώληση "2026-02-01")))
                      (orchestrator.inference:run-inference e)
                      (null (orchestrator.inference:query
                             e '(:ισχύει :κατοχή :Α ?τ))))))))
    (format t "~%── ΠΥΛΗ ΙΣΤΟΡΙΑΣ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--event-gate" (lambda (a) (declare (ignore a)) (run-event-gate)))

(orchestrator.self-model:declare-capability! "ιστορία-συμβάντων"
 :description "event calculus: γεγονότα γεννούν/σβήνουν έννομες καταστάσεις, αδράνεια μέσω WFS"
 :package :orchestrator.eventcalculus :functions '("ec-initiation" "ec-clipping" "ec-holds")
 :gate "--event-gate" :depends-on '("συμπερασμός-wfs" "λογισμός-φραγμών"))

;;; ── ΣΥΜΒΟΛΑΙΑ ΠΑΡΟΧΩΝ (δεσμευτική αυτοπεριγραφή — βλ. --contract-gate) ──

(orchestrator.contracts:defcontract "event-calculus-protocol" :protocol
 :package :orchestrator.eventcalculus :system "orchestrator-infrastructure"
 :capability "ιστορία-συμβάντων" :role "αποδείξεις"
 :purpose "γεγονότα γεννούν/σβήνουν έννομες καταστάσεις με αδράνεια (ec-initiation, ec-clipping, ec-holds)"
 :preconditions '("οι ημερομηνίες συμβάντων έγκυρες — αλλιώς απορρίπτονται με λόγο")
 :postconditions '("το μέλλον δεν αποδεικνύει παρόν· clipping ρητά υπαρξιακό· σύμβαση ορίων δηλωμένη")
 :legal-critical t :policy-level :φραγή
 :tests '("--event-gate"))
