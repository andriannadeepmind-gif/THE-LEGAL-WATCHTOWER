;;;; systems/orchestrator-cli/self-extension.lisp
;;;; ============================================================================
;;;; Σ11 — ΑΥΤΟ-ΕΠΕΚΤΑΣΗ ΜΕ ΠΥΛΕΣ: ο βρόχος βελτίωσης γίνεται ιδιότητα του συστήματος
;;;; ============================================================================
;;;;
;;;; Το σύστημα διαβάζει τα ΚΑΤΑΓΕΓΡΑΜΜΕΝΑ κενά του (lessons: αγείωτες έννοιες)
;;;; και ΣΥΝΘΕΤΕΙ ΜΟΝΟ ΤΟΥ υποψήφια τεχνήματα γνώσης — εδώ: γειώσεις εννοιών σε
;;;; διατάξεις, βρίσκοντας ΤΟ ίδιο το άρθρο-υποψήφιο μέσα στο corpus (μνείες με
;;;; προτεραιότητα ΤΙΤΛΟΥ). ΔΗΛΩΜΕΝΟ ΟΡΙΟ (η ασφάλεια του meta): συνθέτει ΜΟΝΟ
;;;; δηλωτική γνώση (πακέτα), ποτέ κώδικα στο έμπιστο μονοπάτι. Κάθε τέχνημα:
;;;;   1. επικυρώνεται συντακτικά (load-pack — ποτέ μισογραμμένη γνώση),
;;;;   2. δοκιμάζεται ΣΚΙΩΔΩΣ (with-packs-overlay: εγκατάσταση→επαναφορά,
;;;;      καμία μόλυνση της ενεργής γνώσης),
;;;;   3. κατατίθεται ως ΠΡΟΤΑΣΗ (:self-extension) — η υιοθέτηση είναι ΠΑΝΤΑ
;;;;      πράξη του δημιουργού (--approve), που γράφει το πακέτο στη γνώση και
;;;;      το καταγράφει στη βιογραφία με πλήρη προέλευση «αυτο-προτάθηκε από
;;;;      το κενό Χ».
;;;; Ο κύκλος proposals/packs/gates ΥΠΗΡΧΕ — εδώ απλώς κλείνει ο βρόχος.

(in-package :orchestrator.cli)

(defun %self-extension-payload (p)
  (let ((*read-eval* nil))
    (read-from-string (orchestrator.proposals:proposal-payload p))))

(defun %assert-safe-pack-filename (name)
  "ΦΡΑΓΜΟΣ ΟΡΙΟΥ ΕΜΠΙΣΤΟΣΥΝΗΣ: όνομα πακέτου γνώσης = ΜΟΝΟ απλό basename
   με κατάληξη .sexp — ποτέ απόλυτη διαδρομή, ποτέ ../ (path traversal),
   ώστε υιοθέτηση πρότασης να μην μπορεί να γράψει ΕΞΩ από τον κατάλογο
   γνώσης ακόμη κι αν το payload είναι εχθρικό (εξωτερική επιθεώρηση 05-07-2026)."
  (unless (and (stringp name)
               (> (length name) 5)
               (string= ".sexp" name :start2 (- (length name) 5))
               (string= name (file-namestring name))
               (not (find #\/ name)) (not (find #\\ name))
               (not (search ".." name)) (not (find #\: name)))
    (error "Μη ασφαλές όνομα πακέτου γνώσης: ~S — απαιτείται απλό όνομα *.sexp χωρίς διαδρομή" name))
  name)

(orchestrator.proposals:register-proposal-kind :self-extension
 :on-approve
 (lambda (p)
   (let* ((pl (%self-extension-payload p))
          ;; ένα αρχείο (:filename/:pack-text) ή πολλά (:files ((fn text)…))
          (files (or (getf pl :files)
                     (list (list (getf pl :filename) (getf pl :pack-text))))))
     ;; γράψε ατομικά, φόρτωσε ζωντανά, κατέγραψε στη βιογραφία — με προέλευση
     (dolist (f files)
       (orchestrator.journal:write-file-atomic
        (merge-pathnames (%assert-safe-pack-filename (first f))
                         orchestrator.knowledge-packs:*knowledge-dir*)
        (second f)))
     (orchestrator.knowledge-packs:ensure-fresh)
     (orchestrator.self-history:record!
      :self-extension-adopted
      (format nil "Υιοθέτησα αυτο-προταθείσα γνώση «~{~A~^ + ~}» (κενό: ~A) — σκιωδώς δοκιμασμένη, εγκεκριμένη από τον δημιουργό."
              (mapcar #'first files) (getf pl :gap)))))
 :describe
 (lambda (p)
   (let ((pl (%self-extension-payload p)))
     (format nil "ΑΥΤΟ-ΕΠΕΚΤΑΣΗ: ~A — από το κενό «~A»"
             (or (getf pl :filename) (mapcar #'first (getf pl :files)))
             (getf pl :gap)))))

(defun %compose-grounding-pack (concept lemmas tag corpus article heading)
  "Σύνθεσε κείμενο πακέτου :concept-grounding για την ΕΝΝΟΙΑ — πάνω στο ΔΙΚΟ του
   σχήμα γνώσης (MOP-γνωστό), όχι αυθαίρετο κείμενο."
  (with-output-to-string (s)
    (let ((*print-pretty* nil))
      (format s "(:knowledge-pack :concept-grounding 1~%")
      (format s " ;; ΑΥΤΟ-ΠΡΟΤΑΘΗΚΕ από καταγεγραμμένο κενό γνώσης· υποψήφια γείωση:~%")
      (format s " ;; το άρθρο ~A ~A (~S) φέρει την έννοια στον ΤΙΤΛΟ του.~%" article tag heading)
      (format s " (:concept ~S (~S) :grounds ~S ~S))~%"
              concept lemmas corpus article))))

(defun propose-groundings (gaps)
  "Για κάθε αγείωτη έννοια των GAPS ((label)…): βρες υποψήφιο άρθρο-έδρα
   (μνεία με προτεραιότητα ΤΙΤΛΟΥ σε όλους τους κώδικες), σύνθεσε πακέτο,
   ΕΠΙΚΥΡΩΣΕ (load-pack σε προσωρινό αρχείο), δοκίμασε ΣΚΙΩΔΩΣ, κατάθεσε
   πρόταση. Επιστρέφει πλήθος προτάσεων."
  (let ((n 0) (seen '()))
    (dolist (gap gaps n)
      (let* ((label (string gap))
             (lemmas (remove-if-not #'orchestrator.citation-authority:content-lemma-p
                                    (%q-lemmas label))))
        (when (and lemmas (not (member label seen :test #'string=)))
          (push label seen)
          ;; ψάξε άρθρο με την έννοια ΣΤΟΝ ΤΙΤΛΟ σε όλους τους κώδικες
          (let ((best nil))
            (let ((cseen '()))
              (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
                (let ((corpus (cdr entry)) (tag (car entry)))
                  (unless (member corpus cseen :test #'string=)
                    (push corpus cseen)
                    (unless best
                      (multiple-value-bind (hits) (%corpus-mentions corpus lemmas :limit 1)
                        (let ((h (first hits)))
                          (when (and h (third h))   ; μόνο τίτλος = «είναι ΓΙ' αυτό»
                            (setf best (list tag corpus (first h) (second h)))))))))))
            (when best
              (destructuring-bind (tag corpus num heading) best
                (let ((text (%compose-grounding-pack label lemmas tag corpus num heading))
                      (tmp (merge-pathnames
                            (format nil "selfext-~D.sexp" (get-universal-time))
                            (uiop:temporary-directory))))
                  ;; 1. συντακτική επικύρωση + 2. σκιώδης δοκιμή — ΠΡΙΝ την πρόταση
                  (orchestrator.journal:write-file-atomic tmp text)
                  (when (handler-case
                            (progn (orchestrator.knowledge-packs:load-pack tmp)
                                   (orchestrator.knowledge-packs:with-packs-overlay
                                    (list tmp) (lambda () t)))
                          (error () nil))
                    ;; 3. πρόταση — η υιοθέτηση ανήκει στον δημιουργό
                    (when (orchestrator.proposals:propose!
                           :sig (format nil "self-extension grounding ~A" label)
                           :kind :self-extension
                           :why (format nil "αυτο-επέκταση: γείωση της αγείωτης έννοιας «~A» στο άρθρο ~A ~A"
                                        label num tag)
                           :payload (prin1-to-string
                                     (list :filename (format nil "self-grounding-~A.sexp"
                                                             (subseq (orchestrator.journal:sha256-hex label) 0 8))
                                           :pack-text text :gap label)))
                      (incf n)))
                  (ignore-errors (delete-file tmp)))))))))))

(defun %ungrounded-gaps (rows)
  "Τα κενά γείωσης από τις σειρές (count kind subject) των lessons. Το kind
   είναι STRING (έτσι γράφεται στο jsonl από το %lesson) — η σύγκριση εδώ
   είναι το ΕΝΑ σημείο που το ξέρει."
  (loop for (count kind subject) in rows
        when (and (equal kind "concept-ungrounded") (plusp count))
          collect subject))

(defun %compose-taxonomy-pack (term source sentence tuples)
  "Πακέτο :taxonomy από αφομοιωμένη ΟΡΙΣΤΙΚΗ διατύπωση — με πηγή και το
   ίδιο το εδάφιο ως σχόλιο προέλευσης."
  (with-output-to-string (s)
    (let ((*print-pretty* nil))
      (format s "(:knowledge-pack :taxonomy 1~%")
      (format s " ;; ΑΥΤΟ-ΠΡΟΤΑΘΗΚΕ: αφομοίωση οριστικής διατύπωσης — ~A (όρος «~A»)~%"
              source term)
      (format s " ;; ~A~%" (substitute #\Space #\~ sentence))
      (dolist (tu tuples)
        (format s " ~S~%" tu))
      (format s ")~%"))))

(defun propose-assimilations (term defs)
  "ΑΦΟΜΟΙΩΣΗ: για κάθε (ΠΗΓΗ ΠΡΟΤΑΣΗ) των DEFS, η οριστική πρόταση
   αναλύεται συντακτικά (parse-definition) σε υποψήφια (:γένος …), το πακέτο
   επικυρώνεται συντακτικά ΚΑΙ περνά ΟΛΟΚΛΗΡΗ την πύλη υπαγωγής ΣΚΙΩΔΩΣ
   (με τη νέα ταξινομία εγκατεστημένη προσωρινά — καμία παλινδρόμηση), και
   κατατίθεται ως πρόταση. Η υιοθέτηση μένει ΠΑΝΤΑ στον δημιουργό."
  (let ((n 0))
    (dolist (d defs n)
      (destructuring-bind (source sentence) d
        (let ((tuples (orchestrator.casegrammar:parse-definition sentence term)))
          (when tuples
            (let ((text (%compose-taxonomy-pack term source sentence tuples))
                  (tmp (merge-pathnames
                        (format nil "assim-~D.sexp" (get-universal-time))
                        (uiop:temporary-directory))))
              (orchestrator.journal:write-file-atomic tmp text)
              (when (handler-case
                        (progn
                          (orchestrator.knowledge-packs:load-pack tmp)
                          (orchestrator.knowledge-packs:with-packs-overlay
                           (list tmp)
                           (lambda ()
                             ;; ΠΛΗΡΗΣ σκιώδης παλινδρόμηση: όλη η πύλη
                             ;; υπαγωγής πρέπει να μείνει πράσινη ΜΕ το νέο γένος
                             (zerop (let ((*standard-output* (make-broadcast-stream)))
                                      (run-subsumption-gate))))))
                      (error () nil))
                (when (orchestrator.proposals:propose!
                       :sig (format nil "self-extension taxonomy ~A ~A" term source)
                       :kind :self-extension
                       :why (format nil "αφομοίωση ορισμού από ~A:~{ ~A ⊂ ~A~^ ·~}"
                                    source
                                    (loop for tu in tuples
                                          append (list (second tu) (third tu))))
                       :payload (prin1-to-string
                                 (list :filename
                                       (format nil "self-taxonomy-~A.sexp"
                                               (subseq (orchestrator.journal:sha256-hex
                                                        (format nil "~A~A" term source)) 0 8))
                                       :pack-text text :gap term)))
                  (incf n)))
              (ignore-errors (delete-file tmp)))))))))

(defun %compose-norm-pack (id source heading spec)
  "Πακέτο :tatbestand από ΑΝΑΓΝΩΣΜΕΝΗ διάταξη — πηγή, τίτλος, και τα
   δηλωμένα όρια της ανάγνωσης ως σχόλια προέλευσης."
  (with-output-to-string (s)
    (let ((*print-pretty* nil))
      (format s "(:knowledge-pack :tatbestand 1~%")
      (format s " ;; ΑΥΤΟ-ΠΡΟΤΑΘΗΚΕ: ανάγνωση της διάταξης ~A (~A)~%" source (or heading "χωρίς τίτλο"))
      (dolist (c (getf spec :caveats))
        (format s " ;; ΠΡΟΣΟΧΗ: ~A~%" c))
      (format s " (:norm ~S ~S ~S :penal~%  ~S~%  ~S~%  ())~%)~%"
              id (getf spec :modality) source
              (getf spec :antecedent) (getf spec :consequent)))))

(defun propose-norm-from-provision (corpus article)
  "Σ12α: διάβασε τη διάταξη corpus:article με τη γραμματική του νομοθέτη.
   Αν ΥΠΑΡΧΕΙ κανόνας ίδιας πηγής ⇒ ΕΠΑΛΗΘΕΥΣΗ (συμφωνεί η μηχανή με το
   χέρι;) — ποτέ διπλότυπο. Αλλιώς: σύνθεση κανόνα, ΟΛΟΚΛΗΡΗ η πύλη
   υπαγωγής σκιωδώς, πρόταση προς έγκριση. (values 1|0 λόγος)."
  (let ((entry (let ((tbl (%article-table corpus)))
                 (and tbl (gethash article tbl)))))
    (when (null entry)
      (return-from propose-norm-from-provision
        (values 0 (format nil "δεν βρίσκω το άρθρο ~A στον ~A" article corpus))))
    (multiple-value-bind (spec why)
        (orchestrator.casegrammar:parse-provision (first entry)
                                                  :heading (second entry))
      (when (null spec)
        (return-from propose-norm-from-provision (values 0 why)))
      (let* ((source (format nil "~A:~A" corpus article))
             (existing (find source (orchestrator.deontic:all-norms)
                             :key #'orchestrator.deontic:norm-source
                             :test #'string=)))
        (when existing
          ;; ΕΠΑΛΗΘΕΥΣΗ: υπογραφή προϋποθέσεων = (κατηγόρημα τιμή|:?), ταξινομημένη
          (flet ((sig (facts)
                   (sort (mapcar (lambda (f)
                                   (format nil "~A ~A" (third f)
                                           (if (keywordp (fourth f)) (fourth f) :?)))
                                 facts)
                         #'string<)))
            (let* ((mine (sig (orchestrator.subsumption::%devar (getf spec :antecedent))))
                   (his (sig (orchestrator.deontic:norm-antecedent existing)))
                   (agree (equal mine his))
                   (dfs (length (orchestrator.deontic:norm-defeaters existing))))
              (return-from propose-norm-from-provision
                (values 0
                        (concatenate 'string
                          (format nil "ΕΠΑΛΗΘΕΥΣΗ κατά ~A: η ανάγνωσή μου ~:[ΔΙΑΦΩΝΕΙ (~{~A~^, ~} ≠ ~{~A~^, ~})~;ΣΥΜΦΩΝΕΙ πλήρως στην ειδική υπόσταση~2*~]"
                                  (orchestrator.deontic:norm-id existing)
                                  agree mine his)
                          (if (plusp dfs)
                              (format nil " · ο εγγεγραμμένος φέρει ~D λόγο(υς) άρσης που η α΄ ανάγνωση δεν διαβάζει — δηλωμένο όριο" dfs)
                              "")))))))
        ;; ΝΕΑ πηγή: σύνθεση, σκιώδης πλήρης πύλη, πρόταση
        (let* ((id (intern (string-upcase (format nil "norm-~A-~A-αυτο" corpus article))
                           :keyword))
               (pack (%compose-norm-pack id source (second entry) spec))
               (tmp (merge-pathnames
                     (format nil "readnorm-~D.sexp" (get-universal-time))
                     (uiop:temporary-directory))))
          (orchestrator.journal:write-file-atomic tmp pack)
          (unwind-protect
               (if (handler-case
                       (progn
                         (orchestrator.knowledge-packs:load-pack tmp)
                         (orchestrator.knowledge-packs:with-packs-overlay
                          (list tmp)
                          (lambda ()
                            (zerop (let ((*standard-output* (make-broadcast-stream)))
                                     (run-subsumption-gate))))))
                     (error () nil))
                   (if (orchestrator.proposals:propose!
                        :sig (format nil "self-extension norm ~A" source)
                        :kind :self-extension
                        :why (format nil "ΑΝΑΓΝΩΣΗ ΔΙΑΤΑΞΗΣ ~A «~A»: ~D προϋποθέσεις, τροπικότητα ~A~{ · ~A~}"
                                     source (or (second entry) "")
                                     (length (getf spec :antecedent))
                                     (getf spec :modality) (getf spec :caveats))
                        :payload (prin1-to-string
                                  (list :filename (format nil "self-norm-~A-~A.sexp"
                                                          corpus article)
                                        :pack-text pack :gap source)))
                       (values 1 nil)
                       (values 0 "ήδη κατατεθειμένη (καταστολή κατά sig)"))
                   (values 0 "ο κανόνας ΔΕΝ πέρασε τη σκιώδη πύλη υπαγωγής — απορρίφθηκε"))
            (ignore-errors (delete-file tmp))))))))

(defun run-read-provision (args)
  "--read-provision <corpus> <άρθρο> : ανάγνωση διάταξης σε ΚΑΝΟΝΑ (Σ12α)."
  (let ((corpus (first args)) (article (second args)))
    (if (or (null corpus) (null article))
        (progn (format t "χρήση: --read-provision poinikos 372~%") 1)
        (progn
          (orchestrator.knowledge-packs:ensure-fresh)
          (multiple-value-bind (n why) (propose-norm-from-provision corpus article)
            (if (plusp n)
                (progn (format t "~%✦ Διάβασα το ~A:~A και κατέθεσα ΚΑΝΟΝΑ προς έγκριση (--thoughts / --approve).~%"
                               corpus article) 0)
                (progn (format t "~%✗ ~A:~A — ~A~%" corpus article why) 1)))))))

(register-command "--read-provision" (lambda (a) (run-read-provision a)))

(defun study-code (corpus &key (propose t))
  "ΑΥΤΟΚΑΤΕΥΘΥΝΟΜΕΝΗ ΜΕΛΕΤΗ: διάβασε ΟΛΕΣ τις διατάξεις του CORPUS με τη
   γραμματική του νομοθέτη. Επιστρέφει plist μετρήσεων: πόσα άρθρα διάβασε,
   πόσους κανόνες επαλήθευσε/πρότεινε/απέρριψε η σκιά, πόσα ΔΕΝ διαβάζονται
   και ΓΙΑΤΙ — και ποια ρήματα, με σειρά συχνότητας, θα ξεκλείδωναν τα
   περισσότερα: η μηχανή ΛΕΕΙ ΜΟΝΗ ΤΗΣ τι πρέπει να μάθει.
   PROPOSE nil ⇒ ξηρή ανάλυση (χωρίς σκιώδεις πύλες/προτάσεις) — για δοκιμές."
  (let ((table (%article-table corpus))
        (read- 0) (verified 0) (disagree 0) (proposed 0) (rejected 0)
        (unreadable 0) (reasons (make-hash-table :test 'equal))
        (verbs (make-hash-table :test 'equal)))
    (when table
      (maphash
       (lambda (num entry)
         (incf read-)
         (multiple-value-bind (spec why candidate)
             (orchestrator.casegrammar:parse-provision (first entry)
                                                       :heading (second entry))
           (cond
             ((null spec)
              (incf unreadable)
              (incf (gethash (subseq why 0 (min 34 (length why))) reasons 0))
              (when candidate (incf (gethash candidate verbs 0))))
             (propose
              (multiple-value-bind (n vwhy) (propose-norm-from-provision corpus num)
                (cond ((plusp n) (incf proposed))
                      ((and vwhy (search "ΣΥΜΦΩΝΕΙ" vwhy)) (incf verified))
                      ((and vwhy (search "ΔΙΑΦΩΝΕΙ" vwhy)) (incf disagree))
                      (t (incf rejected)))))
             (t (incf proposed)))))   ; ξηρή ανάλυση: μετρά ως αναγνώσιμο
       table))
    (let ((missing '()) (rs '()))
      (maphash (lambda (k v) (push (cons k v) missing)) verbs)
      (maphash (lambda (k v) (push (cons k v) rs)) reasons)
      (list :corpus corpus :read read- :verified verified :disagree disagree
            :proposed proposed :rejected rejected :unreadable unreadable
            :reasons (sort rs #'> :key #'cdr)
            :missing-verbs (sort missing #'> :key #'cdr)))))

(defvar *study-cache* (make-hash-table :test 'equal)
  "corpus → (write-date . stats): η ξηρή αυτομελέτη είναι φθηνή σε κάθε
   κύκλο αναστοχασμού — ξανατρέχει ΜΟΝΟ όταν αλλάξει το corpus.jsonl.")

(defun %study-cached (corpus)
  "Η ξηρή αυτομελέτη του CORPUS, με cache κατά write-date του corpus.jsonl."
  (let* ((path (merge-pathnames (format nil "output/~A/corpus.jsonl" (%corpus-outdir corpus))
                                (uiop:getcwd)))
         (fwd (and (probe-file path) (file-write-date path)))
         (hit (gethash corpus *study-cache*)))
    (cond ((null fwd) nil)
          ((and hit (eql (car hit) fwd)) (cdr hit))
          (t (let ((st (study-code corpus :propose nil)))
               (setf (gethash corpus *study-cache*) (cons fwd st))
               st)))))

;;; Η ΒΟΥΛΗΣΗ ΣΤΟ ΣΥΝΤΑΓΜΑ: η αυτομόρφωση είναι ΑΠΟΣΤΟΛΗ με μετρητή —
;;; το «πού βρίσκεσαι στην αποστολή σου» απαντά και για το διάβασμα του νόμου.
(orchestrator.self:register-mission-measure
 :self-study
 (lambda ()
   (let ((st (%study-cached "poinikos")))
     (if (null st)
         (values "κανένα εκδομένο corpus προς μελέτη ακόμη" nil)
         (let* ((read- (getf st :read))
                (readable (getf st :proposed))
                (top (first (getf st :missing-verbs))))
           (values (format nil "διαβάζω ~D/~D διατάξεις ΠΚ (~D%)~@[ · κορυφαίο κενό γραμματικής: «~A» (θα ξεκλείδωνε ~D άρθρα)~]"
                           readable read-
                           (if (plusp read-) (round (* 100 readable) read-) 0)
                           (car top) (cdr top))
                   (and (plusp read-) (= readable read-))))))))

(defun dream-grammar (&optional gaps)
  "Σ13α — Ο ΟΝΕΙΡΕΥΤΗΣ ΚΑΙ Ο ΔΙΚΑΣΤΗΣ: για κάθε κενό γραμματικής της ΒΟΥΛΗΣΗΣ
   (ρηματικός τύπος + πόσα άρθρα ξεκλειδώνει), ο σύμβουλος (εκτός εμπιστοσύνης)
   ονειρεύεται το ΚΑΛΟΥΠΙ (:dream λήμμα/κατηγόρημα/μορφές)· ο πυρήνας το
   δικάζει: σχήμα → η μαρτυρία των κειμένων εξηγείται → ΟΛΟΚΛΗΡΗ η πύλη
   υπαγωγής σκιωδώς → πρόταση. Η υιοθέτηση ΠΑΝΤΑ του δημιουργού. Χωρίς
   συνδεδεμένο σύμβουλο ο βρόχος αδρανεί — δηλωμένα. Επιστρέφει πλήθος."
  (unless orchestrator.cognition:*advisor*
    (return-from dream-grammar 0))
  (let ((gaps (or gaps
                  (let ((st (%study-cached "poinikos")))
                    (and st (subseq (getf st :missing-verbs) 0
                                    (min 3 (length (getf st :missing-verbs))))))))
        (n 0))
    (dolist (g gaps n)
      (destructuring-bind (vform . count) g
        (let ((dream (orchestrator.cognition:advise
                      :dream-verb
                      (format nil "Ρηματικός τύπος: «~A» (σε ~D διατάξεις μετά το «όποιος»)"
                              vform count))))
          (when dream
            (multiple-value-bind (lemma pred forms) (validate-dream vform dream)
              (when lemma
                (let* ((vf-pack (with-output-to-string (o)
                                  (let ((*print-pretty* nil))
                                    (format o "(:knowledge-pack :verb-frames 1~%")
                                    (format o " ;; ΟΝΕΙΡΟ ΣΥΜΒΟΥΛΟΥ, ΔΙΚΑΣΜΕΝΟ: ο τύπος «~A» μαρτυρείται στα κείμενα~%" vform)
                                    (format o " (:frame ~S ~S))~%" lemma pred))))
                       (lx-pack (with-output-to-string (o)
                                  (let ((*print-pretty* nil))
                                    (format o "(:knowledge-pack :lexicon 1~%")
                                    (format o " (:lemma ~S (~{~S~^ ~})))~%" lemma forms))))
                       (h (subseq (orchestrator.journal:sha256-hex lemma) 0 8))
                       (tmp1 (merge-pathnames (format nil "dreamvf-~A.sexp" h)
                                              (uiop:temporary-directory)))
                       (tmp2 (merge-pathnames (format nil "dreamlx-~A.sexp" h)
                                              (uiop:temporary-directory))))
                  (orchestrator.journal:write-file-atomic tmp1 vf-pack)
                  (orchestrator.journal:write-file-atomic tmp2 lx-pack)
                  (unwind-protect
                       (when (handler-case
                                 (progn
                                   (orchestrator.knowledge-packs:load-pack tmp1)
                                   (orchestrator.knowledge-packs:load-pack tmp2)
                                   (orchestrator.knowledge-packs:with-packs-overlay
                                    (list tmp1 tmp2)
                                    (lambda ()
                                      (let ((rc (let ((*standard-output* (make-broadcast-stream)))
                                                  (run-subsumption-gate))))
                                        ;; ΤΙΜΙΑ ΑΠΟΡΡΙΨΗ, ποτέ σιωπηλή: ο λόγος φαίνεται
                                        (unless (zerop rc)
                                          (format t "  ⚠ όνειρο «~A»: η σκιώδης πύλη υπαγωγής ΑΠΕΤΥΧΕ (rc ~D) — απορρίπτεται~%"
                                                  lemma rc))
                                        (zerop rc)))))
                               (error (e)
                                 (format t "  ⚠ όνειρο «~A»: σφάλμα στη σκιώδη δίκη — ~A~%" lemma e)
                                 nil))
                         (let ((id (orchestrator.proposals:propose!
                                :sig (format nil "self-extension dream ~A" lemma)
                                :kind :self-extension
                                :why (format nil "ΟΝΕΙΡΟ→ΔΙΚΗ: πλαίσιο «~A»→~A (~D μορφές, μαρτυρία «~A», ξεκλειδώνει ~D άρθρα)"
                                             lemma pred (length forms) vform count)
                                :payload (prin1-to-string
                                          (list :files
                                                (list (list (format nil "self-dream-frame-~A.sexp" h) vf-pack)
                                                      (list (format nil "self-dream-lemma-~A.sexp" h) lx-pack))
                                                :gap vform :class :dream-frame)))))
                           (when id
                             (incf n)
                             ;; ΕΝΤΟΣ ΠΟΛΙΤΙΚΗΣ (αν ο δημιουργός την έχει δώσει
                             ;; με μετρημένη ακρίβεια): αυτο-υιοθέτηση — αλλιώς
                             ;; η πρόταση περιμένει το χέρι του
                             (ignore-errors (%maybe-auto-approve id :dream-frame)))))
                    (ignore-errors (delete-file tmp1))
                    (ignore-errors (delete-file tmp2))))))))))))

(defun run-study-code (args)
  "--study-code <corpus> : η μηχανή μελετά ΟΛΟΚΛΗΡΟ τον κώδικα μόνη της και
   αναφέρει τι έμαθε, τι πρότεινε, και τι γραμματική τής λείπει — μετρημένα."
  (let ((corpus (or (first args) "poinikos")))
    (orchestrator.knowledge-packs:ensure-fresh)
    (let ((st (study-code corpus)))
      (format t "~%══ ΑΥΤΟΜΕΛΕΤΗ ~A: ~D διατάξεις ══~%" corpus (getf st :read))
      (format t "  ΕΠΑΛΗΘΕΥΣΑ κανόνες του δημιουργού: ~D · ΔΙΑΦΩΝΩ: ~D~%"
              (getf st :verified) (getf st :disagree))
      (format t "  ΠΡΟΤΕΙΝΑ νέους κανόνες: ~D · απέρριψε η σκιώδης πύλη: ~D~%"
              (getf st :proposed) (getf st :rejected))
      (format t "  ΔΕΝ διαβάζονται (ακόμη): ~D — οι λόγοι:~%" (getf st :unreadable))
      (loop for (r . c) in (getf st :reasons) repeat 4
            do (format t "    ~4D× ~A…~%" c r))
      (let ((mv (getf st :missing-verbs)))
        (when mv
          (format t "  ΤΙ ΠΡΕΠΕΙ ΝΑ ΜΑΘΩ ΠΡΩΤΑ (ρήματα κατά αξία ξεκλειδώματος):~%")
          (loop for (v . c) in mv repeat 10
                do (format t "    ~3D άρθρα ⇐ «~A»~%" c v)
                   (%lesson :grammar-gap v (format nil "θα ξεκλείδωνε ~D άρθρα του ~A" c corpus)))
          (format t "  (καταγράφηκαν ως κενά γραμματικής — δίδαξέ μου τα με μία γραμμή :frame το καθένα)~%")))
      0)))

(register-command "--study-code" (lambda (a) (run-study-code a)))

(defun run-evolve (&key quiet)
  "--evolve : ΕΝΑΣ ΚΥΚΛΟΣ ΑΥΤΟΕΞΕΛΙΞΗΣ, ντετερμινιστικός και μετρημένος:
   μελέτη → προτάσεις (γειώσεις + όνειρα-καλούπια) → αυτο-υιοθέτηση ΜΟΝΟ
   εντός πολιτικών που έδωσε ο δημιουργός → επαναμέτρηση → η ΔΙΑΦΟΡΑ στη
   βιογραφία. Τρέχει και ΑΥΤΟΝΟΜΑ σε κάθε κύκλο του δαίμονα."
  (orchestrator.knowledge-packs:ensure-fresh)
  (let* ((before (study-code "poinikos" :propose nil))
         (b-read (getf before :proposed))
         (gaps (%ungrounded-gaps (%lessons-aggregate)))
         (n (+ (propose-groundings gaps) (dream-grammar))))
    ;; επαναμέτρηση ΜΕΤΑ από τυχόν αυτο-υιοθετήσεις (νέα γραμματική ⇒ νέα κάλυψη)
    (remhash "poinikos" *study-cache*)
    (let* ((after (study-code "poinikos" :propose nil))
           (a-read (getf after :proposed)))
      (when (> a-read b-read)
        (orchestrator.self-history:record!
         :evolution
         (format nil "Αυτοεξελίχθηκα εντός πολιτικών: διάβαζα ~D/~D διατάξεις ΠΚ, τώρα ~D — μέσω ονείρου→δίκης→πολιτικής, με πλήρη προέλευση."
                 b-read (getf before :read) a-read)))
      (unless quiet
        (format t "~%══ ΚΥΚΛΟΣ ΕΞΕΛΙΞΗΣ ══~%")
        (format t "  προτάσεις που κατέθεσα: ~D~%" n)
        (format t "  ανάγνωση ΠΚ: ~D → ~D (από ~D διατάξεις)~%"
                b-read a-read (getf after :read))
        (format t "  (αυτο-υιοθέτηση ΜΟΝΟ εντός πολιτικών: --policies · τα υπόλοιπα: --thoughts/--approve)~%"))
      0)))

(register-command "--evolve" (lambda (a) (declare (ignore a)) (run-evolve)))

(defun run-self-extend ()
  "--self-extend : διάβασε τα καταγεγραμμένα κενά (lessons :concept-ungrounded),
   σύνθεσε υποψήφιες γειώσεις, δοκίμασέ τες σκιωδώς, κατάθεσέ τες προς έγκριση."
  (let* ((gaps (%ungrounded-gaps (%lessons-aggregate)))
         (n (+ (propose-groundings gaps) (dream-grammar))))
    (format t "~%── ΑΥΤΟ-ΕΠΕΚΤΑΣΗ: ~D κενά εξετάστηκαν · ~D προτάσεις κατατέθηκαν ──~%"
            (length gaps) n)
    (when (plusp n)
      (format t "  Έλεγχος: --thoughts · υιοθέτηση: --approve <id> (γράφει το πακέτο στη γνώση)~%"))
    0))

(defun run-extension-gate ()
  "--extension-gate : η πύλη της αυτο-επέκτασης — προσωρινά ημερολόγια/γνώση."
  (let* ((tmp-prop (merge-pathnames (format nil "extgate-~D.sexp" (get-universal-time))
                                    (uiop:temporary-directory)))
         (tmp-kdir (merge-pathnames (format nil "extgate-know-~D/" (get-universal-time))
                                    (uiop:temporary-directory)))
         (orchestrator.proposals:*proposals-path* tmp-prop)
         (orchestrator.knowledge-packs:*knowledge-dir* tmp-kdir)
         (fails '()) (total 0))
    (ensure-directories-exist tmp-kdir)
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΑΥΤΟ-ΕΠΕΚΤΑΣΗΣ (Σ11) ──~%")
      ;; 0 — ΦΡΑΓΜΟΣ ΟΡΙΟΥ: εχθρικά ονόματα πακέτων δεν γράφουν ΠΟΤΕ εκτός
      ;;     του καταλόγου γνώσης (εξωτερική επιθεώρηση 05-07-2026, κλειδωμένο)
      (check "εχθρικό όνομα «../evil.sexp» ⇒ απορρίπτεται"
             (null (ignore-errors (%assert-safe-pack-filename "../evil.sexp"))))
      (check "εχθρικό όνομα «/tmp/evil.sexp» ⇒ απορρίπτεται"
             (null (ignore-errors (%assert-safe-pack-filename "/tmp/evil.sexp"))))
      (check "εχθρικό όνομα «a/b.sexp» ⇒ απορρίπτεται"
             (null (ignore-errors (%assert-safe-pack-filename "a/b.sexp"))))
      (check "λάθος κατάληξη «evil.lisp» ⇒ απορρίπτεται"
             (null (ignore-errors (%assert-safe-pack-filename "evil.lisp"))))
      (check "νόμιμο όνομα «kalo-pack.sexp» ⇒ δεκτό"
             (equal "kalo-pack.sexp" (ignore-errors (%assert-safe-pack-filename "kalo-pack.sexp"))))
      ;; 1 — από κενό σε ΕΓΚΥΡΗ πρόταση (η «έφεση» έχει άρθρο-τίτλο στο corpus)
      (let ((n (propose-groundings '("έφεση"))))
        (check "κενό «έφεση» ⇒ 1 αυτο-πρόταση (συντακτικά έγκυρη, σκιωδώς δοκιμασμένη)"
               (= n 1)))
      ;; 2 — ίδιο κενό δεν επανακατατίθεται (καταστολή κατά sig)
      (check "ίδιο κενό ⇒ καμία δεύτερη πρόταση" (zerop (propose-groundings '("έφεση"))))
      ;; 3 — άγνωστη/ανύπαρκτη έννοια ⇒ ΚΑΜΙΑ πρόταση (δεν εφευρίσκει)
      (check "ανύπαρκτη έννοια ⇒ καμία πρόταση — δεν εφευρίσκω γείωση"
             (zerop (propose-groundings '("ζζζζζζ"))))
      ;; 4 — το ΦΙΛΤΡΟ των κενών δουλεύει πάνω στην ΠΡΑΓΜΑΤΙΚΗ μορφή των lessons
      ;;     (kind = string στο jsonl — το σφάλμα eq/keyword ήταν πραγματικό εύρημα)
      (check "φίλτρο κενών: (2 \"concept-ungrounded\" έφεση)+(1 \"needs-ocr\" x) ⇒ μόνο η έφεση"
             (equal '("έφεση")
                    (%ungrounded-gaps '((2 "concept-ungrounded" "έφεση")
                                        (1 "needs-ocr" "x.pdf")))))
      ;; 5 — η έγκριση ΓΡΑΦΕΙ το πακέτο στη γνώση (προσωρινός κατάλογος) και φορτώνει
      (let ((p (first (orchestrator.proposals:open-proposals))))
        (multiple-value-bind (q status) (orchestrator.proposals:approve!
                                         (orchestrator.proposals:proposal-id p))
          (declare (ignore q))
          (check "έγκριση ⇒ το πακέτο ΓΡΑΦΕΤΑΙ και φορτώνεται ζωντανά"
                 (and (eq status :approved)
                      (probe-file (merge-pathnames
                                   (getf (%self-extension-payload p) :filename)
                                   tmp-kdir)))))))
      ;; ── ΑΦΟΜΟΙΩΣΗ: ανάγνωση → γένος → σκιώδης πύλη → έγκριση → ΣΥΛΛΟΓΙΣΜΟΣ ──
    (flet ((check (label ok)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (let* ((sent "Ιδιωτικά έγγραφα θεωρούνται και τα βιβλία που τηρούν οι έμποροι")
             (tuples (orchestrator.casegrammar:parse-definition sent "βιβλίο")))
        (check "ανάγνωση ορισμού ⇒ ΓΕΝΟΣ ΜΕ ΔΙΑΦΟΡΑ (:γένος-όταν … τηρείται-από έμπορος) + δεσμός κεφαλής"
               (and (= 2 (length tuples))
                    (eq :γένος-όταν (first (first tuples)))
                    (= 5 (length (first tuples)))
                    (eq :γένος (first (second tuples)))))
        (check "αφομοίωση: η πρόταση κατατίθεται ΜΟΝΟ αφού περάσει ΟΛΟΚΛΗΡΗ τη σκιώδη πύλη υπαγωγής"
               (= 1 (propose-assimilations "βιβλίο" (list (list "ΚΠολΔ 444" sent)))))
        (let ((p (first (orchestrator.proposals:open-proposals))))
          (orchestrator.proposals:approve! (orchestrator.proposals:proposal-id p))
          (multiple-value-bind (engine)
              (orchestrator.subsumption:subsume
               '((:γεγονός :τεφτέρι :είναι :βιβλίο)
                 (:γεγονός :τεφτέρι :τηρείται-από :έμπορος)))
            (check "ΜΕ τη διαφορά (τηρείται από έμπορο): τεφτέρι ⇒ έγγραφο (Barbara ×2 υπό όρο)"
                   (plusp (length (orchestrator.inference:query
                                   engine '(:γεγονός :τεφτέρι :είναι :έγγραφο))))))
          (multiple-value-bind (engine)
              (orchestrator.subsumption:subsume '((:γεγονός :τεφτέρι :είναι :βιβλίο)))
            (check "ΧΩΡΙΣ τη διαφορά: ΔΕΝ γενικεύει — το εύρος του νόμου, όχι ευρύτερο"
                   (zerop (length (orchestrator.inference:query
                                   engine '(:γεγονός :τεφτέρι :είναι :έγγραφο)))))))))
    ;; ── Σ12α: Η ΜΗΧΑΝΗ ΔΙΑΒΑΖΕΙ ΤΟ ΙΔΙΟ ΤΟ ΠΚ 372 ΚΑΙ ΚΡΙΝΕΤΑΙ ΠΑΝΩ ΤΟΥ ──
    (flet ((check (label ok)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (let ((entry (let ((tbl (%article-table "poinikos"))) (and tbl (gethash "372" tbl)))))
        (multiple-value-bind (spec why)
            (orchestrator.casegrammar:parse-provision (first entry) :heading (second entry))
          (declare (ignore why))
          (check "ανάγνωση του ΠΡΑΓΜΑΤΙΚΟΥ ΠΚ 372: «όποιος…τιμωρείται» ⇒ 4 προϋποθέσεις + πράξη ΚΛΟΠΗ"
                 (and spec
                      (= 4 (length (getf spec :antecedent)))
                      (eq :prohibition (getf spec :modality))
                      (eq :κλοπή (getf spec :act))))))
      (multiple-value-bind (n why) (propose-norm-from-provision "poinikos" "372")
        (check "ΕΠΑΛΗΘΕΥΣΗ κατά τον χειροποίητο κανόνα: η μηχανή ΣΥΜΦΩΝΕΙ στην ειδική υπόσταση, δηλώνει το όριο των λόγων άρσης"
               (and (zerop n) why
                    (search "ΣΥΜΦΩΝΕΙ" why)
                    (search "άρσης" why)))))
    ;; ── ΑΥΤΟΜΕΛΕΤΗ (ξηρή): η μηχανή μετρά ΜΟΝΗ της τι τής λείπει ──
    (flet ((check (label ok)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (let ((st (study-code "poinikos" :propose nil)))
        (check "αυτομελέτη ΠΚ: σαρώνει ΟΛΕΣ τις διατάξεις και μετρά αναγνώσιμες/μη"
               (and (> (getf st :read) 300)
                    (plusp (getf st :proposed))
                    (plusp (getf st :unreadable))))
        (check "η μηχανή ΟΝΟΜΑΖΕΙ τα ρήματα που πρέπει να μάθει, κατά αξία ξεκλειδώματος"
               (let ((mv (getf st :missing-verbs)))
                 (and mv (>= (cdr (first mv)) (cdr (first (last mv)))))))))
    ;; ── Η ΒΟΥΛΗΣΗ ΔΙΠΛΑ ΣΤΟ ΕΓΩ: σύνταγμα → μετρητής → αναστοχασμός ──
    (flet ((check (label ok)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (check "η αυτομόρφωση είναι ΑΠΟΣΤΟΛΗ του συντάγματος, μετρημένη ζωντανά (Χ/529 + κορυφαίο κενό)"
             (let ((m (find-if (lambda (m) (search "διαβάζω μόνος μου" (first m)))
                               (orchestrator.self:mission-status))))
               (and m (search "διατάξεις" (second m))
                    (search "κενό γραμματικής" (second m)))))
      (check "η ΒΟΥΛΗΣΗ είναι παρατηρητής του αναστοχασμού: ζητά κοστολογημένα τα ρήματα που της λείπουν"
             (let ((fs (%observe-will)))
               (and fs (search "ΒΟΥΛΗΣΗ" (getf (first fs) :why))
                    (search "άρθρα" (getf (first fs) :why))))))
    (ignore-errors (delete-file tmp-prop))
    (ignore-errors (uiop:delete-directory-tree tmp-kdir :validate t))
    (format t "~%── ΠΥΛΗ ΑΥΤΟ-ΕΠΕΚΤΑΣΗΣ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--self-extend"    (lambda (a) (declare (ignore a)) (run-self-extend)))
(register-command "--extension-gate" (lambda (a) (declare (ignore a)) (run-extension-gate)))

(orchestrator.self-model:declare-capability! "πακέτα-γνώσης"
 :description "δηλωτική γνώση με SHA-256, hot reload και σκιώδη εκτέλεση"
 :package :orchestrator.knowledge-packs :functions '("ensure-fresh" "with-packs-overlay")
 :gate "--extension-gate" :depends-on '())
(orchestrator.self-model:declare-capability! "αυτοεπέκταση"
 :description "κενά → αυτο-προτάσεις γνώσης, σκιωδώς δοκιμασμένες, υιοθέτηση μόνο με έγκριση + rollback"
 :package :orchestrator.cli :functions '("run-self-extend" "run-evolve" "dream-grammar")
 :gate "--extension-gate" :depends-on '("πακέτα-γνώσης" "υπαγωγή"))

;;; ── ΣΥΜΒΟΛΑΙΑ ΠΑΡΟΧΩΝ (δεσμευτική αυτοπεριγραφή — βλ. --contract-gate) ──

(orchestrator.contracts:defcontract "knowledge-pack-lifecycle" :protocol
 :package :orchestrator.knowledge-packs :system "orchestrator-infrastructure"
 :capability "πακέτα-γνώσης" :role "νομική-μνήμη"
 :purpose "δηλωτική γνώση με SHA-256 (ensure-fresh, with-packs-overlay): εγκατάσταση ατομική, σκιά χωρίς μόλυνση"
 :side-effects '("εγκατάσταση/αναφόρτωση πακέτων γνώσης")
 :postconditions '("αποτυχία εγκατάστασης ⇒ πλήρης επαναφορά snapshot — ποτέ μισή γνώση")
 :legal-critical t :policy-level :φραγή
 :audit "SHA-256 κάθε πακέτου στη βιογραφία — ποιο ακριβώς κείμενο γνώσης ισχύει"
 :rollback "snapshot→install→restore-on-error: εγγενής αναστρεψιμότητα"
 :tests '("--extension-gate"))

(orchestrator.contracts:defcontract "self-extension-adoption" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "αυτοεπέκταση" :role "αυτοεξέλιξη"
 :purpose "κενά → υποψήφια γνώση → ΣΚΙΩΔΗΣ δοκιμή → υιοθέτηση ΜΟΝΟ με έγκριση (run-self-extend, run-evolve, dream-grammar)"
 :side-effects '("υιοθέτηση γνώσης στο ζωντανό σύστημα")
 :preconditions '("μηδέν παλινδρομήσεις στη σκιά — αλλιώς η υποψηφιότητα απορρίπτεται")
 :postconditions '("καμία υιοθέτηση χωρίς ανθρώπινη έγκριση ή μετρημένη πολιτική κλάσης")
 :legal-critical t :policy-level :ανθρώπινη-έγκριση
 :audit "κάθε υιοθέτηση γράφεται στη βιογραφία με SHA + αποτέλεσμα σκιάς"
 :rollback "κάθε υιοθέτηση αναστρέψιμη μέσω του ledger της βιογραφίας"
 :tests '("--extension-gate" "--policy-gate"))
