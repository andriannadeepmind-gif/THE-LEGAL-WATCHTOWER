;;;; systems/orchestrator-cli/subsumption-commands.lisp
;;;; ============================================================================
;;;; Σ4-Σ6 στο CLI: --subsume / --argue / --what-if + Η ΠΥΛΗ ΤΟΥΣ
;;;; ============================================================================
;;;;
;;;; Τα γεγονότα δίνονται ως sexp (λίστα tuples), διαβάζονται ΧΩΡΙΣ eval:
;;;;   --subsume '((:γεγονός :Α :αφαιρεί :εργαλεία) …)'
;;;; Κάθε απόφανση με δέντρο απόδειξης· ό,τι λείπει/αίρεται/μετεωρίζεται,
;;;; ΔΗΛΩΝΕΤΑΙ. Η πύλη κλειδώνει τις κανονικές υποθέσεις του χάρτη (Σ4-Σ6).

(in-package :orchestrator.cli)

(defun %case-facts-arg (args what)
  (let ((s (format nil "~{~A~^ ~}" args)))
    (if (zerop (length (string-trim " " s)))
        (progn (format t "χρήση: ~A '((:γεγονός :Α :αφαιρεί :Π) …)'~%" what) nil)
        (handler-case (orchestrator.subsumption:parse-case-facts s)
          (error (e) (format t "άκυρα γεγονότα: ~A~%" e) nil)))))

(defun run-subsume (args)
  "--subsume '<γεγονότα>' : υπαγωγή στους εγγεγραμμένους κανόνες, με αποδείξεις
   και ρητά κενά (τι λείπει / τι αίρεται / τι μένει αναποφάσιστο)."
  (let ((facts (%case-facts-arg args "--subsume")))
    (if (null facts) 1
        (progn (orchestrator.knowledge-packs:ensure-fresh)
               (orchestrator.subsumption:subsumption-report facts)
               0))))

(defun run-argue (args)
  "--argue '<γεγονότα>' : η αντιδικία — θέση και ενστάσεις με τις αποδείξεις τους."
  (let ((facts (%case-facts-arg args "--argue")))
    (if (null facts) 1
        (progn (orchestrator.knowledge-packs:ensure-fresh)
               (orchestrator.dialectic:dialectic-report facts)
               0))))

(defun run-what-if (args)
  "--what-if <κανόνας> '<γεγονότα>' : κρίσιμα γεγονότα + ελάχιστα σύνολα φραγής."
  (let ((norm-id (and (first args)
                      (intern (string-upcase (string-left-trim ":" (first args))) :keyword)))
        (facts (%case-facts-arg (rest args) "--what-if <κανόνας>")))
    (if (or (null norm-id) (null facts)) 1
        (progn (orchestrator.knowledge-packs:ensure-fresh)
               (orchestrator.counterfactual:what-if-report facts norm-id)))))

(defun run-subsume-text (args)
  "--subsume-text '<αφήγηση>' : Σ4β — η αφήγηση διαβάζεται με τη γραμματική
   πτώσεων, τα γεγονότα τυπώνονται, και ακολουθεί ΥΠΑΓΩΓΗ. Ό,τι δεν
   αναγνωρίζεται, δηλώνεται."
  (let ((text (format nil "~{~A~^ ~}" args)))
    (if (zerop (length (string-trim " " text)))
        (progn (format t "χρήση: --subsume-text 'Ο Α αφαίρεσε το πορτοφόλι της Β για να το ιδιοποιηθεί.'~%") 1)
        (progn (orchestrator.knowledge-packs:ensure-fresh)
               (orchestrator.casegrammar:narrative-report text)))))

(defun run-think (args)
  "--think '<γεγονότα>' '<στόχος>' : η ΑΛΥΣΙΔΑ ΣΥΛΛΟΓΙΣΜΟΥ — σχεδιασμός
   απόδειξης ανάποδα (κανόνες + tatbestand), βήματα-δεδομένα, και είτε η
   πλήρης forward απόδειξη είτε το ακριβές μέτωπο της άγνοιας."
  (let ((facts (and (first args)
                    (handler-case (orchestrator.subsumption:parse-case-facts (first args))
                      (error (e) (format t "άκυρα γεγονότα: ~A~%" e) nil))))
        (goal (and (second args)
                   (handler-case (first (orchestrator.subsumption:parse-case-facts (second args)))
                     (error (e) (format t "άκυρος στόχος: ~A~%" e) nil)))))
    (if (or (null facts) (null goal))
        (progn (format t "χρήση: --think '((:γεγονός :Α :αφαιρεί :Π) …)' '((:deontic :?τ (:πράξη :?δ :κλοπή :?π) :by :?ν))'~%") 1)
        (progn (orchestrator.knowledge-packs:ensure-fresh)
               (let ((orchestrator.knowledge:*extra-rules*
                       (orchestrator.subsumption:norm-planning-rules)))
                 (if (orchestrator.knowledge:think goal facts nil) 0 1))))))

(defun run-strategy (args)
  "--strategy <σήμερα> '<γεγονότα>' '<στόχος>' : δικονομικό πλάνο (Σ9) με
   αποδείξεις εμπροθέσμου — ή τους ρητούς λόγους αποκλεισμού."
  (let ((today (first args))
        (facts (and (second args)
                    (handler-case (orchestrator.subsumption:parse-case-facts (second args))
                      (error (e) (format t "άκυρα γεγονότα: ~A~%" e) nil))))
        (goal  (and (third args)
                    (handler-case (first (orchestrator.subsumption:parse-case-facts (third args)))
                      (error (e) (format t "άκυρος στόχος: ~A~%" e) nil)))))
    (if (or (null today) (null facts) (null goal))
        (progn (format t "χρήση: --strategy 2026-06-25 '((:γεγονός :απόφαση :οριστική) …)' '((:γεγονός :έφεση :ασκήθηκε))'~%") 1)
        (progn (orchestrator.knowledge-packs:ensure-fresh)
               (orchestrator.strategy:strategy-report facts goal :today today)))))

;;; ============================================================================
;;; Η ΠΥΛΗ Σ4-Σ6 — οι κανονικές υποθέσεις του χάρτη, κλειδωμένες
;;; ============================================================================

(defparameter +gate-klopi-pliris+
  '((:γεγονός :Α :αφαιρεί :εργαλεία)
    (:γεγονός :εργαλεία :είναι :κινητό)
    (:γεγονός :εργαλεία :είναι :ξένο)
    (:γεγονός :Α :σκοπός :παράνομη-ιδιοποίηση)
    (:γεγονός :Α :φοράει :καπέλο))          ; αδιάφορο — για τον υποθετικό λόγο
  "Κλοπή ΠΚ 372, πλήρης ειδική υπόσταση + ένα αδιάφορο γεγονός.")

(defun run-subsumption-gate ()
  "--subsumption-gate : οι κλειδωμένες υποθέσεις των Σ4-Σ6. Μία αποτυχία ⇒ 1."
  (orchestrator.knowledge-packs:ensure-fresh)
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label))))
             (status-for (facts norm-id)
               (let ((norm (orchestrator.deontic:find-norm norm-id)))
                 (multiple-value-bind (engine) (orchestrator.subsumption:subsume facts)
                   (orchestrator.subsumption:conclusion-status engine norm facts)))))
      (format t "~%── ΠΥΛΗ ΥΠΑΓΩΓΗΣ (Σ4-Σ6) ──~%")

      ;; ── Σ4: υπαγωγή ──
      (check "372 πλήρης: η ΑΠΑΓΟΡΕΥΣΗ στοιχειοθετείται (:in)"
             (eq :in (status-for +gate-klopi-pliris+ :norm-klopi-372)))
      (check "372 χωρίς σκοπό ιδιοποίησης: ΔΕΝ στοιχειοθετείται + ονομάζεται το κενό"
             (let ((facts (remove '(:γεγονός :Α :σκοπός :παράνομη-ιδιοποίηση)
                                  +gate-klopi-pliris+ :test #'equal)))
               (and (eq :not-triggered (status-for facts :norm-klopi-372))
                    (multiple-value-bind (have missing)
                        (orchestrator.subsumption:norm-gaps
                         (orchestrator.deontic:find-norm :norm-klopi-372) facts)
                      (and (= 3 (length have)) (= 1 (length missing))
                           (search "ΣΚΟΠ" (format nil "~S" missing)))))))
      (check "372 με συναίνεση κατόχου: η ειδική υπόσταση πλήρης αλλά ΑΙΡΕΤΑΙ (:out)"
             (eq :out (status-for (cons '(:γεγονός :Α :έχει-συναίνεση-κατόχου :εργαλεία)
                                        +gate-klopi-pliris+)
                                  :norm-klopi-372)))
      (check "299 με νόμιμη άμυνα: αίρεται (:out)"
             (eq :out (status-for '((:γεγονός :Β :θανατώνει :Γ)
                                    (:γεγονός :Β :ενεργεί-με :δόλο)
                                    (:γεγονός :Β :τελεί-σε :νόμιμη-άμυνα))
                                  :norm-anthropoktonia-299)))
      (check "914 πλήρης: η ΥΠΟΧΡΕΩΣΗ αποζημίωσης στοιχειοθετείται"
             (eq :in (status-for '((:γεγονός :Δ :ζημιώνει :Ε)
                                   (:γεγονός :Δ :ενεργεί :παράνομα)
                                   (:γεγονός :Δ :ενεργεί :υπαίτια))
                                 :norm-adikopraxia-914)))
      (check "διάκριση 372/375: κατοχή+ιδιοποίηση ⇒ υπεξαίρεση, ΟΧΙ κλοπή"
             (let ((facts '((:γεγονός :Ζ :ιδιοποιείται :ποσό)
                            (:γεγονός :ποσό :είναι :κινητό)
                            (:γεγονός :ποσό :είναι :ξένο)
                            (:γεγονός :ποσό :στην-κατοχή-του :Ζ))))
               (and (eq :in (status-for facts :norm-ypexairesi-375))
                    (eq :not-triggered (status-for facts :norm-klopi-372)))))
      ;; η απόδειξη φέρει την ΠΗΓΗ (τα γεγονότα-ερείσματα ως δεδομένα)
      (multiple-value-bind (engine positions)
          (orchestrator.subsumption:subsume +gate-klopi-pliris+)
        (declare (ignore engine))
        (check "η θέση φέρει δέντρο απόδειξης με τα γεγονότα-ερείσματα"
               (let ((pos (find-if (lambda (p) (member :norm-klopi-372 (car p)))
                                   positions)))
                 (and pos (search "ΑΦΑΙΡΕ" (format nil "~S" (cdr pos)))))))

      ;; ── ΟΡΓΑΝΟΝ: Κατηγορίαι + Barbara + μη-αντίφαση ──
      (check "Barbara: μετρητά σε φάκελο ⇒ κινητό ⇒ η κλοπή στοιχειοθετείται (χωρίς ρητό «κινητό»)"
             (eq :in (status-for '((:γεγονός :Α :αφαιρεί :φάκελος-χρημάτων)
                                   (:γεγονός :φάκελος-χρημάτων :είναι :μετρητά)
                                   (:γεγονός :φάκελος-χρημάτων :είναι :ξένο)
                                   (:γεγονός :Α :σκοπός :παράνομη-ιδιοποίηση))
                                 :norm-klopi-372)))
      (check "δόγμα δημιουργού: ΑΦΗΡΗΜΕΝΟ χρηματικό ποσό (απαίτηση) ⇒ ΟΧΙ κλοπή — λείπει το «κινητό»"
             (eq :not-triggered
                 (status-for '((:γεγονός :Α :αφαιρεί :οφειλόμενο-ποσό)
                               (:γεγονός :οφειλόμενο-ποσό :είναι :χρηματικό-ποσό)
                               (:γεγονός :οφειλόμενο-ποσό :είναι :ξένο)
                               (:γεγονός :Α :σκοπός :παράνομη-ιδιοποίηση))
                             :norm-klopi-372)))
      (check "μη-αντίφαση (Περί Ερμηνείας): κινητό ΚΑΙ ακίνητο ⇒ ΑΠΟΔΕΔΕΙΓΜΕΝΗ (:αντίφασις …)"
             (multiple-value-bind (engine)
                 (orchestrator.subsumption:subsume
                  '((:γεγονός :Χ :είναι :κινητό)
                    (:γεγονός :Χ :είναι :ακίνητο)))
               (plusp (length (orchestrator.inference:query
                               engine '(:αντίφασις ?x ?α ?β))))))

      ;; ── Σ4β: γραμματική πτώσεων — αφήγηση → γεγονότα → υπαγωγή ──
      (multiple-value-bind (facts unparsed)
          (orchestrator.casegrammar:parse-narrative
           "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας για να το ιδιοποιηθεί.")
        (check "αφήγηση κλοπής: αναγνωρίζονται πράξη+κατηγορία+ξένο+σκοπός, τίποτα ανερμήνευτο"
               (and (null unparsed)
                    (>= (length facts) 4)
                    (eq :in (status-for facts :norm-klopi-372)))))
      (multiple-value-bind (facts unparsed)
          (orchestrator.casegrammar:parse-narrative
           "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας.")
        (declare (ignore unparsed))
        (check "αφήγηση χωρίς σκοπό ιδιοποίησης ⇒ η κλοπή ΔΕΝ στοιχειοθετείται"
               (and facts (not (eq :in (status-for facts :norm-klopi-372))))))
      (multiple-value-bind (facts unparsed)
          (orchestrator.casegrammar:parse-narrative "Η βροχή έπεφτε όλη νύχτα.")
        (check "άσχετη αφήγηση ⇒ ΚΑΝΕΝΑ γεγονός δεν εφευρίσκεται, η πρόταση δηλώνεται ανερμήνευτη"
               (and (null facts) (= 1 (length unparsed)))))

      ;; ── ΑΡΝΗΣΗ (εσωτερικός έλεγχος 05-07-2026): ενεργός κίνδυνος ορθότητας ──
      ;; «δεν αφαίρεσε» ΔΕΝ επιτρέπεται να παραγάγει καταφατικό :αφαιρεί
      (multiple-value-bind (facts unparsed)
          (orchestrator.casegrammar:parse-narrative
           "Ο Ανδρέας δεν αφαίρεσε το πορτοφόλι της Μαρίας.")
        (check "ΑΡΝΗΣΗ: «δεν αφαίρεσε» ⇒ :άρνηση, ΚΑΝΕΝΑ καταφατικό :αφαιρεί, η κλοπή ΔΕΝ στοιχειοθετείται"
               (and (null unparsed)
                    (member :αφαιρεί facts :key (lambda (f) (and (eq (car f) :άρνηση) (third f))))
                    (notany (lambda (f) (and (eq (car f) :γεγονός) (eq (third f) :αφαιρεί))) facts)
                    (not (eq :in (status-for facts :norm-klopi-372))))))
      ;; ── ΜΟΡΦΟΛΟΓΙΑ: ονομαστική=δράστης, αιτιατική=θέμα, ακόμη και σε σειρά OVS ──
      (multiple-value-bind (facts unparsed)
          (orchestrator.casegrammar:parse-narrative "Τον Γιώργο σκότωσε ο Νίκος.")
        (declare (ignore unparsed))
        (check "ΠΤΩΣΗ: «Τον Γιώργο σκότωσε ο Νίκος» ⇒ δράστης=Νίκος, θύμα=Γιώργος (OVS + ονομαστική)"
               (member '(:γεγονός :ΝΙΚΟΣ :θανατώνει :ΓΙΩΡΓΟΣ) facts :test #'equal)))
      ;; ── ΣΥΝΑΝΑΦΟΡΑ: ο ίδιος διάδικος σε διαφορετικές πτώσεις = ΜΙΑ οντότητα ──
      ;; «ο Γιώργος» (υποκ.) και «τον Γιώργο» (αντικ.) πρέπει να ταυτίζονται —
      ;; αλλιώς το σύστημα χάνει την ταυτότητα του διαδίκου (κρίσιμο για δικηγόρο)
      (let ((subj-facts (orchestrator.casegrammar:parse-narrative "Ο Γιώργος αφαίρεσε το ρολόι."))
            (obj-facts  (orchestrator.casegrammar:parse-narrative "Τον Γιώργο σκότωσε ο Νίκος.")))
        (check "ΣΥΝΑΝΑΦΟΡΑ: «ο Γιώργος»=«τον Γιώργο» ⇒ ΜΙΑ οντότητα :ΓΙΩΡΓΟΣ σε όλες τις πτώσεις"
               (and (find :ΓΙΩΡΓΟΣ subj-facts :key #'second)
                    (find :ΓΙΩΡΓΟΣ obj-facts :key #'fourth))))

      ;; ── ΑΛΥΣΙΔΑ ΣΥΛΛΟΓΙΣΜΟΥ (McCarthy CoT): ο σχεδιαστής απόδειξης ζωντανός ──
      (let ((orchestrator.knowledge:*extra-rules*
              (orchestrator.subsumption:norm-planning-rules)))
        (multiple-value-bind (proved chain)
            (let ((*standard-output* (make-broadcast-stream)))
              (orchestrator.knowledge:think
               '(:deontic :prohibition (:πράξη ?δράστης :κλοπή ?πράγμα) :by :norm-klopi-372)
               +gate-klopi-pliris+ nil))
          (check "αλυσίδα συλλογισμού: πλήρης κλοπή ⇒ αποδεικνύεται, βήματα-δεδομένα με :derive"
                 (and proved (> (length chain) 3)
                      (find :derive chain :key (lambda (st) (getf st :kind))))))
        (let* ((facts (remove '(:γεγονός :Α :σκοπός :παράνομη-ιδιοποίηση)
                              +gate-klopi-pliris+ :test #'equal))
               (plan (orchestrator.knowledge:plan-goal
                      '(:deontic :prohibition (:πράξη ?δράστης :κλοπή ?πράγμα) :by :norm-klopi-372)
                      facts nil)))
          (check "σχέδιο απόδειξης: χωρίς σκοπό ⇒ το μέτωπο άγνοιας ονοματίζει ΑΚΡΙΒΩΣ τον σκοπό"
                 (find-if (lambda (g)
                            (not (eq :fail (orchestrator.inference:unify
                                            g '(:γεγονός ?δ :σκοπός :παράνομη-ιδιοποίηση)))))
                          (orchestrator.knowledge:plan-frontier plan)))))

      ;; ── Ο ΧΩΡΟΣ ΥΠΟΘΕΣΗΣ: όλοι οι ειδικοί σε ΜΙΑ αρένα ──
      (check "χώρος υπόθεσης: ο φάκελος φέρει υπαγωγή+αντιδικία+κρίσιμα+προηγούμενα+θεμελίωση"
             (let ((out (with-output-to-string (st)
                          (case-workspace +gate-klopi-pliris+ :stream st))))
               (and (search "ΦΑΚΕΛΟΣ ΥΠΟΘΕΣΗΣ" out)
                    (search "ΥΠΑΓΩΓΗ" out) (search "ΑΝΤΙΔΙΚΙΑ" out)
                    (search "ΚΡΙΣΙΜΑ" out) (search "ΠΡΟΗΓΟΥΜΕΝΑ" out)
                    (search "ΘΕΜΕΛΙΩΣΗ" out))))
      (check "προηγούμενα: το δέσιμο νομολογίας βρίσκει αποφάσεις που εφαρμόζουν άρθρο (ΠΚ 380 ⇒ ≥1)"
             (plusp (length (%decisions-citing "poinikos" "380"))))
      ;; ΤΟ ΔΕΣΙΜΟ ΤΩΝ ΕΙΔΙΚΩΝ (Global-Workspace συμπεριφορά, κλειδωμένη):
      ;; ένσταση που ΡΙΧΝΕΙ τη θέση στο ② πρέπει να ΣΩΠΑΙΝΕΙ τα ③/④ — οι
      ;; ειδικοί επικοινωνούν μέσω του ΚΟΙΝΟΥ σταθερού σημείου του JTMS,
      ;; όχι μέσω ανεξάρτητων εκθέσεων (επαληθευμένο εμπειρικά 05-07-2026).
      (check "ΔΕΣΙΜΟ: πεσμένη θέση (συναίνεση) ⇒ ΚΑΝΕΝΑ κρίσιμο/προηγούμενο γι' αυτήν στα ③/④"
             (let ((out (with-output-to-string (st)
                          (case-workspace
                           (cons '(:γεγονός :Α :έχει-συναίνεση-κατόχου :εργαλεία)
                                 +gate-klopi-pliris+)
                           :stream st))))
               (and (search "καμία ιστάμενη θέση" out)
                    (not (search "NORM-KLOPI-372:" (subseq out (search "③" out)
                                                           (search "④" out)))))))

      ;; ── Σ5: αντιδικία ──
      (multiple-value-bind (standing upheld undecided)
          (let ((*standard-output* (make-broadcast-stream)))
            (orchestrator.dialectic:dialectic-report +gate-klopi-pliris+))
        (check "αντιδικία (πλήρης 372): 1 θέση ίσταται, καμία ένσταση δεν κερδίζει"
               (and (= standing 1) (= upheld 0) (= undecided 0))))
      (multiple-value-bind (standing upheld undecided)
          (let ((*standard-output* (make-broadcast-stream)))
            (orchestrator.dialectic:dialectic-report
             (cons '(:γεγονός :Α :έχει-συναίνεση-κατόχου :εργαλεία) +gate-klopi-pliris+)))
        (check "αντιδικία (με συναίνεση): η ΕΝΣΤΑΣΗ κερδίζει και η θέση πίπτει"
               (and (= standing 0) (>= upheld 1) (= undecided 0))))

      ;; ── Σ6: υποθετικός λόγος ──
      (let ((norm (orchestrator.deontic:find-norm :norm-klopi-372)))
        (multiple-value-bind (critical idle basis-p)
            (orchestrator.counterfactual:critical-facts +gate-klopi-pliris+ norm)
          (check "κρίσιμα: και τα 4 στοιχεία της ειδικής υπόστασης — το καπέλο ΟΧΙ"
                 (and basis-p (= 4 (length critical))
                      (equal idle '((:γεγονός :Α :φοράει :καπέλο)))))
          (check "ελάχιστα σύνολα φραγής: 4 μονομελή, κανένα γνήσιο διμελές"
                 (multiple-value-bind (blockers)
                     (orchestrator.counterfactual:minimal-blockers +gate-klopi-pliris+ norm)
                   (and (= 4 (length blockers))
                        (every (lambda (b) (= 1 (length b))) blockers))))))

      ;; ── Σ9: στρατηγική (STRIPS) — προθεσμίες με απόδειξη ──
      (multiple-value-bind (plan blocked)
          (orchestrator.strategy:plan-course
           '((:γεγονός :απόφαση :οριστική) (:γεγονός :επιδόθηκε "2026-06-10"))
           '(:γεγονός :έφεση :ασκήθηκε) :today "2026-06-25")
        (declare (ignore blocked))
        (check "στρατηγική: έφεση ΕΜΠΡΟΘΕΣΜΗ (επίδοση 10/6, σήμερα 25/6) ⇒ πλάνο με απόδειξη"
               (and (= 1 (length plan))
                    (eq :άσκηση-έφεσης (getf (first plan) :op))
                    (search "ΕΜΠΡΟΘΕΣΜΟ" (getf (first plan) :why)))))
      (multiple-value-bind (plan blocked)
          (orchestrator.strategy:plan-course
           '((:γεγονός :απόφαση :οριστική) (:γεγονός :επιδόθηκε "2026-06-10"))
           '(:γεγονός :έφεση :ασκήθηκε) :today "2026-08-01")
        (check "στρατηγική: σήμερα 1/8 ⇒ ΚΑΝΕΝΑ πλάνο, ο λόγος = ΕΚΠΡΟΘΕΣΜΟ ρητά"
               (and (null plan)
                    (let ((b (assoc :άσκηση-έφεσης blocked)))
                      (and b (search "ΕΚΠΡΟΘΕΣΜΟ" (cdr b)))))))
      (multiple-value-bind (plan blocked)
          (orchestrator.strategy:plan-course
           '((:γεγονός :απόφαση :οριστική))
           '(:γεγονός :έφεση :ασκήθηκε) :today "2026-06-25")
        (check "στρατηγική: χωρίς γεγονός επίδοσης ⇒ ΑΓΝΩΣΤΗ αφετηρία, δηλωμένη — όχι εικασία"
               (and (null plan)
                    (let ((b (assoc :άσκηση-έφεσης blocked)))
                      (and b (search "ΑΓΝΩΣΤΗ" (cdr b)))))))

      ;; ── Σ10: προελευσιακή βεβαιότητα (ασθενέστερος κρίκος) ──
      (multiple-value-bind (engine positions)
          (orchestrator.subsumption:subsume +gate-klopi-pliris+)
        (declare (ignore engine))
        (let ((pos (find-if (lambda (p) (member :norm-klopi-372 (car p))) positions)))
          (multiple-value-bind (weakest kinds)
              (orchestrator.subsumption:proof-grade (cdr pos))
            (check "βεβαιότητα: ασθενέστερος κρίκος = ΔΕΔΟΜΕΝΟ ΥΠΟΘΕΣΗΣ, με τον ΚΑΝΟΝΑ ΠΗΓΗΣ παρόντα"
                   (and (eq weakest :δεδομένο-υπόθεσης)
                        (member :κανόνας-πηγής kinds)))))))

    (format t "~%── ΠΥΛΗ ΥΠΑΓΩΓΗΣ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--subsume"  (lambda (a) (run-subsume a)))
(register-command "--υπαγωγή"  (lambda (a) (run-subsume a)))
(register-command "--argue"    (lambda (a) (run-argue a)))
(register-command "--what-if"  (lambda (a) (run-what-if a)))
(register-command "--strategy" (lambda (a) (run-strategy a)))
(register-command "--subsume-text" (lambda (a) (run-subsume-text a)))
(register-command "--think"    (lambda (a) (run-think a)))
(register-command "--subsumption-gate" (lambda (a) (declare (ignore a)) (run-subsumption-gate)))

(orchestrator.self-model:declare-capability! "γλωσσική-αντίληψη"
 :description "αφήγηση/διάταξη → γεγονότα: πλαίσια πτώσεων, άρνηση, μορφολογία, ημερομηνίες"
 :package :orchestrator.casegrammar :functions '("parse-narrative" "parse-provision" "parse-definition")
 :gate "--subsumption-gate" :depends-on '())
(orchestrator.self-model:declare-capability! "υπαγωγή"
 :description "γεγονότα → κανόνες → απόφανση με απόδειξη + μετα-γνώση του τι λείπει"
 :package :orchestrator.subsumption :functions '("subsume" "conclusion-status" "norm-gaps" "proof-grade")
 :gate "--subsumption-gate" :depends-on '("συμπερασμός-wfs" "γλωσσική-αντίληψη" "δεοντικό"))
(orchestrator.self-model:declare-capability! "αντιδικία"
 :description "θέση ↔ ένσταση με τρίτιμη τύχη και αποδείξεις (grounded semantics)"
 :package :orchestrator.dialectic :functions '("dialectic-report")
 :gate "--subsumption-gate" :depends-on '("υπαγωγή"))
(orchestrator.self-model:declare-capability! "υποθετικός-λόγος"
 :description "κρίσιμα γεγονότα + ελάχιστα σύνολα φραγής (ακριβές ablation)"
 :package :orchestrator.counterfactual :functions '("critical-facts" "minimal-blockers")
 :gate "--subsumption-gate" :depends-on '("υπαγωγή"))
(orchestrator.self-model:declare-capability! "δικονομικός-σχεδιασμός"
 :description "STRIPS τελεστές + πλάνα με αποδείξεις εμπροθέσμου (McCarthy CoT)"
 :package :orchestrator.strategy :functions '("strategy-report" "plan-goal" "think")
 :gate "--subsumption-gate" :depends-on '("συμπερασμός-wfs"))
(orchestrator.self-model:declare-capability! "ομοιότητα-υποθέσεων"
 :description "HYPO/CATO: παράγοντες, διακρίσεις, k-NN διατακτικού"
 :package :orchestrator.hypo :functions '("case-factors" "rank-precedents" "knn-verdict")
 :gate nil :depends-on '("υπαγωγή"))   ; ΧΩΡΙΣ ΠΥΛΗ — δηλωμένο χρέος
