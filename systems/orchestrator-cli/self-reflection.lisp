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

;;; ── Η ΘΕΣΜΙΚΗ ΤΑΥΤΟΤΗΤΑ: το Ίδρυμα, οι ρόλοι, το συμβόλαιο ταυτότητας ───
;;; Ο μηχανισμός ζει στο orchestrator.self-model· εδώ η ΔΗΛΩΣΗ του τομέα:
;;; ποιο Ίδρυμα είναι αυτό, με ποια όργανα. ΟΧΙ φράση README — αντικείμενα
;;; που η πύλη του καθρέφτη ελέγχει.

(orchestrator.institution:declare-role! "συντονισμός"
 :description "ο orchestrator: το ΕΣΩΤΕΡΙΚΟ όργανο συντονισμού — εντολές, dispatch, ολομέλεια πυλών· ΔΕΝ είναι η ταυτότητα του όλου")
(orchestrator.institution:declare-role! "σύνταγμα"
 :description "το καταστατικό όργανο: συνταγματικοί φραγμοί, πολιτικές έγκρισης, override με λόγο")
(orchestrator.institution:declare-role! "νομική-μνήμη"
 :description "corpus, ταυτότητα άρθρων, νομολογία, πακέτα γνώσης, επεισοδιακή μνήμη")
(orchestrator.institution:declare-role! "αποδείξεις"
 :description "συμπερασμός WFS/JTMS, μετακυκλικός αποτιμητής, πιστοποιητικά, υπαγωγή/αντιδικία")
(orchestrator.institution:declare-role! "γλώσσα"
 :description "ελληνική αντίληψη (πτώσεις, άρνηση, χρόνος) και γένεση (κλίση, συμφωνία)")
(orchestrator.institution:declare-role! "νόηση"
 :description "διάλογος, ρευστή επαγωγή, γνωσιακή ροή — η γενική αντίληψη του Ιδρύματος")
(orchestrator.institution:declare-role! "έλεγχος"
 :description "πύλες, μαθήματα, audit, ο καθρέφτης — το όργανο που δεν αφήνει το Ίδρυμα να λέει ψέματα στον εαυτό του")
(orchestrator.institution:declare-role! "αυτοεξέλιξη"
 :description "αυτο-προτάσεις, σκιώδης δοκιμή, υιοθέτηση με έγκριση + rollback, σύμβουλος-LLM εκτός εμπιστοσύνης")
(orchestrator.institution:declare-role! "χειρισμός-υποθέσεων"
 :description "matters: φάκελοι υποθέσεων, παραδοτέα, προθεσμίες — το μέτωπο προς τον δικηγόρο")

(orchestrator.institution:declare-institution!
 :name "LAWMAX Legal Institution"
 :description "Ψηφιακό νομικό Ίδρυμα: θεσμική πολυπρακτορική νοημοσύνη στην υπηρεσία του δημιουργού"
 :coordination-engine "συντονισμός"
 :organs '("συντονισμός" "σύνταγμα" "νομική-μνήμη" "αποδείξεις" "γλώσσα"
           "νόηση" "έλεγχος" "αυτοεξέλιξη" "χειρισμός-υποθέσεων"))

(orchestrator.contracts:defcontract "institutional-identity" :institutional-identity
 :package :orchestrator.self-model :system "orchestrator-infrastructure"
 :capability "αυτοεπίγνωση"
 :purpose "Είμαι το LAWMAX Legal Institution. Ο orchestrator είναι το coordination engine μου — εσωτερικό όργανο, όχι η ταυτότητά μου. Οι πύλες, οι ικανότητες, οι μνήμες, τα proofs και τα adoption gates είναι θεσμικά όργανα/λειτουργίες μου."
 :postconditions '("η μηχανή συντονισμού είναι δηλωμένος ρόλος, διακριτός από το όνομα του Ιδρύματος"
                   "κάθε όργανο του Ιδρύματος είναι δηλωμένος ρόλος")
 :legal-critical t :policy-level :φραγή
 :tests '("--mirror-gate"))

;;; ── ΤΑΥΤΟΤΗΤΑ ΑΡΘΡΩΝ: θεσμική ικανότητα της νομικής μνήμης ──────────────
;;; Χωρίς δική της πύλη ακόμη (ΔΗΛΩΜΕΝΟ ΧΡΕΟΣ)· το συμβόλαιό της όμως ξέρει
;;; ΜΗΧΑΝΙΚΑ τι παρασύρει μια αλλαγή της — αυτό ελέγχει η πύλη του καθρέφτη.

(orchestrator.self-model:declare-capability! "ταυτότητα-άρθρων"
 :description "η μία ταυτότητα κάθε άρθρου: corpus keying, κανονικοποίηση, ELI/άρθρο URIs, δρομολόγηση ΦΕΚ"
 :package :orchestrator.legal-id
 :functions '("build-article-uri" "registry-by-corpus" "normalize-greek"
              "parse-article-id" "article-id=" "article-id-string")
 :gate nil :depends-on '())   ; ΧΩΡΙΣ ΠΥΛΗ — δηλωμένο χρέος· τα εκτελέσιμα τεστ ζουν στο --component-gate

(orchestrator.contracts:defcontract "article-identity-management" :protocol
 :package :orchestrator.uris :system "orchestrator-infrastructure"
 :capability "ταυτότητα-άρθρων" :role "νομική-μνήμη"   ; Corpus/Legal-Memory Authority — ΟΧΙ utility του συντονιστή
 :purpose "η ΜΙΑ πηγή ταυτότητας άρθρου — κάθε κλειδί corpus, article/ELI URI και υποκείμενο RDF παράγεται από εδώ (πάροχοι: orchestrator.uris build-article-uri, orchestrator.legal-id registry/normalize)"
 :inputs '("corpus-id" "κανονική ταυτότητα άρθρου (αριθμός + επίθημα, πχ 100Α)" "κανονικοποιημένο ελληνικό κείμενο")
 :outputs '("σταθερό κλειδί corpus" "article URI" "ELI URI" "υποκείμενο RDF")
 :preconditions '("η ταυτότητα άρθρου είναι ΚΑΝΟΝΙΚΟΠΟΙΗΜΕΝΗ πριν από κάθε χρήση"
                  "ετικέτες με επίθημα ΔΕΝ καταρρέουν: το 100 και το 100Α μένουν ΔΙΑΚΡΙΤΑ"
                  "τα κλειδιά corpus χρησιμοποιούν την κανονική ταυτότητα, ΟΧΙ τον ωμό αριθμό")
 :postconditions '("μοναδική κανονική ταυτότητα ανά άρθρο"
                   "σταθερό ELI/URI — ίδια είσοδος ⇒ ίδια έξοδος, σε κάθε τρέξιμο"
                   "ΚΑΜΙΑ σιωπηλή αντικατάσταση άρθρου"
                   "συγκρουόμενη διπλή ταυτότητα αποτυγχάνει ΦΩΝΑΧΤΑ, όχι σιωπηλά")
 :legal-critical t :policy-level :ανθρώπινη-έγκριση    ; αλλαγή του μοντέλου ταυτότητας ⇒ έγκριση δημιουργού
 :side-effects '("εγγραφή κλειδιών/URIs στο corpus και στους γράφους RDF")
 :failure-modes '("διπλή ταυτότητα ίδιου άρθρου" "κατάρρευση 100Α σε 100"
                  "σιωπηλή αλλαγή κλειδιών σε υπάρχον corpus")
 :proof-obligations '("τα proof hashes που αναφέρουν άρθρα μένουν επαληθεύσιμα"
                      "αλλαγή κανονικής ταυτότητας ⇒ αλλάζει το proof hash — ποτέ ίδιο hash για άλλη ταυτότητα")
 :audit "κάθε αλλαγή πολιτικής ταυτότητας ⇒ audit event + αναφορά επίπτωσης (--impact) ΠΡΙΝ την εφαρμογή"
 :rollback "αλλαγή πολιτικής ταυτότητας αναστρέψιμη (versioned corpus) — αλλιώς ΜΠΛΟΚΑΡΕΤΑΙ"
 :tests '("--contract-gate" "--subsumption-gate" "--draft-gate")
 :dependents '("υπαγωγή" "παραδοτέο" "πρόσληψη-νομολογίας")
 :impact-tags '(:corpus-storage :corpus-keying :normalized-input :article-uri
                :eli-uri :canonical-uri :rdf-subjects :shacl-validation
                :citation-resolver :proof-hashes :temporal-conclusions
                :regression-gates))

;;; ── ΠΡΟΦΙΛ ΚΕΝΩΝ: τι συμβόλαια απαιτεί μια ικανότητα που ΔΕΝ έχουμε ─────
(orchestrator.contracts:register-gap-profile! "legal-drafting"
 '("pleading-artifact" "sentence-provenance" "claim-defense-structure"
   "court-procedure-model" "adversarial-review-of-draft" "human-approval-of-filing"))
(orchestrator.contracts:register-gap-profile! "σύνταξη-δικογράφων"
 '("pleading-artifact" "sentence-provenance" "claim-defense-structure"
   "court-procedure-model" "adversarial-review-of-draft" "human-approval-of-filing"))

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
    ;; Η θεσμική ταυτότητα + το ισοζύγιο συμβολαίων — από τα μητρώα, τώρα.
    (let ((inst (orchestrator.institution:the-institution)))
      (when inst
        (format t "~%▸ Ίδρυμα: ~A · μηχανή συντονισμού (όργανο): ~A · όργανα: ~{~A~^, ~}~%"
                (orchestrator.institution:institution-name inst)
                (orchestrator.institution:institution-coordination-engine inst)
                (orchestrator.institution:institution-organs inst))))
    (let* ((cov (orchestrator.self-model:contract-coverage))
           (violations (orchestrator.self-model:validate-all-contracts :test-exists-p #'find-command)))
      (format t "~%▸ Συμβόλαια: ~D · πλήρης κάλυψη: ~D ικανότητες~@[ (~{~A~^, ~})~] · μερική: ~{~A~^, ~} · καμία: ~{~A~^, ~}~%"
              (getf cov :contracts)
              (length (getf cov :full)) nil
              (getf cov :partial) (getf cov :none))
      (when (getf cov :uncovered)
        (format t "▸ Συναρτήσεις ΧΩΡΙΣ συμβόλαιο (χρέος, ορατό):~%")
        (dolist (u (getf cov :uncovered))
          (format t "    ~A: ~{~A~^, ~}~%" (car u) (cdr u))))
      (when (getf cov :orphans)
        (format t "▸ ΟΡΦΑΝΑ συμβόλαια (ανύπαρκτη ικανότητα): ~{~A~^, ~}~%" (getf cov :orphans)))
      (if violations
          (progn (format t "▸ ΠΑΡΑΒΑΣΕΙΣ συμβολαίων (~D):~%~{    ✗ ~A~%~}"
                         (length violations) violations))
          (format t "▸ Επικύρωση συμβολαίων: 0 παραβάσεις.~%")))
    ;; Συστατικά — ο καθρέφτης ΚΑΤΑΝΑΛΩΝΕΙ το component registry (πηγή αλήθειας).
    (multiple-value-bind (n e) (orchestrator.component-scan:build-component-registry!)
      (let ((cv (orchestrator.component-scan:validate-components
                 :test-exists-p #'find-command))
            (stale (orchestrator.component-scan:stale-components))
            (orphan-pkgs (remove-if #'orchestrator.components:component-parent
                                    (orchestrator.components:components-of-kind :package))))
        (format t "~%▸ Συστατικά: ~D ταυτότητες (~D συστήματα, ~D αρχεία με SHA-256, ~D πακέτα, ~D κρίσιμα σύμβολα) · ~D ακμές~%"
                n
                (length (orchestrator.components:components-of-kind :system))
                (length (orchestrator.components:components-of-kind :file))
                (length (orchestrator.components:components-of-kind :package))
                (length (orchestrator.components:components-of-kind :symbol))
                e)
        (when orphan-pkgs
          (format t "▸ ΟΡΦΑΝΑ πακέτα (χωρίς αρχείο-έδρα): ~{~A~^, ~}~%"
                  (mapcar #'orchestrator.components:component-name orphan-pkgs)))
        (when stale
          (format t "▸ ΞΕΠΕΡΑΣΜΕΝΑ hashes: ~{~A~^, ~}~%"
                  (mapcar #'orchestrator.components:component-id stale)))
        (if cv
            (format t "▸ ΠΑΡΑΒΑΣΕΙΣ ταυτοποίησης (~D):~%~{    ✗ ~A~%~}" (length cv) cv)
            (format t "▸ Ταυτοποίηση συστατικών: 0 παραβάσεις.~%"))))
    ;; Προέλευση εκτέλεσης — καταναλωτής του orchestrator.trace/provenance.
    (multiple-value-bind (traced via debts silent)
        (orchestrator.exec-provenance:trace-coverage)
      (format t "~%▸ Προέλευση εκτέλεσης: προφίλ ~(~A~) · ~D ίχνη στη συνεδρία · τελευταίο συμπέρασμα: ~:[κανένα~;ίχνος #~:*~D~]~%"
              orchestrator.trace:*trace-profile*
              (orchestrator.trace:event-count)
              (orchestrator.trace:last-conclusion-id))
      (format t "▸ Ενοργάνωση legal-critical: ~D άμεσα · ~D μέσω γονικού span · ~D ρητά χρέη~@[ · ΣΙΩΠΗΛΑ: ~{~A~^, ~} ⚠~]~%"
              (length traced) (length via) (length debts)
              silent)
      (let ((pv (orchestrator.exec-provenance:validate-provenance)))
        (if pv (format t "▸ ΠΑΡΑΒΑΣΕΙΣ προέλευσης (~D):~%~{    ✗ ~A~%~}" (length pv) pv)
            (format t "▸ Επικύρωση προέλευσης: 0 παραβάσεις στο ζωντανό ρεύμα.~%"))))
    ;; Ελεγχόμενη αυτοεξέλιξη — καταναλωτής των orchestrator.whatif/adoption.
    (let ((props (orchestrator.whatif:all-proposals))
          (recs (orchestrator.adoption:adoption-records))
          (lv (orchestrator.adoption:validate-adoption-records)))
      (format t "~%▸ Αυτοεξέλιξη: ~D δηλωμένες προτάσεις αλλαγής · ~D υπογεγραμμένες αποφάσεις · ledger: ~:[~D παραβάσεις ⚠~;καθαρό~]~%"
              (length props) (length recs) (null lv) (length lv)))
    0))

(defun run-institution ()
  "--institution : η θεσμική αυτο-δήλωση — από το συμβόλαιο ταυτότητας, όχι από πρόζα."
  (let ((inst (orchestrator.institution:the-institution))
        (idc (orchestrator.contracts:find-contract "institutional-identity")))
    (cond
      ((null inst) (format t "ΔΕΝ έχει δηλωθεί Ίδρυμα — αυτό είναι σφάλμα.~%") 1)
      (t
       (format t "~%══ ~A ══~%~A~%" (orchestrator.institution:institution-name inst)
               (orchestrator.institution:institution-description inst))
       (when idc
         (format t "~%«~A»~%" (orchestrator.contracts:contract-purpose idc)))
       (format t "~%Όργανα/αίθουσες:~%")
       (dolist (r (orchestrator.institution:all-roles))
         (format t "  • ~A~:[~; ← μηχανή συντονισμού~] — ~A (~D συμβόλαια)~%"
                 (orchestrator.institution:role-name r)
                 (string= (orchestrator.institution:role-name r)
                          (orchestrator.institution:institution-coordination-engine inst))
                 (orchestrator.institution:role-description r)
                 (length (orchestrator.contracts:contracts-for-role
                          (orchestrator.institution:role-name r)))))
       0))))

(defun %print-contract (c)
  (format t "~%── ΣΥΜΒΟΛΑΙΟ «~A» (~(~A~)) ──~%" (orchestrator.contracts:contract-name c)
          (orchestrator.contracts:contract-kind c))
  (loop for (label val)
          in (list (list "έδρα" (format nil "~(~A~) · ~A"
                                        (orchestrator.contracts:contract-package c)
                                        (or (orchestrator.contracts:contract-system c) "—")))
                   (list "ικανότητα" (orchestrator.contracts:contract-capability c))
                   (list "θεσμικός ρόλος" (orchestrator.contracts:contract-role c))
                   (list "σκοπός" (orchestrator.contracts:contract-purpose c))
                   (list "είσοδοι" (orchestrator.contracts:contract-inputs c))
                   (list "έξοδοι" (orchestrator.contracts:contract-outputs c))
                   (list "προϋποθέσεις" (orchestrator.contracts:contract-preconditions c))
                   (list "μετασυνθήκες" (orchestrator.contracts:contract-postconditions c))
                   (list "παρενέργειες" (or (orchestrator.contracts:contract-side-effects c) "ΚΑΘΑΡΗ"))
                   (list "legal-critical" (if (orchestrator.contracts:contract-legal-critical c) "ΝΑΙ" "όχι"))
                   (list "επίπεδο πολιτικής" (orchestrator.contracts:contract-policy-level c))
                   (list "τρόποι αστοχίας" (orchestrator.contracts:contract-failure-modes c))
                   (list "συνθήκες/σφάλματα" (orchestrator.contracts:contract-conditions c))
                   (list "υποχρεώσεις απόδειξης" (orchestrator.contracts:contract-proof-obligations c))
                   (list "audit/provenance" (orchestrator.contracts:contract-audit c))
                   (list "τεστ απόδειξης" (orchestrator.contracts:contract-tests c))
                   (list "κατάντη εξαρτώμενοι" (orchestrator.contracts:contract-dependents c))
                   (list "ετικέτες επίπτωσης" (orchestrator.contracts:contract-impact-tags c)))
        when val
          do (format t "  ~A: ~A~%" label
                     (if (consp val) (format nil "~{~A~^ · ~}" val) val))))

(defun run-contract (args)
  "--contract <συνάρτηση|ικανότητα> : το πλήρες συμβόλαιο — ή όλα τα συμβόλαια
   της ικανότητας. Ντετερμινιστική, δομημένη έξοδος."
  (let ((name (format nil "~{~A~^ ~}" args)))
    (cond
      ((zerop (length name)) (format t "χρήση: --contract <όνομα>~%") 1)
      ((orchestrator.contracts:find-contract name)
       (%print-contract (orchestrator.contracts:find-contract name)) 0)
      ((orchestrator.self-model:find-capability name)
       (let ((cs (orchestrator.contracts:contracts-for-capability name)))
         (if cs (progn (mapc #'%print-contract cs) 0)
             (progn (format t "Η ικανότητα «~A» ΔΕΝ έχει κανένα συμβόλαιο — χρέος.~%" name) 1))))
      (t (format t "Κανένα συμβόλαιο ή ικανότητα «~A».~%" name) 1))))

(defun run-contracts-missing ()
  "--contracts-missing : το τίμιο έλλειμμα — τι ΔΕΝ έχει ακόμη συμβόλαιο."
  (let ((cov (orchestrator.self-model:contract-coverage)))
    (format t "~%── ΕΛΛΕΙΜΜΑ ΣΥΜΒΟΛΑΙΩΝ ──~%")
    (if (getf cov :uncovered)
        (dolist (u (getf cov :uncovered))
          (format t "  ~A: ~{~A~^, ~}~%" (car u) (cdr u)))
        (format t "  Καμία ακάλυπτη κρίσιμη συνάρτηση.~%"))
    (when (getf cov :orphans)
      (format t "  Ορφανά συμβόλαια: ~{~A~^, ~}~%" (getf cov :orphans)))
    0))

(defun run-capability-contracts (args)
  "--capability-contracts <ικανότητα> : τα συμβόλαια που τη στηρίζουν."
  (run-contract args))

(defun run-impact (args)
  "--impact <ικανότητα|συμβόλαιο> : η αιτιώδης επίπτωση — ποιες ικανότητες
   κληρονομούν τον κίνδυνο (depends-on ∪ contract dependents) και ποιες πύλες
   είναι το ελάχιστο regression. Για συμβόλαιο: μέσω της ικανότητάς του,
   συν οι ετικέτες επίπτωσής του."
  (let* ((name (format nil "~{~A~^ ~}" args))
         (contract (orchestrator.contracts:find-contract name))
         (cap-name (if contract (orchestrator.contracts:contract-capability contract) name)))
    (cond
      ((zerop (length name)) (format t "χρήση: --impact <όνομα>~%") 1)
      ((and (null contract) (null (orchestrator.self-model:find-capability name)))
       (format t "Ούτε ικανότητα ούτε συμβόλαιο «~A» — τίμια άγνοια.~%" name) 1)
      (t
       (when contract
         (format t "~%Συμβόλαιο «~A» → ικανότητα «~A»~%" name cap-name)
         (when (orchestrator.contracts:contract-impact-tags contract)
           (format t "Ετικέτες επίπτωσης: ~{~(~A~)~^ · ~}~%"
                   (orchestrator.contracts:contract-impact-tags contract))))
       (multiple-value-bind (caps gates)
           (orchestrator.self-model:capability-impact cap-name)
         (format t "~%Αν αλλάξει «~A», κληρονομούν τον κίνδυνο (~D):~%~{  • ~A~%~}"
                 cap-name (length caps)
                 (mapcar #'orchestrator.self-model:capability-name caps))
         (format t "Ελάχιστο regression — πύλες που ΠΡΕΠΕΙ να τρέξουν: ~{~A~^, ~}~%"
                 gates))
       ;; Και σε επίπεδο ΣΥΣΤΑΤΙΚΩΝ (καταναλωτής του component registry):
       ;; πάροχοι της ρίζας με τα αρχεία-πηγές τους, συμβόλαιά της, τεστ.
       (let ((cap (orchestrator.self-model:find-capability cap-name)))
         (when cap
           (format t "~%Συστατικά της ρίζας «~A»:~%" cap-name)
           (dolist (f (orchestrator.self-model:capability-functions cap))
             (multiple-value-bind (sym src)
                 (orchestrator.component-scan:resolve-critical-symbol
                  f (orchestrator.self-model:capability-package cap))
               (declare (ignore sym))
               (format t "  • ~A — ~:[ΑΧΑΡΤΟΓΡΑΦΗΤΟ~;~:*~A~]~%"
                       f (and src (enough-namestring src (uiop:getcwd))))))
           (let ((cs (orchestrator.contracts:contracts-for-capability cap-name)))
             (when cs
               (format t "  Συμβόλαια: ~{~A~^ · ~}~%"
                       (mapcar #'orchestrator.contracts:contract-name cs))
               (format t "  Τεστ: ~{~A~^ · ~}~%"
                       (remove-duplicates
                        (mapcan (lambda (c) (copy-list (orchestrator.contracts:contract-tests c))) cs)
                        :test #'string=))))))
       0))))

(defun %contract-field (args field label)
  "Μία δομημένη όψη ενός πεδίου συμβολαίου — ντετερμινιστική έξοδος."
  (let* ((name (format nil "~{~A~^ ~}" args))
         (c (or (orchestrator.contracts:find-contract name)
                (first (orchestrator.contracts:contracts-for-capability name)))))
    (if (null c)
        (progn (format t "Κανένα συμβόλαιο «~A».~%" name) 1)
        (let ((val (funcall field c)))
          (format t "~A «~A»: ~A~%" label (orchestrator.contracts:contract-name c)
                  (cond ((null val) "—")
                        ((consp val) (format nil "~{~A~^ · ~}" val))
                        (t val)))
          0))))

(register-command "--institution" (lambda (a) (declare (ignore a)) (run-institution)))
(register-command "--ίδρυμα"      (lambda (a) (declare (ignore a)) (run-institution)))
(register-command "--contract"    (lambda (a) (run-contract a)))
(register-command "--συμβόλαιο"   (lambda (a) (run-contract a)))
(register-command "--contracts-missing" (lambda (a) (declare (ignore a)) (run-contracts-missing)))
(register-command "--capability-contracts" (lambda (a) (run-capability-contracts a)))
(register-command "--impact"      (lambda (a) (run-impact a)))
(register-command "--providers"
  (lambda (a) (let ((cs (orchestrator.contracts:contracts-for-capability
                         (format nil "~{~A~^ ~}" a))))
                (if cs (progn (format t "Πάροχοι της «~{~A~^ ~}»: ~{~A~^ · ~}~%"
                                      a (mapcar #'orchestrator.contracts:contract-name cs)) 0)
                    (%contract-field a #'orchestrator.contracts:contract-package "Έδρα-πάροχος")))))
(register-command "--tests"
  (lambda (a) (%contract-field a #'orchestrator.contracts:contract-tests "Τεστ απόδειξης")))
(register-command "--policy"
  (lambda (a) (%contract-field a (lambda (c)
                                   (format nil "~@[legal-critical · ~*~]~(~A~)"
                                           (orchestrator.contracts:contract-legal-critical c)
                                           (or (orchestrator.contracts:contract-policy-level c) "—")))
                               "Πολιτική")))

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
                                    '("ομοιότητα-υποθέσεων" "πρόσληψη-νομολογίας"
                                      "ταυτότητα-άρθρων")
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
