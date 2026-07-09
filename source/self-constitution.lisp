;;;; source/self-constitution.lisp
;;;; ============================================================================
;;;; ΤΟ ΣΥΝΤΑΓΜΑ ΤΟΥ ΣΥΣΤΗΜΑΤΟΣ — ανάγνωση, ταυτότητα, μετρήσιμη αποστολή
;;;; ============================================================================
;;;;
;;;; ΠΡΟΣΟΧΗ ΣΤΗΝ ΔΙΑΚΡΙΣΗ: το Σύνταγμα της Ελλάδας είναι ΑΝΤΙΚΕΙΜΕΝΟ ΓΝΩΣΗΣ
;;;; του συστήματος (corpus «Σ»). Το παρόν module διαβάζει το ΔΙΚΟ ΤΟΥ σύνταγμα
;;;; (deployment/SYSTEM-CONSTITUTION.sexp): ποιον υπηρετεί, γιατί, με ποιες
;;;; απαραβίαστες αρχές και ποιες μετρήσιμες αποστολές.
;;;;
;;;; ΜΙΑ ευθύνη (modular by design):
;;;;   • ανάγνωση+επικύρωση του κειμένου με ταυτότητα SHA-256 και ζωντανή
;;;;     φρεσκάδα (ίδια πειθαρχία με πακέτα γνώσης: άκυρο κείμενο ⇒ μένει το
;;;;     προηγούμενο, το σφάλμα δηλώνεται)·
;;;;   • πρόσβαση στα άρθρα/εντολέα/αποστολές·
;;;;   • ΜΗΤΡΩΟ ΜΕΤΡΗΣΕΩΝ αποστολής: το module ΔΕΝ ξέρει να μετρά τίποτα —
;;;;     ο καταναλωτής που κατέχει την ικανότητα (CLI για το 1/1, corpus για
;;;;     την ακεραιότητα) εγγράφει το κλείσιμό του (register-mission-measure).
;;;; ΚΑΜΙΑ εξάρτηση από inference/corpus/CLI — η φορά είναι πάντα προς τα εδώ.

(defpackage :orchestrator.self
  (:use :cl)
  (:export #:*constitution-path* #:ensure-constitution #:constitution-sha
           #:constitution-version #:serves #:articles #:missions
           #:register-mission-measure #:mission-status #:describe-constitution))

(in-package :orchestrator.self)

(defvar *constitution-path* nil
  "Ρητό override θέσης συντάγματος· NIL ⇒ επιλύεται ΣΤΟ RUNTIME στη ζωντανή ρίζα.")

(defun %constitution-path ()
  "Θέση του SYSTEM-CONSTITUTION.sexp μέσω FF1 institution-root — επιλύεται στο
   RUNTIME (εύρημα δημιουργού [0034]). Το παλιό baked (merge getcwd στο LOAD)
   πάγωνε /app/... στο build και δεν έβρισκε το αρχείο source-present (cwd=/src)."
  (or *constitution-path*
      (orchestrator.paths:institution-dir "deployment/SYSTEM-CONSTITUTION.sexp")))

(defvar *constitution* nil "plist (:version :sha :serves :because :articles :missions).")
(defvar *measures* (make-hash-table :test 'eq)
  "measure-keyword → κλείσιμο ()→(values κείμενο-κατάστασης ok-p). Εγγράφεται
   από τον καταναλωτή που ΞΕΡΕΙ να μετρά — ποτέ από εδώ.")

(defun %validate (form path)
  (unless (and (listp form) (eq (first form) :system-constitution)
               (integerp (second form)))
    (error "~A: δεν είναι (:system-constitution <version> …)" path))
  (let (serves because articles missions)
    (dolist (e (cddr form))
      (unless (and (listp e) (keywordp (first e)))
        (error "~A: κάθε διάταξη είναι (keyword …), βρέθηκε ~S" path e))
      (ecase (first e)
        (:serves (setf serves (second e)
                       because (getf (cddr e) :because)))
        (:article (destructuring-bind (n title text) (rest e)
                    (unless (and (integerp n) (stringp title) (stringp text))
                      (error "~A: άρθρο = (:article N \"τίτλος\" \"κείμενο\")" path))
                    (push (list n title text) articles)))
        (:mission (destructuring-bind (key desc &key measure) (rest e)
                    (unless (and (keywordp key) (stringp desc))
                      (error "~A: αποστολή = (:mission :key \"περιγραφή\" :measure :kw)" path))
                    (push (list key desc measure) missions)))))
    (unless serves (error "~A: λείπει το (:serves …) — ποιον υπηρετεί;" path))
    (list :version (second form) :serves serves :because because
          :articles (nreverse articles) :missions (nreverse missions))))

(defun ensure-constitution (&key (path (%constitution-path)) (stream nil))
  "Φόρτωσε/ξαναφόρτωσε το σύνταγμα αν άλλαξε (κατά SHA). Άκυρο κείμενο ⇒
   κρατιέται το ισχύον και το σφάλμα ΔΗΛΩΝΕΤΑΙ. Επιστρέφει το ενεργό plist."
  (when (probe-file path)
    (let ((sha (ironclad:byte-array-to-hex-string
                (ironclad:digest-file :sha256 path))))
      (unless (equal sha (getf *constitution* :sha))
        (handler-case
            (let ((form (with-open-file (s path :external-format :utf-8)
                          (with-standard-io-syntax
                            (let ((*read-eval* nil)
                                  (*package* (find-package :keyword)))
                              (read s))))))
              (setf *constitution* (append (%validate form path) (list :sha sha)))
              (when stream
                (format stream "  ✓ σύνταγμα συστήματος v~D (sha ~A…)~%"
                        (getf *constitution* :version) (subseq sha 0 12))))
          (error (e)
            (format (or stream *standard-output*)
                    "  ✗ το νέο κείμενο συντάγματος ΑΠΟΡΡΙΦΘΗΚΕ (ισχύει το προηγούμενο): ~A~%" e))))))
  *constitution*)

(defun constitution-sha () (getf (ensure-constitution) :sha))
(defun constitution-version () (getf (ensure-constitution) :version))
(defun serves ()
  (let ((c (ensure-constitution)))
    (values (getf c :serves) (getf c :because))))
(defun articles () (getf (ensure-constitution) :articles))
(defun missions () (getf (ensure-constitution) :missions))

(defun register-mission-measure (key fn)
  "Ο καταναλωτής που ΞΕΡΕΙ να μετρά την αποστολή KEY εγγράφει το κλείσιμό
   του: ()→(values κείμενο-κατάστασης ok-p). Μηδέν εξάρτηση αντίστροφης φοράς."
  (check-type key keyword)
  (setf (gethash key *measures*) fn)
  key)

(defun mission-status ()
  "Η απόσταση από ΚΑΘΕ αποστολή, μετρημένη ΤΩΡΑ από τους αρμόδιους.
   Λίστα (desc status ok-p) — αποστολή χωρίς εγγεγραμμένη μέτρηση δηλώνεται
   ΑΜΕΤΡΗΤΗ (τίμια), δεν εμφανίζεται ως εκπληρωμένη."
  (loop for (key desc measure) in (missions)
        for fn = (and measure (gethash measure *measures*))
        collect (if fn
                    (multiple-value-bind (status ok) (funcall fn)
                      (list desc status ok))
                    (list desc "αμέτρητη προς το παρόν — καμία εγγεγραμμένη μέτρηση" nil))
        do (progn key)))

(defun describe-constitution (&optional (stream *standard-output*))
  "Το πλήρες σύνταγμα με την ταυτότητά του — και η αποστολή ΜΕΤΡΗΜΕΝΗ."
  (let ((c (ensure-constitution)))
    (unless c
      (format stream "~%(δεν βρέθηκε σύνταγμα συστήματος στο ~A)~%" (%constitution-path))
      (return-from describe-constitution 1))
    (format stream "~%── ΤΟ ΣΥΝΤΑΓΜΑ ΤΟΥ ΣΥΣΤΗΜΑΤΟΣ · v~D · sha ~A… ──~%"
            (getf c :version) (subseq (getf c :sha) 0 16))
    (multiple-value-bind (who why) (serves)
      (format stream "~%Υπηρετώ: ~A~%Διότι: ~A~%" who why))
    (dolist (a (articles))
      (format stream "~%Άρθρο ~D — ~A~%  ~A~%" (first a) (second a) (third a)))
    (format stream "~%── Η ΑΠΟΣΤΟΛΗ, ΜΕΤΡΗΜΕΝΗ ΤΩΡΑ ──~%")
    (dolist (m (mission-status))
      (format stream "  ~:[◌~;✓~] ~A~%      → ~A~%" (third m) (first m) (second m)))
    0))
