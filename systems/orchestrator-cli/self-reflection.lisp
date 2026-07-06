;;;; systems/orchestrator-cli/self-reflection.lisp
;;;; ============================================================================
;;;; Ο ΕΣΩΤΕΡΙΚΟΣ ΒΡΟΧΟΣ ΤΟΥ LAWMAX — εγγραφές τομέα (νομική) + εντολές
;;;; ============================================================================
;;;;
;;;; Οι γενικοί πυρήνες (orchestrator.introspection, orchestrator.proposals)
;;;; δεν ξέρουν από νομική. Εδώ, ΜΟΝΟ με εγγραφές (open/closed), δίνουμε στον
;;;; LAWMAX τι να παρατηρεί και τι σημαίνει κάθε πρόταση:
;;;;   • είδη προτάσεων: :adopt (υιοθέτησε υποψήφια γνώση) και :need (ανάγκη
;;;;     που δεν λύνεται μόνη της — αίτημα στον δημιουργό)·
;;;;   • παρατηρητές: αποστολή (πλαίσιο), επαναλαμβανόμενα lessons (ανάγκες),
;;;;     υποψήφια γνώση που πέρασε τη σκιώδη δοκιμή (έτοιμες αναβαθμίσεις).
;;;; Νέος τομέας αύριο (π.χ. οικονομικά) = νέοι παρατηρητές εδώ, μηδέν αλλαγή
;;;; στους πυρήνες. Καμία επανάληψη κώδικα.

(in-package :orchestrator.cli)

;;; ── ΕΙΔΗ ΠΡΟΤΑΣΕΩΝ ──────────────────────────────────────────────────────

(orchestrator.proposals:register-proposal-kind
 :adopt
 :describe (lambda (p)
             (format nil "υιοθέτηση γνώσης «~A»"
                     (file-namestring (orchestrator.proposals:proposal-payload p))))
 :on-approve
 (lambda (p)
   ;; Η έγκριση δεν παρακάμπτει την πύλη: το run-adopt-knowledge ΞΑΝΑτρέχει
   ;; τη σκιώδη δοκιμή και μόνο επί μηδέν παλινδρόμησης εγκαθιστά + γράφει
   ;; στη βιογραφία. Ο άνθρωπος λέει «ναι»· η απόδειξη μένει υποχρεωτική.
   (let ((pack (orchestrator.proposals:proposal-payload p)))
     (when (and (stringp pack) (plusp (length pack)) (probe-file pack))
       (run-adopt-knowledge (list pack))))))

(orchestrator.proposals:register-proposal-kind
 :need
 :describe (lambda (p) (orchestrator.proposals:proposal-why p))
 :on-approve
 (lambda (p)
   ;; Μια «ανάγκη» δεν λύνεται μόνη της (θέλει νέα ικανότητα σε κώδικα): η
   ;; έγκριση την αναγνωρίζει ρητά ως αίτημα προς τον δημιουργό και τη γράφει
   ;; στη βιογραφία — η οντότητα ξέρει τι της υποσχέθηκες.
   (format t "  ✓ Αναγνωρισμένη ανάγκη — αίτημα προς τον δημιουργό.~%")
   (ignore-errors
     (orchestrator.self-history:record!
      :need-acknowledged (orchestrator.proposals:proposal-why p)))))

;;; ── ΠΑΡΑΤΗΡΗΤΕΣ ─────────────────────────────────────────────────────────

(defun %observe-mission ()
  "Η απόσταση από κάθε αποστολή — πλαίσιο (:note), όχι πρόταση προς έγκριση."
  (loop for m in (orchestrator.self:mission-status)
        collect (list :sig (format nil "mission:~A" (first m))
                      :kind :note
                      :why (format nil "αποστολή~:[ ΑΝΟΙΧΤΗ~; ✓~]: ~A → ~A"
                                   (third m) (first m) (second m)))))

(defun %tier (n)
  "Βαθμίδα εύρους στο sig: αλλάζει ΜΟΝΟ όταν το πρόβλημα μεγαλώνει ουσιαστικά,
   ώστε μια απορριφθείσα πρόταση να επανέρχεται όταν όντως χειροτερεύει."
  (cond ((>= n 30) "t3") ((>= n 10) "t2") ((>= n 3) "t1") (t "t0")))

(defun %observe-understanding ()
  "ΔΟΜΙΚΟΣ αναστοχασμός — το αντίθετο του «απλοϊκού». Αντί να απαριθμεί κάθε
   απόφαση χωριστά, βλέπει τη ΜΟΡΦΗ της ατέλειάς του: ΠΟΙΟ συστατικό κατανόησης
   (ratio, λόγοι, ανατομία…) αποτυγχάνει ΣΥΣΤΗΜΑΤΙΚΑ και σε πόσες αποφάσεις.
   Μία ρίζα → μία πρόταση. Πηγή η ΖΩΝΤΑΝΗ σάρωση (η αλήθεια της στιγμής), όχι
   το ημερολόγιο (που διπλομετρά τα τρεξίματα)."
  (multiple-value-bind (perfect total gaps) (%understanding-scan nil)
    (declare (ignore perfect total))
    (let ((by-component (make-hash-table :test 'equal))
          (examples (make-hash-table :test 'equal)))
      (maphash (lambda (first-comp entries)
                 (declare (ignore first-comp))
                 (dolist (e entries)                 ; e = (id . missing-list)
                   (dolist (comp (cdr e))
                     (incf (gethash comp by-component 0))
                     (when (< (length (gethash comp examples '())) 3)
                       (pushnew (car e) (gethash comp examples) :test #'equal)))))
               gaps)
      (let (out)
        (maphash (lambda (comp n)
                   (when (>= n 3)                    ; μόνο ΣΥΣΤΗΜΑΤΙΚΟ κενό
                     (push (list :sig (format nil "gap:~A:~A" comp (%tier n))
                                 :kind :need
                                 :why (format nil "Δομικό κενό «~A»: ~D αποφάσεις δεν το έχουν (πχ ~{~A~^· ~}). Ρίζα: η γραμματική του «~A» — μία διόρθωση τις καλύπτει όλες."
                                              comp n (reverse (gethash comp examples)) comp))
                           out)))
                 by-component)
        (nreverse out)))))

(defun %observe-lessons ()
  "Ρίζα ανά ΕΙΔΟΣ αποτυχίας — όχι ανά στιγμιότυπο. Ομαδοποιεί τα lessons ανά
   kind (ΕΚΤΟΣ των understanding-gap — αυτά τα βλέπει δομικά ο
   %observe-understanding), μετρά ΔΙΑΚΡΙΤΑ αντικείμενα (όχι επαναλήψεις
   καταγραφής) και προτείνει ΜΙΑ διόρθωση στη ρίζα ανά είδος."
  (let ((by-kind (make-hash-table :test 'equal)))
    (dolist (row (%lessons-aggregate))              ; (count kind subject)
      (let ((kind (second row)) (subject (third row)))
        (unless (equal kind "understanding-gap")
          (pushnew subject (gethash kind by-kind '()) :test #'equal))))
    (let (out)
      (maphash (lambda (kind subjects)
                 (let ((n (length subjects)))
                   (push (list :sig (format nil "kind:~A:~A" kind (%tier n))
                               :kind :need
                               :why (format nil "«~A»: ~D διακριτ~:[ά αντικείμενα~;ό αντικείμενο~] (πχ ~{~A~^· ~}) — μία διόρθωση στη ρίζα."
                                            kind n (= n 1)
                                            (subseq (reverse subjects) 0 (min 3 n))))
                         out)))
               by-kind)
      (nreverse out))))

(defun %observe-candidates ()
  "Υποψήφια γνώση στο deployment/self/candidates/*.sexp που ΠΕΡΝΑΕΙ τη σκιώδη
   δοκιμή (0 παλινδρομήσεις) → πρόταση υιοθέτησης, με το sha της στο sig ώστε
   αλλαγή του αρχείου να γεννά νέα πρόταση. Η σκιά τρέχει σιωπηλά εδώ."
  (let ((cdir (merge-pathnames "deployment/self/candidates/" (uiop:getcwd)))
        (out '()))
    (when (probe-file cdir)
      (dolist (f (directory (merge-pathnames "*.sexp" cdir)))
        (let ((rc 1))
          (ignore-errors
            (let ((*standard-output* (make-broadcast-stream)))   ; σιωπηλή δοκιμή
              (setf rc (run-shadow-knowledge (list (namestring f))))))
          (when (eql rc 0)
            (push (list :sig (format nil "candidate:~A:~A" (file-namestring f)
                                     (or (ignore-errors
                                           (subseq (orchestrator.knowledge-packs:pack-sha f) 0 12))
                                         "?"))
                        :kind :adopt
                        :why (format nil "Υποψήφια γνώση «~A» πέρασε τη σκιώδη δοκιμή με 0 παλινδρομήσεις — έτοιμη προς υιοθέτηση."
                                     (file-namestring f))
                        :payload (namestring f))
                  out)))))
    (nreverse out)))

;;; ── ΣΥΝΤΑΓΜΑΤΙΚΟΙ ΚΑΝΟΝΕΣ (τομέα) ──────────────────────────────────────
;;; Ο υπέρτατος φραγμός, δηλωμένος: η φόρτωση ΝΕΩΝ αποφάσεων υπόκειται στην
;;; αποστολή «κατάλαβε 1/1 πριν φορτώσεις». Νέος κανόνας αύριο = νέα εγγραφή,
;;; μηδέν αλλαγή στη μηχανή του φραγμού (open/closed).

(orchestrator.constitution:register-rule
 :id :understanding-before-load
 :article "Αποστολή :understanding (Άρθρο 6) — «πλήρης κατανόηση κάθε απόφασης (1/1) πριν φορτωθούν νέες»"
 :applies-to '("--fetch-decision" "--fetch-year" "--watch-decisions")
 :predicate
 (lambda ()
   (multiple-value-bind (perfect total) (%understanding-scan nil)
     (cond
       ((zerop total) (values t nil))            ; τίποτα να καταλάβω ακόμη — αρχική φόρτωση επιτρεπτή
       ((= perfect total) (values t nil))        ; 1/1 — ελεύθερη επέκταση
       (t (values nil (format nil "κατανόηση ~D/~D (~D%) — όχι ακόμη 1/1· ~D αποφάσεις αδιάβαστες"
                              perfect total (round (* 100 perfect) total) (- total perfect))))))))

(defun %observe-will ()
  "Η ΒΟΥΛΗΣΗ, δίπλα στο εγώ: σε ΚΑΘΕ κύκλο αναστοχασμού (χειροκίνητο --reflect
   ή αυτόνομο του δαίμονα) η μηχανή μετρά την απόσταση από την αποστολή
   αυτομόρφωσης και ΖΗΤΑ, ως πρόταση, τη γραμματική που θα τη μίκραινε
   περισσότερο — κοστολογημένα, ποτέ αόριστα."
  (let ((st (ignore-errors (%study-cached "poinikos"))))
    (when st
      (let ((mv (getf st :missing-verbs)))
        (when mv
          (let* ((top (subseq mv 0 (min 3 (length mv))))
                 (unlock (reduce #'+ top :key #'cdr)))
            (list (list :sig (format nil "will:grammar:~A" (%tier unlock))
                        :kind :need
                        :why (format nil "ΒΟΥΛΗΣΗ: για την αποστολή αυτομόρφωσης χρειάζομαι ~D πλαίσια ρημάτων —~{ «~A» (~D άρθρα)~^ ·~} — μία γραμμή :frame το καθένα στο casegrammar-core."
                                     (length top)
                                     (loop for (v . c) in top append (list v c)))))))))))

(orchestrator.introspection:register-observer "mission"       #'%observe-mission)
(orchestrator.introspection:register-observer "βούληση"       #'%observe-will)
(orchestrator.introspection:register-observer "understanding" #'%observe-understanding)
(orchestrator.introspection:register-observer "lessons"       #'%observe-lessons)
(orchestrator.introspection:register-observer "candidates"    #'%observe-candidates)

;;; ── ΕΝΤΟΛΕΣ ─────────────────────────────────────────────────────────────

(defun run-reflect ()
  "--reflect : Ο LAWMAX κοιτάζει τον εαυτό του — αποστολή, επαναλαμβανόμενα
   κενά, υποψήφιες αναβαθμίσεις. Σκέψεις ορατές· προτάσεις στο μητρώο· το
   «όχι» σου προσωρινό (αν αλλάξουν τα στοιχεία, ξαναπροτείνει)."
  (orchestrator.self:ensure-constitution)
  (let ((new (orchestrator.introspection:run-introspection)))
    (format t "~%~D νέες προτάσεις αυτόν τον κύκλο.~%" new)
    (orchestrator.proposals:describe-proposals)
    0))

(defun run-thoughts ()
  "--thoughts : Τι σκέφτεται/ζητά ο LAWMAX τώρα — οι ανοιχτές προτάσεις του."
  (orchestrator.proposals:describe-proposals)
  0)

(defun run-approve (args)
  "--approve <id> : έγκριση πρότασης (η :adopt περνά ΞΑΝΑ τη σκιώδη πύλη)."
  (let ((id (first args)))
    (if (null id)
        (progn (format t "χρήση: --approve <id>~%") 1)
        (multiple-value-bind (p why) (orchestrator.proposals:approve! id)
          (if p (progn (format t "~%✓ Εγκρίθηκε #~A~%" id) 0)
              (progn (format t "Δεν εγκρίθηκε #~A (~A)~%" id why) 1))))))

(defun run-reject (args)
  "--reject <id> : προσωρινή απόρριψη (ίδια στοιχεία δεν επανέρχονται)."
  (let ((id (first args)))
    (if (null id)
        (progn (format t "χρήση: --reject <id>~%") 1)
        (multiple-value-bind (p why) (orchestrator.proposals:reject! id)
          (declare (ignore p))
          (if (eq why :rejected)
              (progn (format t "~%⨯ Απορρίφθηκε #~A (προσωρινά — αν αλλάξουν τα στοιχεία, θα ξαναπροταθεί)~%" id) 0)
              (progn (format t "Δεν απορρίφθηκε #~A (~A)~%" id why) 1))))))

;;; ── Ο ΚΑΘΡΕΦΤΗΣ: εντολές αυτοεπίγνωσης πάνω στο μητρώο ικανοτήτων ───────
;;; Η ουσία ζει στο orchestrator.self-model (μία έδρα)· εδώ ΜΟΝΟ η όψη CLI.

(defun %gate-names ()
  "Οι εντολές-πύλες, από το ζωντανό μητρώο — ποτέ χειρόγραφη λίστα."
  (let ((names '()))
    (maphash (lambda (k v)
               (declare (ignore v))
               (when (and (> (length k) 5)
                          (string= "-gate" k :start2 (- (length k) 5)))
                 (push k names)))
             *commands*)
    (sort names #'string<)))

(defun run-mirror ()
  "--mirror : η απογραφή του εαυτού — συστήματα, εντολές, πύλες, ικανότητες
   με έδρα/πύλη/εξαρτήσεις, ορφανές πύλες, δηλωμένα χρέη. Όλα ΥΠΟΛΟΓΙΣΜΕΝΑ
   από τη ζωντανή εικόνα τη στιγμή της ερώτησης."
  (let* ((caps (orchestrator.self-model:all-capabilities))
         (gates (%gate-names))
         (declared-gates (remove nil (mapcar #'orchestrator.self-model:capability-gate caps)))
         (orphans (set-difference gates declared-gates :test #'string=))
         (debts (remove-if #'orchestrator.self-model:capability-gate caps)))
    (format t "~%══ ΚΑΘΡΕΦΤΗΣ — ποιος είμαι, διαβασμένο τώρα ══~%")
    (format t "~%▸ Συστήματα ASDF: ~{~A~^ · ~}~%"
            (loop for s in '("orchestrator-infrastructure" "orchestrator-cli")
                  for sys = (ignore-errors (asdf:find-system s))
                  when sys collect (format nil "~A ~@[v~A~]"
                                           (asdf:component-name sys)
                                           (ignore-errors (asdf:component-version sys)))))
    (format t "▸ Εντολές στο μητρώο: ~D · Πύλες: ~D (~{~A~^, ~})~%"
            (hash-table-count *commands*) (length gates) gates)
    (format t "~%▸ Ικανότητες (~D):~%" (length caps))
    (dolist (c caps)
      (format t "  • ~A — έδρα ~(~A~) · ~:[ΧΡΕΟΣ: χωρίς πύλη~;πύλη ~:*~A~]~@[ · εξαρτάται: ~{~A~^, ~}~]~%"
              (orchestrator.self-model:capability-name c)
              (orchestrator.self-model:capability-package c)
              (orchestrator.self-model:capability-gate c)
              (orchestrator.self-model:capability-depends-on c)))
    (if orphans
        (format t "~%▸ ΟΡΦΑΝΕΣ πύλες (χωρίς δηλωμένη ικανότητα): ~{~A~^, ~} — ΧΡΕΟΣ.~%" orphans)
        (format t "~%▸ Καμία ορφανή πύλη — κάθε πύλη αποδεικνύει δηλωμένη ικανότητα.~%"))
    (when debts
      (format t "▸ Δηλωμένα χρέη (ικανότητες χωρίς πύλη): ~{~A~^, ~}~%"
              (mapcar #'orchestrator.self-model:capability-name debts)))
    0))

(defun run-capability-gap (args)
  "--gap <ικανότητα> : έχω αυτή την ικανότητα; Τίμιο ✔/✘ + τι απαιτεί η
   απόκτηση. Το ✘ γίνεται ΜΑΘΗΜΑ (capability-gap) — περιέργεια, όχι σιωπή."
  (let ((wanted (format nil "~{~A~^ ~}" args)))
    (if (zerop (length wanted))
        (progn (format t "χρήση: --gap <ικανότητα>~%") 1)
        (let ((have (orchestrator.self-model:capability-gap-report wanted)))
          (unless have
            (%lesson "capability-gap" wanted
                     "ζητήθηκε ικανότητα που δεν έχω — υποψήφιο επόμενο κύμα"))
          0))))

(defun run-mirror-gate ()
  "--mirror-gate : η αυτοεπίγνωση, κλειδωμένη — ο καθρέφτης δεν λέει ψέματα."
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΚΑΘΡΕΦΤΗ: το σύστημα γνωρίζει τον εαυτό του ──~%")
      (let* ((caps (orchestrator.self-model:all-capabilities))
             (gates (%gate-names))
             (declared (remove nil (mapcar #'orchestrator.self-model:capability-gate caps))))
        ;; ① πληρότητα: το μητρώο δεν είναι διακοσμητικό
        (check (format nil "① ≥21 δηλωμένες ικανότητες (τώρα: ~D)" (length caps))
               (>= (length caps) 21))
        ;; ② κάθε δηλωμένη πύλη ΥΠΑΡΧΕΙ στο μητρώο εντολών (όχι κρεμασμένα ονόματα)
        (check "② κάθε δηλωμένη πύλη υπάρχει ως εντολή — καμία κρεμασμένη αναφορά"
               (every (lambda (g) (find-command g)) declared))
        ;; ③ ΚΑΜΙΑ ορφανή πύλη: νέα πύλη ⇒ υποχρεωτική δήλωση ικανότητας (ratchet)
        (check "③ καμία «-gate» εντολή χωρίς δηλωμένη ικανότητα (ratchet αυτοεπίγνωσης)"
               (null (set-difference gates declared :test #'string=)))
        ;; ④ κάθε εξάρτηση δείχνει σε ΥΠΑΡΚΤΗ ικανότητα (ο γράφος είναι κλειστός)
        (check "④ κάθε εξάρτηση δείχνει σε δηλωμένη ικανότητα — κλειστός γράφος"
               (every (lambda (c)
                        (every #'orchestrator.self-model:find-capability
                               (orchestrator.self-model:capability-depends-on c)))
                      caps))
        ;; ⑤ αιτιώδης επίπτωση: αλλαγή στον λογισμό φραγμών ⇒ υπαγωγή+παραδοτέο
        ;;    κληρονομούν τον κίνδυνο και οι πύλες τους μπαίνουν στο regression
        (multiple-value-bind (affected regression)
            (orchestrator.self-model:capability-impact "λογισμός-φραγμών")
          (let ((names (mapcar #'orchestrator.self-model:capability-name affected)))
            (check "⑤ impact(λογισμός-φραγμών) ⊇ {υπαγωγή, παραδοτέο} — μεταβατικό κλείσιμο"
                   (and (member "υπαγωγή" names :test #'string=)
                        (member "παραδοτέο" names :test #'string=)))
            (check "⑥ το regression της περιλαμβάνει --subsumption-gate και --draft-gate"
                   (and (member "--subsumption-gate" regression :test #'string=)
                        (member "--draft-gate" regression :test #'string=)))))
        ;; ⑦ ανεξάρτητη ικανότητα ΔΕΝ μολύνεται: η ρευστή-επαγωγή δεν εξαρτάται
        ;;    από τον λογισμό φραγμών ⇒ εκτός του συνόλου επίπτωσης
        (check "⑦ η ρευστή-επαγωγή ΕΚΤΟΣ impact(λογισμός-φραγμών) — καμία ψευδο-εξάρτηση"
               (not (member "ρευστή-επαγωγή"
                            (mapcar #'orchestrator.self-model:capability-name
                                    (orchestrator.self-model:capability-impact "λογισμός-φραγμών"))
                            :test #'string=)))
        ;; ⑧ τίμιο κενό: υπαρκτή ⇒ T, ανύπαρκτη ⇒ NIL (ποτέ ψευδής κατάφαση)
        (let ((sink (make-broadcast-stream)))
          (check "⑧ gap-report: «υπαγωγή» ⇒ ✔ T, «τηλεπάθεια» ⇒ ✘ NIL — τίμιος καθρέφτης"
                 (and (orchestrator.self-model:capability-gap-report "υπαγωγή" sink)
                      (not (orchestrator.self-model:capability-gap-report "τηλεπάθεια" sink)))))
        ;; ⑨ τα δηλωμένα χρέη είναι ΡΗΤΑ :gate nil — και υπαρκτά ως γνωστά χρέη
        (check "⑨ οι ικανότητες χωρίς πύλη είναι δηλωμένο χρέος, ορατό στον --mirror"
               (every (lambda (c)
                        (or (orchestrator.self-model:capability-gate c)
                            (member (orchestrator.self-model:capability-name c)
                                    '("ομοιότητα-υποθέσεων" "πρόσληψη-νομολογίας")
                                    :test #'string=)))
                      caps))))
    (format t "~%── ΠΥΛΗ ΚΑΘΡΕΦΤΗ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--mirror"      (lambda (a) (declare (ignore a)) (run-mirror)))
(register-command "--καθρέφτης"   (lambda (a) (declare (ignore a)) (run-mirror)))
(register-command "--gap"         (lambda (a) (run-capability-gap a)))
(register-command "--mirror-gate" (lambda (a) (declare (ignore a)) (run-mirror-gate)))

(orchestrator.self-model:declare-capability! "αυτοεπίγνωση"
 :description "ο καθρέφτης: μητρώο ικανοτήτων, αιτιώδης επίπτωση, τίμιος αναλυτής κενών"
 :package :orchestrator.self-model
 :functions '("declare-capability!" "capability-impact" "capability-gap-report")
 :gate "--mirror-gate" :depends-on '())

(register-command "--reflect"  (lambda (a) (declare (ignore a)) (run-reflect)))
(register-command "--αναστοχασμός" (lambda (a) (declare (ignore a)) (run-reflect)))
(register-command "--thoughts" (lambda (a) (declare (ignore a)) (run-thoughts)))
(register-command "--σκέψεις"  (lambda (a) (declare (ignore a)) (run-thoughts)))
(register-command "--approve"  (lambda (a) (run-approve a)))
(register-command "--reject"   (lambda (a) (run-reject a)))
