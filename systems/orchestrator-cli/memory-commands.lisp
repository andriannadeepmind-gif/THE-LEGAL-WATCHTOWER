;;;; systems/orchestrator-cli/memory-commands.lisp
;;;; ============================================================================
;;;; ΕΝΤΟΛΕΣ ΜΝΗΜΗΣ — το βιωματικό ρεύμα, ορατό και ελεγμένο
;;;; ============================================================================
;;;;
;;;;   --memory            σύνοψη: πλήθη ανά είδος, ακεραιότητα αλυσίδας, πρόσφατα
;;;;   --recall «κείμενο»  ανάκληση ομοίων επεισοδίων (εξηγήσιμη: τα κοινά λήμματα)
;;;;   --agenda            οι ανοιχτοί στόχοι — «πού είχα μείνει»
;;;;   --intend / --intentions   όπλιση/κατάλογος προθέσεων («όταν Χ, κάνε Υ»)
;;;;   --memory-gate       η πύλη: ντετερμινιστικά tests σε ΠΡΟΣΩΡΙΝΟ ημερολόγιο
;;;;
;;;; Πρώτη καταχωρημένη συνθήκη πρόθεσης (νομικός τομέας): :new-decision-citing —
;;;; «ήρθε νέα απόφαση που εφαρμόζει τη διάταξη Χ» (το context το δίνει όποιος
;;;; εισάγει νέα πραγματικότητα, πχ ο δαίμονας εισαγωγής).

(in-package :orchestrator.cli)

;;; ── Συνθήκες προθέσεων του νομικού τομέα (open/closed μητρώο) ──
(orchestrator.memory:register-intention-condition :new-decision-citing
 (lambda (args context)
   ;; args = ("corpus" "article") · context plist με :new-citations = ("corpus:article"…)
   (member (format nil "~A:~A" (first args) (second args))
           (getf context :new-citations) :test #'string=)))

(defun run-memory ()
  "--memory : η σύνοψη του βιωματικού ρεύματος."
  (multiple-value-bind (ok n broken) (orchestrator.memory:verify-episode-chain)
    (let ((by-kind (make-hash-table :test 'eq)))
      (dolist (e (orchestrator.memory:episodes))
        (incf (gethash (orchestrator.memory:episode-kind e) by-kind 0)))
      (format t "~%── ΜΝΗΜΗ (βιωματικό ρεύμα) ──~%")
      (format t "  γεγονότα: ~D · αλυσίδα: ~:[ΣΠΑΣΜΕΝΗ στο ~A~;ΑΚΕΡΑΙΗ~]~%" n ok broken)
      (loop for k being the hash-keys of by-kind using (hash-value v)
            do (format t "  ~(~A~): ~D~%" k v))
      (let ((recent (orchestrator.memory:recent-episodes 5)))
        (when recent
          (format t "~%  Πρόσφατα:~%")
          (dolist (e recent)
            (format t "    [~A] ~(~A~)~@[/~(~A~)~] — ~A~%"
                    (orchestrator.memory:episode-at e)
                    (orchestrator.memory:episode-kind e)
                    (orchestrator.memory:episode-status e)
                    (let ((tx (orchestrator.memory:episode-text e)))
                      (subseq tx 0 (min 70 (length tx))))))))
      0)))

(defun run-recall (args)
  "--recall «κείμενο» : τα πιο όμοια επεισόδια, με ΕΞΗΓΗΣΗ (τα κοινά λήμματα)."
  (let ((q (string-trim " " (format nil "~{~A~^ ~}" args))))
    (when (zerop (length q))
      (format t "χρήση: --recall \"κείμενο προς ανάκληση\"~%")
      (return-from run-recall 1))
    (let ((hits (orchestrator.memory:similar-episodes q :k 5)))
      (cond
        ((null hits) (format t "~%Κανένα όμοιο επεισόδιο στη μνήμη.~%") 0)
        (t (format t "~%── ΑΝΑΚΛΗΣΗ: όμοια με «~A» ──~%" q)
           (dolist (h hits)
             (destructuring-bind (score common e) h
               (format t "  • [~D] ~A — ~(~A~)~%      ∵ κοινά: ~{~A~^, ~}~%"
                       score (orchestrator.memory:episode-text e)
                       (orchestrator.memory:episode-kind e) common)))
           0)))))

(defun run-agenda ()
  "--agenda : οι ανοιχτοί στόχοι με τον δρομέα τους — τίποτα μισοτελειωμένο σιωπηλά."
  (let ((goals (orchestrator.memory:open-goals)))
    (cond
      ((null goals) (format t "~%Η ατζέντα είναι καθαρή — κανένας ανοιχτός στόχος.~%") 0)
      (t (format t "~%── ΑΤΖΕΝΤΑ (~D ανοιχτοί στόχοι) ──~%" (length goals))
         (dolist (g goals)
           (format t "  ◌ [~A] ~A~@[ — δρομέας: ~D~]~@[ (~A)~]~%"
                   (orchestrator.memory:episode-id g)
                   (orchestrator.memory:episode-text g)
                   (getf (orchestrator.memory:episode-props g) :progress)
                   (getf (orchestrator.memory:episode-props g) :note)))
         0))))

(defun run-intend (args)
  "--intend <corpus> <άρθρο> «περιγραφή πράξης» : όπλισε πρόθεση «όταν έρθει νέα
   απόφαση που εφαρμόζει τη διάταξη, κάνε Χ»."
  (destructuring-bind (&optional corpus article &rest what) args
    (unless (and corpus article what)
      (format t "χρήση: --intend <corpus> <άρθρο> \"τι να γίνει όταν συμβεί\"~%")
      (return-from run-intend 1))
    (let ((e (orchestrator.memory:arm-intention
              (list :new-decision-citing corpus article)
              (format nil "~{~A~^ ~}" what)
              :why (format nil "πρόθεση για art:~A:~A" corpus article))))
      (format t "~%Οπλίστηκε [~A]: όταν νέα απόφαση εφαρμόσει art:~A:~A → «~A»~%"
              (orchestrator.memory:episode-id e) corpus article
              (orchestrator.memory:episode-text e))
      0)))

(defun run-intentions ()
  "--intentions : οι οπλισμένες προθέσεις."
  (let ((ints (orchestrator.memory:armed-intentions)))
    (cond
      ((null ints) (format t "~%Καμία οπλισμένη πρόθεση.~%") 0)
      (t (format t "~%── ΠΡΟΘΕΣΕΙΣ (~D οπλισμένες) ──~%" (length ints))
         (dolist (i ints)
           (format t "  ⏳ [~A] όταν ~S → ~A~%"
                   (orchestrator.memory:episode-id i)
                   (getf (orchestrator.memory:episode-props i) :when)
                   (orchestrator.memory:episode-text i)))
         0))))

(defun run-memory-gate ()
  "--memory-gate : η πύλη του υποστρώματος μνήμης — ΟΛΟΙ οι έλεγχοι σε ΠΡΟΣΩΡΙΝΟ
   ημερολόγιο (το πραγματικό δεν αγγίζεται). Μία αποτυχία ⇒ exit 1."
  (let* ((tmp (merge-pathnames (format nil "memgate-~D.sexp" (get-universal-time))
                               (uiop:temporary-directory)))
         (orchestrator.memory:*episodes-path* tmp)
         (fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      ;; 1 — καταγραφή + fold
      (orchestrator.memory:record-episode :interaction "τι λέει το άρθρο 380 ΠΚ"
                                          :status :answered :topic '("art:poinikos:380"))
      (check "καταγραφή+ανάγνωση επεισοδίου"
             (= 1 (length (orchestrator.memory:episodes :kind :interaction))))
      ;; 2 — ατζέντα: στόχος → δρομέας → συνέχιση → κλείσιμο
      (let ((g (orchestrator.memory:record-goal "δοκιμαστικός στόχος"
                                                :props '(:mission :test :progress 0))))
        (orchestrator.memory:update-goal (orchestrator.memory:episode-id g) :progress 40)
        (check "ατζέντα: δρομέας συνέχισης"
               (= 40 (getf (orchestrator.memory:episode-props
                            (first (orchestrator.memory:open-goals))) :progress)))
        (orchestrator.memory:update-goal (orchestrator.memory:episode-id g) :status :done)
        (check "ατζέντα: κλείσιμο στόχου" (null (orchestrator.memory:open-goals))))
      ;; 3 — προθετική: όπλιση → ΔΕΝ πυροδοτεί χωρίς λόγο → πυροδοτεί με λόγο
      (orchestrator.memory:arm-intention '(:new-decision-citing "poinikos" "380")
                                         "επανεξέτασε το δεδικασμένο")
      (check "πρόθεση: αδρανής χωρίς γεγονός"
             (null (orchestrator.memory:fire-due-intentions '(:new-citations ()))))
      (check "πρόθεση: πυροδότηση στο γεγονός"
             (= 1 (length (orchestrator.memory:fire-due-intentions
                           '(:new-citations ("poinikos:380"))))))
      (check "πρόθεση: άπαξ (δεν ξαναπυροδοτεί)"
             (null (orchestrator.memory:fire-due-intentions
                    '(:new-citations ("poinikos:380")))))
      ;; 4 — ανάκληση ομοίων, εξηγήσιμη
      (orchestrator.memory:record-episode :interaction "ποια νομολογία για το άρθρο 372;"
                                          :status :answered :topic '("art:poinikos:372"))
      (let ((hits (orchestrator.memory:similar-episodes "τι προβλέπει ο νόμος για το άρθρο;")))
        (check "ανάκληση ομοίων μέσω λημμάτων" (plusp (length hits))))
      ;; 5 — ακεραιότητα αλυσίδας
      (check "αλυσίδα SHA-256 ακέραιη" (orchestrator.memory:verify-episode-chain))
      ;; 6 — ΤΑΥΤΟΧΡΟΝΙΑ (Φάση 0): 4 νήματα × 50 εγγραφές ΜΑΖΙ — η αλυσίδα
      ;; πρέπει να βγει ΑΚΕΡΑΙΗ και πλήρης (ο ένας-συγγραφέας του journal)
      ;; τα dynamic bindings ΔΕΝ περνούν σε θυγατρικά νήματα — δένουμε το path
      ;; ΜΕΣΑ σε κάθε νήμα (στο tmp), αλλιώς θα μόλυναν το πραγματικό αρχείο
      (let* ((path orchestrator.memory:*episodes-path*)
             (before (length (orchestrator.memory:episodes :fold nil)))
             (threads (loop for i from 1 to 4
                            collect (let ((tid i))
                                      (sb-thread:make-thread
                                       (lambda ()
                                         (let ((orchestrator.memory:*episodes-path* path))
                                           (dotimes (k 50)
                                             (orchestrator.memory:record-episode
                                              :observation
                                              (format nil "ταυτόχρονη εγγραφή ~D/~D" tid k)))))
                                       :name (format nil "memgate-~D" tid))))))
        (mapc #'sb-thread:join-thread threads)
        (check "ταυτοχρονία: 200/200 εγγραφές από 4 νήματα"
               (= (+ before 200) (length (orchestrator.memory:episodes :fold nil))))
        (check "ταυτοχρονία: η αλυσίδα SHA-256 ΑΚΕΡΑΙΗ υπό 4 νήματα"
               (orchestrator.memory:verify-episode-chain))))
    (ignore-errors (delete-file tmp))
    (format t "~%── ΠΥΛΗ ΜΝΗΜΗΣ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--memory"      (lambda (a) (declare (ignore a)) (run-memory)))
(register-command "--recall"     (lambda (a) (run-recall a)))
(register-command "--agenda"     (lambda (a) (declare (ignore a)) (run-agenda)))
(register-command "--intend"     (lambda (a) (run-intend a)))
(register-command "--intentions" (lambda (a) (declare (ignore a)) (run-intentions)))
(register-command "--memory-gate" (lambda (a) (declare (ignore a)) (run-memory-gate)))
