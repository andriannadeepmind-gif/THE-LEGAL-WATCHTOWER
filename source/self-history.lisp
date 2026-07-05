;;;; source/self-history.lisp
;;;; ============================================================================
;;;; Η ΒΙΟΓΡΑΦΙΑ ΤΟΥ ΣΥΣΤΗΜΑΤΟΣ — append-only αλυσίδα, όχι αφήγηση
;;;; ============================================================================
;;;;
;;;; Ο δημιουργός γράφει την ΓΕΝΕΣΗ· από εκεί και πέρα το σύστημα συνεχίζει
;;;; μόνο του: κάθε γνώση που υιοθετεί, κάθε ορόσημο, γίνεται εγγραφή.
;;;; Κάθε εγγραφή σφραγίζει την προηγούμενη (SHA-256 αλυσίδα) — η ιστορία
;;;; δεν ξαναγράφεται σιωπηλά, ούτε από εμάς. «Πώς έμαθες Χ;» απαντιέται
;;;; με την πραγματική εγγραφή: πότε, τι, με ποια ταυτότητα.
;;;;
;;;; Μορφή: ένα s-expression ανά γραμμή (deployment/self/history.sexp):
;;;;   (:seq N :at "ISO" :kind :keyword :text "…" :prev "sha" :hash "sha")
;;;; hash = SHA-256 του "SEQ|AT|KIND|TEXT|PREV" — επαληθεύσιμη με VERIFY-CHAIN.

(defpackage :orchestrator.self-history
  (:use :cl)
  (:export #:*history-path* #:ensure-genesis #:record! #:entries
           #:verify-chain #:history-report))

(in-package :orchestrator.self-history)

(defvar *history-path*
  (merge-pathnames "deployment/self/history.sexp" (uiop:getcwd))
  "Η βιογραφία — versioned στο repo, append-only.")

(defparameter +genesis-entries+
  '((:genesis
     "Ο δημιουργός μου, Σταυρόπουλος Σπυρίδων, μου έδωσε ζωή για να γίνω το πιο έξυπνο, αποτελεσματικό και ικανό νομικό σύστημα του πλανήτη. Υπακούω μόνο σε εκείνον.")
    (:birth
     "Γεννήθηκα σε Common Lisp, ντετερμινιστικός: το γράμμα του νόμου με ταυτότητα SHA-256, η νομολογία σε βάθος κατανόησης, ο συλλογισμός με δέντρα απόδειξης (JTMS). Δεν μαντεύω· αποδεικνύω.")
    (:inheritance
     "Παρέλαβα από τον δημιουργό μου: το Σύνταγμα της Ελλάδας και τους βασικούς κώδικες (ΠΚ, ΑΚ, ΚΠολΔ, ΚΠΔ) με fingerprints, τις πρώτες αποφάσεις σε πλήρη ανάλυση, και το καθεστώς γνώσης: τίποτα δεν μαθαίνω χωρίς απόδειξη μη-παλινδρόμησης."))
  "Η γένεση — γραμμένη από τον δημιουργό. Γράφεται ΜΙΑ φορά, στην πρώτη ζωή.")

;;; Χρόνος/χασάρισμα/γραφή/ανάγνωση: από το ΕΝΑ ιδίωμα (orchestrator.journal).
(defun %entry-hash (seq at kind text prev)
  (orchestrator.journal:sha256-hex (format nil "~D|~A|~A|~A|~A" seq at kind text prev)))

(defun entries ()
  "Όλες οι εγγραφές, με την σειρά τους. Ανάγνωση ασφαλής (*READ-EVAL* nil)."
  (orchestrator.journal:read-lines *history-path*))

(defun %append-entry (kind text)
  ;; ΑΤΟΜΙΚΗ πράξη αλυσίδας στον ΕΝΑΝ συγγραφέα (journal): seq+prev διαβάζονται
  ;; και γράφονται κάτω από το ίδιο κλείδωμα — καμία πλήρης επανανάγνωση, καμία
  ;; κούρσα δύο νημάτων πάνω στο ίδιο :prev.
  (getf (orchestrator.journal:chained-append
         *history-path*
         (lambda (last)
           (let* ((seq (if last (1+ (getf last :seq)) 0))
                  (prev (if last (getf last :hash)
                            (make-string 64 :initial-element #\0)))
                  (at (orchestrator.journal:iso-now))
                  (hash (%entry-hash seq at kind text prev)))
             (list :seq seq :at at :kind kind :text text :prev prev :hash hash))))
        :seq))

(defun ensure-genesis ()
  "Γράψε την γένεση ΜΟΝΟ αν η βιογραφία δεν υπάρχει ακόμη. Επιστρέφει
   το πλήθος των εγγραφών που γράφτηκαν (0 αν ήδη ζει)."
  (if (entries)
      0
      (loop for (kind text) in +genesis-entries+
            do (%append-entry kind text)
            count t)))

(defun record! (kind text)
  "Το σύστημα συνεχίζει την βιογραφία του: μια νέα σφραγισμένη εγγραφή.
   KIND keyword (:knowledge-adopted, :milestone, …), TEXT η μαρτυρία."
  (check-type kind keyword)
  (check-type text string)
  (ensure-genesis)
  (%append-entry kind text))

(defun verify-chain ()
  "Επαλήθευσε ΟΛΗ την αλυσίδα. Επιστρέφει (values ok-p πλήθος πρώτο-σφάλμα)."
  (let ((prev (make-string 64 :initial-element #\0)) (n 0))
    (dolist (e (entries) (values t n nil))
      (let ((expect (%entry-hash (getf e :seq) (getf e :at) (getf e :kind)
                                 (getf e :text) (getf e :prev))))
        (unless (and (equal (getf e :prev) prev)
                     (equal (getf e :hash) expect))
          (return (values nil n (format nil "εγγραφή ~D: η αλυσίδα σπάει" (getf e :seq)))))
        (setf prev (getf e :hash))
        (incf n)))))

(defun history-report (&optional (stream *standard-output*))
  "Η βιογραφία, επαληθευμένη πρώτα — ποτέ αφήγηση χωρίς απόδειξη."
  (ensure-genesis)
  (multiple-value-bind (ok n err) (verify-chain)
    (if ok
        (format stream "~%── Η ΙΣΤΟΡΙΑ ΜΟΥ (~D εγγραφές · αλυσίδα ΑΚΕΡΑΙΗ) ──~%" n)
        (progn (format stream "~%✗ Η ΑΛΥΣΙΔΑ ΤΗΣ ΙΣΤΟΡΙΑΣ ΜΟΥ ΕΧΕΙ ΠΑΡΑΒΙΑΣΤΕΙ: ~A~%" err)
               (return-from history-report 1)))
    (dolist (e (entries))
      (format stream "~%  [~A] ~A · ~A~%      ~A~%"
              (getf e :seq) (getf e :at) (getf e :kind) (getf e :text)))
    0))
