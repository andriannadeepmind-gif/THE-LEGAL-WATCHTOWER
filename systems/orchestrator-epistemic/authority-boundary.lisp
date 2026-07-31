;;;; systems/orchestrator-epistemic/authority-boundary.lisp
;;;; ============================================================================
;;;; LEVEL-7 VCCT-RSM — Η ΓΡΑΜΜΗ CANDIDATE/AUTHORITY (μία έδρα κατάργησης)
;;;; ============================================================================
;;;; ΓΙΑΤΙ ΥΠΑΡΧΕΙ: κατ' εντολή δημιουργού (FV-CCT-RSM), ολόκληρο το υπάρχον
;;;; Common Lisp σύστημα γίνεται ΑΠΟΚΛΕΙΣΤΙΚΑ μη-έμπιστος παραγωγός immutable
;;;; candidate bundles. Καμία υπάρχουσα διαδρομή (deploy, emit, ingestion,
;;;; blockchain, promote-latest!) ΔΕΝ επιτρέπεται πλέον να γράψει authoritative
;;;; release, log ή latest. Η ΜΟΝΗ authority ζει στη νέα authority-v2 process
;;;; (orchestrator-authority-v2) πίσω από OS-enforced write capability.
;;;;
;;;; ΑΥΤΟ ΤΟ ΑΡΧΕΙΟ είναι η ΜΙΑ έδρα όπου η κατάργηση των παλιών authority seats
;;;; γίνεται ΔΟΜΙΚΗ, όχι σχόλιο: κάθε παλιά έδρα σηματοδοτεί
;;;; LEGACY-AUTHORITY-SEAT-REMOVED αντί να γράφει. Δεν υπάρχει fallback,
;;;; δεν υπάρχει «ισχυρότερη» έκδοση της παλιάς — υπάρχει ΑΡΝΗΣΗ.
;;;;
;;;; assurance_status = under-construction (branch claude/lawmax-level7-vcct-rsm).

(in-package :orchestrator.epistemic)

(define-condition legacy-authority-seat-removed (error)
  ((seat :initarg :seat :reader legacy-authority-seat-removed-seat)
   (detail :initarg :detail :initform nil :reader legacy-authority-seat-removed-detail))
  (:report
   (lambda (c stream)
     (format stream
             "LEVEL-7 VCCT-RSM: η παλιά authority έδρα ~A ΚΑΤΑΡΓΗΘΗΚΕ. ~
              Το legacy σύστημα είναι μη-έμπιστος παραγωγός candidate bundles· ~
              καμία authoritative εγγραφή (release/log/latest) δεν γίνεται από ~
              εδώ. Χρησιμοποίησε τη νέα authority-v2 process (admission kernel + ~
              OS write capability).~@[ ~A~]"
             (legacy-authority-seat-removed-seat c)
             (legacy-authority-seat-removed-detail c)))))

(defun %seat-removed (seat &optional detail)
  "Σηματοδοτεί την ΚΑΤΑΡΓΗΣΗ μιας παλιάς authority έδρας — fail-closed, ΠΑΝΤΑ."
  (error 'legacy-authority-seat-removed :seat seat :detail detail))

;;; ── CANDIDATE BOUNDARY ──
;;; Ο παραγωγός γράφει ΜΟΝΟ candidate bundles: immutable, content-addressed,
;;; σε namespace ΞΕΧΩΡΙΣΤΟ από το authority store. Δεν προάγει τίποτα σε
;;; authority — αυτό είναι δουλειά ΜΟΝΟ του admission kernel της authority-v2.
;;;
;;; ΤΙΜΙΟ ΟΡΙΟ: εδώ δηλώνεται η πρόθεση+δομή· ο OS-enforced διαχωρισμός
;;; (producer identity ⇒ EACCES στο authority store) επιβάλλεται από το
;;; authority-v2/capability/identities.sh και αποδεικνύεται στα tests. Ο
;;; παραγωγός ΔΕΝ έχει καν όνομα-συνάρτησης για authority write — δεν υπάρχει.

(defvar *candidate-namespace* "candidates/"
  "Υπο-κατάλογος (σχετικός στο base) όπου ο παραγωγός γράφει candidate bundles.
   ΠΟΤΕ authority. Το authority store είναι ΤΕΛΕΙΩΣ αλλού (authority-v2 process).")

(defun emit-candidate-bundle! (base-output-dir release-id
                               &key (source-commit nil) (candidate-root nil))
  "Γράφει δείκτη candidate-bundle για το RELEASE-ID στο
   candidate namespace. Επιστρέφει το path του δείκτη. ΔΕΝ προάγει authority,
   ΔΕΝ γράφει latest/log — αυτά είναι αποκλειστικά της authority-v2 process.

   ΠΡΟΣΟΧΗ — ΤΟ candidates/ ΔΕΝ είναι immutable: ο producer είναι ΙΔΙΟΚΤΗΤΗΣ του
   και μπορεί να το αλλάξει ανά πάσα στιγμή (ενεργός αντίπαλος, TOCTOU). Ο μόνος
   αμετάβλητος είναι ο ΣΥΛΛΗΦΘΕΙΣ snapshot μέσα στο authority quarantine — βλ.
   authority-v2/capture/CAPTURE-PROTOCOL.sexp.

   Ο δείκτης είναι evidence-only: λέει «ο παραγωγός ΠΡΟΤΕΙΝΕΙ αυτό το bundle
   ως candidate». Η αποδοχή (ή απόρριψη) κρίνεται από τον admission kernel."
  (let* ((base (uiop:ensure-directory-pathname base-output-dir))
         (cand-dir (merge-pathnames *candidate-namespace* base))
         (marker (merge-pathnames (format nil "~A.candidate.json" release-id) cand-dir)))
    (ensure-directories-exist cand-dir)
    ;; Producer-owned (ΟΧΙ immutable): αν υπάρχει ήδη, ΔΕΝ ξαναγράφεται (content-addressed ⇒ ίδιο).
    (unless (probe-file marker)
      (with-open-file (o marker :direction :output :if-exists :error
                                :if-does-not-exist :create)
        (write-string
         (jonathan:to-json
          (list :|kind| "lawmax/candidate-bundle/1"
                :|release_id| release-id
                :|source_commit| (or source-commit :null)
                :|candidate_root| (or candidate-root :null)
                :|authority| :false
                :|note| "candidate-only: authority αποφασίζεται από τον admission kernel")
          :from :plist)
         o)
        (terpri o)))
    marker))
