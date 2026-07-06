;;;; source/contracts.lisp
;;;; ============================================================================
;;;; ΤΑ ΣΥΜΒΟΛΑΙΑ — μηχανικά ελέγξιμες υποσχέσεις, όχι σχόλια/docstrings/markdown
;;;; ============================================================================
;;;;
;;;; Το contract subsystem: κάθε ΚΡΙΣΙΜΗ συνάρτηση/πρωτόκολλο/εντολή δηλώνει
;;;; ΩΣ ΑΝΤΙΚΕΙΜΕΝΟ τι υπόσχεται — σκοπό, εισόδους/εξόδους, προ/μετα-συνθήκες,
;;;; παρενέργειες, νομική κρισιμότητα, επίπεδο πολιτικής, τρόπους αστοχίας,
;;;; υποχρεώσεις απόδειξης/audit/rollback, τα τεστ που την αποδεικνύουν, τους
;;;; κατάντη εξαρτώμενους και τις ετικέτες επίπτωσης. Το μητρώο είναι
;;;; queryable, ο επικυρωτής μηχανικός: συμβόλαιο που αναφέρει ανύπαρκτη
;;;; ικανότητα/ρόλο/τεστ ΡΙΧΝΕΙ την πύλη — ποτέ σιωπηλή απόκλιση.
;;;;
;;;; Διαχωρισμός στρωμάτων: το πακέτο αυτό ΔΕΝ γνωρίζει το μητρώο ικανοτήτων
;;;; ούτε το μητρώο εντολών — ο επικυρωτής παίρνει κατηγορήματα ύπαρξης
;;;; (capability-exists-p, test-exists-p) από τον καλούντα. Έτσι το contract
;;;; layer μένει καθαρός πυρήνας χωρίς κυκλικές εξαρτήσεις.

(defpackage :orchestrator.contracts
  (:use :cl)
  (:export #:defcontract #:declare-contract! #:find-contract #:all-contracts
           #:contract-name #:contract-kind #:contract-package #:contract-system
           #:contract-capability #:contract-role #:contract-purpose
           #:contract-inputs #:contract-outputs
           #:contract-preconditions #:contract-postconditions
           #:contract-side-effects #:contract-legal-critical
           #:contract-policy-level #:contract-failure-modes
           #:contract-conditions #:contract-proof-obligations
           #:contract-audit #:contract-rollback
           #:contract-tests #:contract-dependents #:contract-impact-tags
           #:contracts-for-capability #:contracts-for-role
           #:contract-dependent-names #:validate-contracts #:+policy-levels+
           #:register-gap-profile! #:find-gap-profile))

(in-package :orchestrator.contracts)

(defun %key (name) (string-downcase (string name)))

(defparameter +policy-levels+
  '(:παρατήρηση :συμβουλευτικό :φραγή :ανθρώπινη-έγκριση)
  "Κλίμακα πολιτικής: από απλή καταγραφή έως υποχρεωτική ανθρώπινη έγκριση.")

(defstruct (contract (:constructor %make-contract))
  name               ; string — όνομα συνάρτησης/πρωτοκόλλου/εντολής/συμβολαίου
  kind               ; :function :protocol :method :command :capability :institutional-identity
  package system     ; έδρα-πακέτο, σύστημα ASDF
  capability         ; ποια δηλωμένη ικανότητα υπηρετεί
  role               ; ποιος θεσμικός ρόλος/αίθουσα την κατέχει
  purpose            ; γιατί υπάρχει, μία πρόταση
  inputs outputs
  preconditions postconditions
  side-effects       ; λίστα (ή NIL = καθαρή)
  legal-critical     ; T όταν σφάλμα της = νομικό σφάλμα του Ιδρύματος
  policy-level       ; μέλος του +policy-levels+ (υποχρεωτικό επί legal-critical)
  failure-modes conditions
  proof-obligations  ; τι απόδειξη οφείλει να φέρει το αποτέλεσμά της
  audit              ; υποχρέωση audit/provenance (υποχρεωτική επί side-effects+legal-critical)
  rollback           ; υποχρέωση αναστρεψιμότητας (υποχρεωτική επί side-effects+legal-critical)
  tests              ; εντολές-πύλες που την αποδεικνύουν (ελέγχονται ότι ΥΠΑΡΧΟΥΝ)
  dependents         ; κατάντη ΙΚΑΝΟΤΗΤΕΣ που κληρονομούν κίνδυνο αν αλλάξει
  impact-tags)       ; ελεύθερες ετικέτες επίπτωσης (π.χ. :eli-uri :proof-hashes)

(defvar *contracts* '()
  "Το μητρώο συμβολαίων — διατεταγμένη λίστα, ντετερμινιστική σειρά δήλωσης.")

(defun declare-contract! (name kind &key package system capability role purpose
                                         inputs outputs preconditions postconditions
                                         side-effects legal-critical policy-level
                                         failure-modes conditions proof-obligations
                                         audit rollback tests dependents impact-tags)
  "Δήλωση συμβολαίου — αντικατάσταση κατά όνομα (idempotent reload)."
  (let ((c (%make-contract
            :name (string name) :kind kind :package package :system system
            :capability (and capability (string capability))
            :role (and role (string role))
            :purpose purpose :inputs inputs :outputs outputs
            :preconditions preconditions :postconditions postconditions
            :side-effects side-effects :legal-critical legal-critical
            :policy-level policy-level :failure-modes failure-modes
            :conditions conditions :proof-obligations proof-obligations
            :audit audit :rollback rollback :tests tests
            :dependents (mapcar #'string dependents)
            :impact-tags impact-tags)))
    (setf *contracts*
          (append (remove (%key name) *contracts*
                          :key (lambda (x) (%key (contract-name x)))
                          :test #'string=)
                  (list c)))
    c))

(defmacro defcontract (name kind &rest keys)
  "Η πειθαρχημένη μορφή δήλωσης συμβολαίου — greppable, ομοιόμορφη."
  `(declare-contract! ,name ,kind ,@keys))

(defun find-contract (name)
  (find (%key name) *contracts*
        :key (lambda (c) (%key (contract-name c))) :test #'string=))

(defun all-contracts () (copy-list *contracts*))

(defun contracts-for-capability (cap-name)
  (remove-if-not (lambda (c) (and (contract-capability c)
                                  (string= (%key (contract-capability c))
                                           (%key cap-name))))
                 *contracts*))

(defun contracts-for-role (role-name)
  (remove-if-not (lambda (c) (and (contract-role c)
                                  (string= (%key (contract-role c))
                                           (%key role-name))))
                 *contracts*))

(defun contract-dependent-names (frontier-keys)
  "Οι κατάντη ικανότητες που ΔΗΛΩΝΟΝΤΑΙ από τα συμβόλαια των ικανοτήτων του
   FRONTIER-KEYS (λίστα κλειδιών) — τροφή του αιτιώδους γράφου επίπτωσης."
  (let ((keys '()))
    (dolist (c *contracts*)
      (when (and (contract-capability c)
                 (member (%key (contract-capability c)) frontier-keys
                         :test #'string=))
        (dolist (d (contract-dependents c))
          (pushnew (%key d) keys :test #'string=))))
    keys))

(defun validate-contracts (&key capability-exists-p role-exists-p test-exists-p
                                institution coordination-engine-role-p)
  "Ο ΕΠΙΚΥΡΩΤΗΣ: λίστα παραβάσεων (strings) — κενή = υγιές μητρώο. Όλα τα
   κατηγορήματα ύπαρξης τα δίνει ο καλών (διαχωρισμός στρωμάτων)."
  (let ((v '()))
    (flet ((bad (fmt &rest args) (push (apply #'format nil fmt args) v)))
      (unless institution
        (bad "ΔΕΝ έχει δηλωθεί Ίδρυμα — το σύστημα δεν ξέρει ΤΙ είναι."))
      (when (and institution coordination-engine-role-p
                 (not (funcall coordination-engine-role-p)))
        (bad "Η μηχανή συντονισμού δεν είναι δηλωμένος ρόλος-όργανο."))
      (dolist (c *contracts*)
        (let ((n (contract-name c)))
          (when (and capability-exists-p (contract-capability c)
                     (not (funcall capability-exists-p (contract-capability c))))
            (bad "Συμβόλαιο «~A»: ανύπαρκτη ικανότητα «~A»." n (contract-capability c)))
          (unless (or (contract-role c) (eq (contract-kind c) :institutional-identity))
            (bad "Συμβόλαιο «~A»: χωρίς θεσμικό ρόλο." n))
          (when (and role-exists-p (contract-role c)
                     (not (funcall role-exists-p (contract-role c))))
            (bad "Συμβόλαιο «~A»: ανύπαρκτος ρόλος «~A»." n (contract-role c)))
          (when (and (contract-policy-level c)
                     (not (member (contract-policy-level c) +policy-levels+)))
            (bad "Συμβόλαιο «~A»: άγνωστο επίπεδο πολιτικής ~S." n (contract-policy-level c)))
          (when (contract-legal-critical c)
            (unless (contract-policy-level c)
              (bad "Συμβόλαιο «~A»: legal-critical ΧΩΡΙΣ επίπεδο πολιτικής." n))
            (unless (contract-tests c)
              (bad "Συμβόλαιο «~A»: legal-critical ΧΩΡΙΣ τεστ απόδειξης." n))
            (when (contract-side-effects c)
              (unless (contract-audit c)
                (bad "Συμβόλαιο «~A»: legal-critical με παρενέργειες ΧΩΡΙΣ υποχρέωση audit/provenance." n))
              (unless (contract-rollback c)
                (bad "Συμβόλαιο «~A»: legal-critical με παρενέργειες ΧΩΡΙΣ υποχρέωση rollback." n))))
          (when test-exists-p
            (dolist (tst (contract-tests c))
              (unless (funcall test-exists-p tst)
                (bad "Συμβόλαιο «~A»: αναφέρει ανύπαρκτο τεστ «~A»." n tst))))
          (when (and capability-exists-p (contract-dependents c))
            (dolist (d (contract-dependents c))
              (unless (funcall capability-exists-p d)
                (bad "Συμβόλαιο «~A»: κατάντη εξαρτώμενος «~A» δεν είναι δηλωμένη ικανότητα." n d)))))))
    (nreverse v)))

;;; ── ΠΡΟΦΙΛ ΚΕΝΩΝ: τι συμβόλαια απαιτεί μια ικανότητα που ΔΕΝ υπάρχει ──────
;;; Δηλωμένη γνώση (ποια συμβόλαια συνιστούν την ικανότητα) + μηχανικός
;;; έλεγχος (ποια υπάρχουν ήδη στο μητρώο) = τίμιο, συγκεκριμένο κενό.

(defvar *gap-profiles* '()
  "alist: όνομα-επιθυμητής-ικανότητας → λίστα ονομάτων απαιτούμενων συμβολαίων.")

(defun register-gap-profile! (wanted required-contracts)
  (let ((k (%key wanted)))
    (setf *gap-profiles*
          (cons (cons k (mapcar #'string required-contracts))
                (remove k *gap-profiles* :key #'car :test #'string=)))))

(defun find-gap-profile (wanted)
  (cdr (assoc (%key wanted) *gap-profiles* :test #'string=)))
