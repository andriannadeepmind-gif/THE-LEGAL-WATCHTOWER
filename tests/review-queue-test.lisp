;;;; tests/review-queue-test.lisp
;;;; CLOS/MOP human-in-the-loop review queue: discovery, lifecycle, dedup,
;;;; decisions + audit, approved-operations, persistence, integration.

(in-package :orchestrator.review)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== MOP: kinds + metaclass-carried severity ==~%")
(check "kinds discovered via the MOP"
       (and (member :amendment (review-item-kinds))
            (member :duplicate (review-item-kinds))
            (member :anomaly (review-item-kinds))))
(check "metaclass carries kind"
       (eq :amendment (item-kind (make-instance 'amendment-review))))
(check "metaclass carries severity (duplicate = :high)"
       (eq :high (item-severity (make-instance 'duplicate-review))))
(check "nothing queued is auto-approvable"
       (not (auto-approvable-p (make-instance 'amendment-review))))

(format t "~%== Polymorphic summaries ==~%")
(let ((a (make-instance 'amendment-review :source "Ν.4855/2021" :target "art_5"
                        :payload (list :op :insert :target "art_5" :note "new-paragraph")
                        :confidence :medium)))
  (check "amendment summary mentions article + law"
         (and (search "art_5" (item-summary a)) (search "4855" (item-summary a))))
  (check "summary reflects the operation phrase" (search "προσθήκη" (item-summary a))))
(check "duplicate summary mentions the article"
       (search "art_10" (item-summary (make-instance 'duplicate-review :target "art_10"))))

(format t "~%== Queue: enqueue + de-dup ==~%")
(let ((q (make-review-queue)))
  (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5" :payload '(:op :insert)))
  (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5" :payload '(:op :insert)))
  (enqueue q (make-instance 'duplicate-review :source "L1" :target "art_9"))
  (check "same identity enqueued once (dedup)" (= 2 (length (queue-items q))))
  (check "2 pending" (= 2 (queue-pending-count q))))

(format t "~%== [audit#9] payload ΑΝΗΚΕΙ στην ταυτότητα (καμία σύμπτυξη διαφορετικών προτάσεων) ==~%")
(let ((q (make-review-queue)))
  ;; ΙΔΙΟ άρθρο (source/target), ΔΙΑΦΟΡΕΤΙΚΟ προτεινόμενο περιεχόμενο ⇒ ΔΥΟ προτάσεις.
  (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                            :payload '(:op :replace-text :text "Εκδοχή Α")))
  (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                            :payload '(:op :replace-text :text "Εκδοχή Β")))
  (check "διαφορετικά payloads για το ΙΔΙΟ άρθρο ⇒ 2 ξεχωριστές προτάσεις"
         (= 2 (length (queue-items q))))
  ;; Απόφαση στη μία ΔΕΝ auto-approve-άρει την άλλη (διαφορετική ταυτότητα).
  (let ((a (first (queue-items q))))
    (decide q (item-id a) :approve :by "δικηγόρος"))
  (check "απόφαση σε μία εκδοχή ΔΕΝ κληρονομείται από την άλλη"
         (= 1 (length (pending-items q))))
  ;; ΙΔΙΟ ακριβώς payload σε νέο poll ⇒ μία εγγραφή (dedup διατηρείται).
  (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                            :payload '(:op :replace-text :text "Εκδοχή Β")))
  (check "ίδιο ακριβώς payload σε επανάληψη ⇒ καμία νέα εγγραφή (dedup)"
         (= 2 (length (queue-items q)))))

(format t "~%== Decisions + audit + approved-operations ==~%")
(let* ((q (make-review-queue))
       (a (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                                    :payload (list :op :replace-text :target "art_5" :text "Νέο."))))
       (b (enqueue q (make-instance 'amendment-review :source "L1" :target "art_7"
                                    :payload (list :op :repeal :target "art_7")))))
  (declare (ignore b))
  (decide q (item-id a) :approve :by "Σ.Σ." :note "ορθό")
  (check "approved item status" (eq :approved (item-status a)))
  (check "decision recorded who" (string= "Σ.Σ." (item-decided-by a)))
  (check "still 1 pending (b)" (= 1 (queue-pending-count q)))
  (check "approved-operations returns ONLY the approved op"
         (let ((ops (approved-operations q)))
           (and (= 1 (length ops)) (eq :replace-text (getf (first ops) :op)))))
  (decide q (item-id a) :reject :by "Σ.Σ.")  ; flip
  (check "reject removes it from approved-operations" (null (approved-operations q))))

(format t "~%== Persistence round-trip (deterministic) ==~%")
(let* ((q (make-review-queue))
       (it (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5" :payload '(:op :insert)))))
  (enqueue q (make-instance 'duplicate-review :source "L2" :target "art_9"))
  (decide q (item-id it) :approve :by "x")
  (let* ((state (queue-state q))
         (q2 (make-review-queue)))
    (restore-queue-state q2 state)
    (check "restored item count" (= 2 (length (queue-items q2))))
    (check "restored kinds preserved (class rebuilt from kind)"
           (and (typep (first (queue-items q2)) 'amendment-review)
                (typep (second (queue-items q2)) 'duplicate-review)))
    (check "restored decision preserved"
           (eq :approved (item-status (first (queue-items q2)))))
    (check "state is byte-identical after round-trip"
           (equal state (queue-state q2)))))

(format t "~%== Integration: flagged data -> review items ==~%")
(let* ((record (list (cons "id" "Ν.4855/2021")
                     (cons "operations" (list (list :op :replace-text :target "art_2" :confidence :high)))
                     (cons "review" (list (list :op :insert :target "art_5" :confidence :medium :note "new-article")
                                          (list :op :repeal-law :target "law-4619/2019" :confidence :low)))))
       (items (amendment-record->review-items record)))
  (check "only the flagged (review) ops become items, not the high-conf ones"
         (= 2 (length items)))
  (check "items carry the source law" (string= "Ν.4855/2021" (item-source (first items))))
  (check "low-confidence preserved" (member :low (mapcar #'item-confidence items))))

(let* ((report (list :duplicates '("art_10" "art_159")
                     :duplicate-details (list (cons "art_10" '((217 . "παλιό") (229 . "νέο"))))))
       (items (validation-report->review-items report :source "ΙΣΟΚΡΑΤΗΣ")))
  (check "a duplicate item per flagged duplicate" (= 2 (length items)))
  (check "duplicate item is high severity" (eq :high (item-severity (first items)))))

(format t "~%== Self-improvement: learn a decision, auto-apply it forever ==~%")
(let ((q (make-review-queue)))
  (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5" :payload '(:op :insert)))
  (decide q "AMENDMENT|L1|art_5" :approve :by "Σ.Σ." :note "ορθό")
  (check "decision is memorised" (= 1 (learned-count q)))
  ;; persist + restore (a new run / restart)
  (let ((q2 (make-review-queue)))
    (restore-queue-state q2 (queue-state q))
    (check "memory survives persistence" (= 1 (learned-count q2)))
    (check "memory round-trips byte-identical" (equal (queue-state q) (queue-state q2)))
    ;; the SAME flagged case reappears -> auto-resolved, never pending again
    (let ((it (enqueue q2 (make-instance 'amendment-review :source "L1" :target "art_5"
                                         :payload '(:op :insert)))))
      (check "identical future case auto-applied (not pending)"
             (eq :approved (item-status it)))
      (check "no human action needed (0 pending)" (= 0 (queue-pending-count q2)))
      (check "the lawyer's identity is preserved" (string= "Σ.Σ." (item-decided-by it))))
    ;; a DIFFERENT case is still pending (no false learning)
    (enqueue q2 (make-instance 'amendment-review :source "L1" :target "art_9" :payload '(:op :insert)))
    (check "an unseen case is still flagged for review" (= 1 (queue-pending-count q2)))))

(format t "~%== [audit#8 μέρος Β] signed, non-repudiable decision (τελική νομική αυθεντία) ==~%")
;; Χωρίς κλειδί ⇒ :unsigned (τίμια· καμία ψευδο-υπογραφή). (Η καθαρή έδρα δεν διαβάζει
;; env — το var είναι η μόνη πηγή· εδώ το αφήνουμε nil.)
(let ((*review-signing-key-path* nil)
      (q (make-review-queue)))
  (let ((it (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                                      :payload '(:op :insert)))))
    (decide q (item-id it) :approve :by "Σ.Σ.")
    (check "χωρίς κλειδί ⇒ decision :unsigned"
           (eq :unsigned (decision-signature-status (item-signature it))))
    (check "unsigned verify ⇒ (values nil :unsigned)"
           (not (verify-decision-signature (item-signature it) "/nonexistent.pem")))))

;; Με το κλειδί ΤΟΥ ΔΙΚΗΓΟΡΟΥ ⇒ :signed + επαληθεύσιμο· tamper ⇒ αποτυχία· επιβιώνει persistence.
(let* ((dir (format nil "/tmp/rq-sign-~D/" (get-internal-real-time)))
       (priv (format nil "~Apriv.pem" dir))
       (pub  (format nil "~Apub.pem" dir)))
  (let ((kp (orchestrator.jws-authority:generate-rsa-keypair :bits 2048)))
    (orchestrator.jws-authority:save-rsa-keypair kp priv pub))
  (let ((*review-signing-key-path* priv)
        (*review-signer-id* "ΑΜ-12345")
        (q (make-review-queue)))
    (let ((it (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                                        :payload '(:op :replace-text :text "Εγκεκριμένο")))))
      (decide q (item-id it) :approve :by "Σ.Σ.")
      (let ((sig (item-signature it)))
        (check "με κλειδί δικηγόρου ⇒ decision :signed"
               (eq :signed (decision-signature-status sig)))
        (check "kid = ο δικηγόρος" (string= "ΑΜ-12345" (getf sig :kid)))
        (check "η υπογραφή ΕΠΑΛΗΘΕΥΕΤΑΙ κατά το public key του δικηγόρου"
               (verify-decision-signature sig pub))
        (let ((tampered (copy-list sig)))
          (setf (getf tampered :statement)
                (concatenate 'string (getf sig :statement) "|TAMPERED"))
          (check "αλλοιωμένη δήλωση ⇒ επαλήθευση ΑΠΟΤΥΓΧΑΝΕΙ (μη-αποποιήσιμη)"
                 (not (verify-decision-signature tampered pub))))
        ;; επιβιώνει queue-state → restore (durable) και εξακολουθεί να επαληθεύεται
        (let ((q2 (make-review-queue)))
          (restore-queue-state q2 (queue-state q))
          (check "signed decision επιβιώνει persistence + επαληθεύεται"
                 (verify-decision-signature (item-signature (first (queue-items q2))) pub)))))))

(format t "~%== [audit#10] schema validation στο restore (fail-closed θεσμική μνήμη) ==~%")
(macrolet ((ck-restore-signals (name form)
             `(check ,name (handler-case (progn ,form nil) (restore-queue-error () t)))))
  ;; άγνωστο kind ⇒ ΣΗΜΑ (καμία σιωπηλή υποβάθμιση σε generic review-item)
  (ck-restore-signals "άγνωστο kind ⇒ restore-queue-error"
    (restore-queue-state (make-review-queue)
      (list :version 2
            :items (list (list :kind :bogus-kind :source "L" :target "art_5"
                               :payload '(:op :insert) :status :pending))
            :memory nil)))
  ;; μη αποδεκτό status ⇒ ΣΗΜΑ
  (ck-restore-signals "μη αποδεκτό status ⇒ restore-queue-error"
    (restore-queue-state (make-review-queue)
      (list :version 2
            :items (list (list :kind :amendment :source "L" :target "art_5"
                               :payload '(:op :insert) :status :maybe))
            :memory nil)))
  ;; εγκεκριμένο χωρίς provenance ⇒ ΣΗΜΑ
  (ck-restore-signals "approved χωρίς decided-by/at ⇒ restore-queue-error"
    (restore-queue-state (make-review-queue)
      (list :version 2
            :items (list (list :kind :amendment :source "L" :target "art_5"
                               :payload '(:op :insert) :status :approved))
            :memory nil))))
;; έγκυρο queue-state ⇒ φορτώνεται· το id ΕΠΑΝΥΠΟΛΟΓΙΖΕΤΑΙ από το περιεχόμενο (binding)
(let* ((q (make-review-queue)))
  (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                            :payload '(:op :replace-text :text "Δ")))
  (let* ((st (queue-state q))
         (orig-id (getf (first (getf st :items)) :id))
         ;; χειροκίνητη αλλοίωση του stored id — το restore ΔΕΝ πρέπει να το εμπιστευτεί
         (tampered (copy-tree st)))
    (setf (getf (first (getf tampered :items)) :id) "ΠΛΑΣΤΟ-ID")
    (let ((q2 (make-review-queue)))
      (restore-queue-state q2 tampered)
      (check "restore αγνοεί αλλοιωμένο id, το ΕΠΑΝΥΠΟΛΟΓΙΖΕΙ από το περιεχόμενο"
             (string= orig-id (item-id (first (queue-items q2))))))))

(format t "~%== [audit#10] publication gate: signed απόφαση απαιτείται όταν υπάρχει verify key ==~%")
(let* ((dir (format nil "/tmp/rq-pub-~D/" (get-internal-real-time)))
       (priv (format nil "~Apriv.pem" dir)) (pub (format nil "~Apub.pem" dir)))
  (orchestrator.jws-authority:save-rsa-keypair
   (orchestrator.jws-authority:generate-rsa-keypair :bits 2048) priv pub)
  ;; (1) εγκεκριμένη ΥΠΟΓΕΓΡΑΜΜΕΝΗ πράξη + verify key ⇒ δημοσιεύεται
  (let ((*review-signing-key-path* priv) (q (make-review-queue)))
    (let ((it (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                                        :payload '(:op :insert :code "poinikos")))))
      (decide q (item-id it) :approve :by "Σ.Σ."))
    (let ((*review-verify-key-path* pub))
      (check "verified signed approval ⇒ περνά στο approved-operations"
             (= 1 (length (approved-operations q))))))
  ;; (2) εγκεκριμένη ΑΝΥΠΟΓΡΑΦΗ πράξη + verify key ⇒ ΔΕΝ δημοσιεύεται (fail-closed)
  (let ((*review-signing-key-path* nil) (q (make-review-queue)))
    (let ((it (enqueue q (make-instance 'amendment-review :source "L1" :target "art_5"
                                        :payload '(:op :insert :code "poinikos")))))
      (decide q (item-id it) :approve :by "άγνωστος"))
    (let ((*review-verify-key-path* pub))
      (check "unsigned approval + verify key ⇒ ΑΠΟΚΛΕΙΕΤΑΙ από τη δημοσίευση"
             (= 0 (length (approved-operations q)))))
    ;; χωρίς verify key ⇒ καμία επαλήθευση configured (δηλωμένο όριο)
    (let ((*review-verify-key-path* nil))
      (check "χωρίς verify key ⇒ καμία επιβολή (δηλωμένο όριο)"
             (= 1 (length (approved-operations q)))))))

(format t "~%========================================~%")
(format t "Review queue tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
