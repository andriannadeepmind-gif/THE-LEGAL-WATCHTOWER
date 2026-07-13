;;;; systems/orchestrator-cli/golden-gate.lisp
;;;; ============================================================================
;;;; ΠΥΛΗ ΧΡΥΣΩΝ ΑΠΟΤΥΠΩΜΑΤΩΝ: --golden-gate — regression ratchet, ΤΙΠΟΤΑ άλλο
;;;; ============================================================================
;;;; Εγκρίθηκε από τον δημιουργό ΜΟΝΟ ως «μικρό προστατευτικό ratchet»:
;;;; τα 6/6 golden identical να μην είναι audit artifact αλλά ΣΤΑΘΕΡΗ πύλη
;;;; μη-παλινδρόμησης μέσα στην ολομέλεια (--gates).
;;;;
;;;; ΤΙ ΔΕΝ ΚΑΝΕΙ (δεσμεύσεις εντολής):
;;;;   · ΔΕΝ γράφει/«διορθώνει» κανένα golden (κανένα GOLDEN_WRITE μονοπάτι εδώ)
;;;;   · ΔΕΝ ξαναγράφει outputs (ούτε καν το output manifest — read-only)
;;;;   · ΔΕΝ αλλάζει συμπεριφορά καμίας άλλης εντολής
;;;;   · ΔΕΝ είναι νέο subsystem — καταναλώνει ΤΙΣ ΙΔΙΕΣ έδρες:
;;;;     orchestrator.fingerprint (η μία υλοποίηση αποτυπώματος/diff) +
;;;;     build-consolidated-for + %fingerprint-method (verify-corpus seat).
;;;;
;;;; ΚΑΝΟΝΙΚΟΣ ΤΡΟΠΟΣ ΣΥΓΚΡΙΣΗΣ (like-with-like — daaf7a74):
;;;;   το ΙΔΙΟ το golden ορίζει τη μέθοδο από το σχήμα του
;;;;   (:num/:original|:amended ⇒ semantic · :file-id/:emitted ⇒ emitted)
;;;;   και το τρέχον αποτύπωμα υπολογίζεται με ΤΗΝ ΙΔΙΑ μέθοδο.
;;;; ΝΤΕΤΕΡΜΙΝΙΣΜΟΣ: καμία εξάρτηση από ρολόι/δίκτυο/τυχαιότητα — μόνο
;;;;   committed πηγές + committed goldens· επιπλέον ρητός έλεγχος ⑤:
;;;;   διπλός υπολογισμός ⇒ ταυτόσημη ρίζα.
;;;; ΑΝ ΕΜΦΑΝΙΣΤΕΙ DIFF: η πύλη ΚΟΚΚΙΝΙΖΕΙ (⇒ και η ολομέλεια) και τυπώνει
;;;;   το ονομαστικό diff. Η ΜΟΝΗ νόμιμη διόρθωση είναι συνειδητή πράξη
;;;;   δημιουργού: είτε διόρθωση της πηγής, είτε ρητό επανακλείδωμα με
;;;;   GOLDEN_WRITE=1 στο --verify-corpus + commit. Η πύλη ΠΟΤΕ δεν «διορθώνει».

(in-package :orchestrator.cli)

(defun %golden-current-manifest (short doc method)
  "Το ΤΡΕΧΟΝ αποτύπωμα του SHORT με τη ΖΗΤΟΥΜΕΝΗ μέθοδο — read-only,
   τίποτα δεν γράφεται πουθενά."
  (let ((fp (find-package :orchestrator.fingerprint)))
    (ecase method
      (:semantic (funcall (find-symbol "CORPUS-FINGERPRINT" fp) doc))
      (:emitted  (funcall (find-symbol "OUTPUT-MANIFEST" fp)
                          (corpus-output-dir
                           (or (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR") (orchestrator.paths:institution-dir "output/")))
                          :id short)))))

(defun run-golden-gate ()
  "--golden-gate : κάθε committed golden ≡ φρέσκο ίδιας-μεθόδου αποτύπωμα.
   Regression guard ΜΟΝΟ: read-only, κανένα golden δεν γράφεται ποτέ από εδώ."
  (let* ((fp (find-package :orchestrator.fingerprint))
         (total 0) (fails '())
         ;; snapshot ΠΡΙΝ από κάθε υπολογισμό: όλα τα golden αρχεία + write-dates
         (golden-files (ignore-errors
                        (directory (merge-pathnames
                                    "*.fingerprint.sexp"
                                    (uiop:ensure-directory-pathname
                                     (or (uiop:getenv "GOLDEN_DIR")
                                         (merge-pathnames "deployment/verify/golden/"
                                                          (or (uiop:getenv "ORCHESTRATOR_ROOT")
                                                              (orchestrator.paths:institution-root)))))))))
         (golden-dates-before (mapcar (lambda (p) (cons (namestring p) (file-write-date p)))
                                      golden-files)))
    (flet ((chk (label ok &optional detail)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails)
                        (format t "  ✗ ~A~@[~%      → ~A~]~%" label detail)))))
      (format t "~%── ΠΥΛΗ ΧΡΥΣΩΝ ΑΠΟΤΥΠΩΜΑΤΩΝ (read-only ratchet) ──~%")
      (dolist (id *served-corpora*)
        (handler-case
            (multiple-value-bind (short doc) (build-consolidated-for id)
              (let ((gpath (%corpus-golden-file short)))
                (if (not (probe-file gpath))
                    (chk (format nil "~A: golden υπάρχει" short) nil
                         (format nil "ΛΕΙΠΕΙ: ~A — κάθε κώδικας οφείλει κλειδωμένο golden" gpath))
                    (let* ((golden (funcall (find-symbol "READ-FINGERPRINT-MANIFEST" fp)
                                            gpath))
                           (method (%fingerprint-method golden))
                           (cur (%golden-current-manifest short doc method))
                           (diff (funcall (find-symbol "FINGERPRINT-DIFF" fp) golden cur))
                           (clean (funcall (find-symbol "DIFF-CLEAN-P" fp) diff)))
                      (chk (format nil "~A: golden ≡ τρέχον (~(~A~), ~A άρθρα, ρίζα ~A…)"
                                   short method
                                   (funcall (find-symbol "MANIFEST-COUNT" fp) golden)
                                   (let ((r (funcall (find-symbol "MANIFEST-ROOT" fp) golden)))
                                     (subseq r 0 (min 12 (length r)))))
                           clean
                           (unless clean
                             (format nil "DRIFT — ~A~%      διόρθωση ΜΟΝΟ συνειδητά: πηγή ή GOLDEN_WRITE=1 + commit (η πύλη δεν γράφει)"
                                     (funcall (find-symbol "FORMAT-DIFF" fp) diff))))))))
          (error (e) (chk (format nil "~A: έλεγχος εκτελέστηκε" id) nil
                          (princ-to-string e)))))
      ;; ⑤ ΝΤΕΤΕΡΜΙΝΙΣΜΟΣ: ο ίδιος υπολογισμός δύο φορές ⇒ byte-ίδια ρίζα.
      (handler-case
          (multiple-value-bind (short doc) (build-consolidated-for "syntagma")
            (declare (ignore short))
            (let ((r1 (funcall (find-symbol "MANIFEST-ROOT" fp)
                               (funcall (find-symbol "CORPUS-FINGERPRINT" fp) doc)))
                  (r2 (funcall (find-symbol "MANIFEST-ROOT" fp)
                               (funcall (find-symbol "CORPUS-FINGERPRINT" fp) doc))))
              (chk "ντετερμινισμός: διπλός υπολογισμός ⇒ ταυτόσημη ρίζα"
                   (equal r1 r2) (format nil "~A ≠ ~A" r1 r2))))
        (error (e) (chk "ντετερμινισμός: έλεγχος εκτελέστηκε" nil (princ-to-string e))))
      ;; ⑥ READ-ONLY ΑΠΟΔΕΙΞΗ: κανένα golden δεν άλλαξε από την ΑΡΧΗ της πύλης
      ;; (snapshot πριν από κάθε υπολογισμό) μέχρι το τέλος της.
      (let ((after (mapcar (lambda (p) (cons (namestring p)
                                             (ignore-errors (file-write-date p))))
                           golden-files)))
        (chk (format nil "read-only: κανένα από τα ~D golden δεν αγγίχτηκε από την πύλη"
                     (length golden-files))
             (and (plusp (length golden-files))
                  (equal golden-dates-before after))))
      (format t "~%── ΠΥΛΗ ΧΡΥΣΩΝ ΑΠΟΤΥΠΩΜΑΤΩΝ: ~D/~D πέρασαν ──~%"
              (- total (length fails)) total)
      (if fails 1 0))))

(register-command "--golden-gate"
  (lambda (a) (declare (ignore a)) (run-golden-gate)))

(orchestrator.self-model:declare-capability! "χρυσή-περιφρούρηση"
 :description "regression ratchet: κάθε committed golden αποτύπωμα ταυτίζεται με φρέσκο ίδιας-μεθόδου υπολογισμό — drift δεν περνά την ολομέλεια· read-only, ποτέ δεν γράφει golden"
 :package :orchestrator.cli
 :functions '("run-golden-gate" "%golden-current-manifest")
 :gate "--golden-gate"
 :depends-on '("συστατικά"))

(orchestrator.contracts:defcontract "golden-regression-guard" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "χρυσή-περιφρούρηση" :role "νομική-μνήμη"
 :purpose "τα κλειδωμένα αποτυπώματα των 6 κωδίκων είναι πύλη μη-παλινδρόμησης, όχι audit artifact — drift = κόκκινη ολομέλεια, διόρθωση ΜΟΝΟ με συνειδητή πράξη δημιουργού"
 :inputs '("deployment/verify/golden/*.fingerprint.sexp (committed)" "consolidated corpora / output article-*.hash")
 :outputs '("ετυμηγορία ανά κώδικα + ονομαστικό diff σε drift")
 :preconditions '("η μέθοδος σύγκρισης ορίζεται από το ΣΧΗΜΑ του golden (like-with-like)")
 :postconditions '("golden drift ⇒ πύλη κόκκινη ⇒ ολομέλεια κόκκινη"
                   "η πύλη δεν έγραψε κανένα golden και κανένα output")
 :side-effects '("καμία — read-only πύλη")
 :legal-critical nil :policy-level :συμβουλευτικό
 :audit "κάθε κώδικας ονομαστικά με μέθοδο/πλήθος/ρίζα· ρητός έλεγχος ντετερμινισμού και read-only"
 :rollback "revert του commit εισαγωγής — καμία κατάσταση δεν αφήνεται πίσω"
 :tests '("--golden-gate"))
