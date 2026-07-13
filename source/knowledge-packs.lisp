;;;; source/knowledge-packs.lisp
;;;; ============================================================================
;;;; ΠΑΚΕΤΑ ΓΝΩΣΗΣ — η γνώση υπό το ΙΔΙΟ επιστημικό καθεστώς με τον νόμο
;;;; ============================================================================
;;;;
;;;; Ο Advice Taker, κυριολεκτικά: το σύστημα δέχεται νέα γνώση ως ΔΗΛΩΣΕΙΣ
;;;; σε αρχεία (deployment/knowledge/*.sexp), όχι ως επαναμεταγλώττιση. Και
;;;; επειδή πρόκειται για σύστημα νομικής αυθεντίας, η γνώση υπάγεται στην
;;;; ίδια πειθαρχία με τα κείμενα των νόμων:
;;;;
;;;;   • ΤΑΥΤΟΤΗΤΑ: κάθε πακέτο έχει SHA-256 fingerprint — ξέρεις αποδείξιμα
;;;;     ποια γνώση τρέχει, πάντα.
;;;;   • ΖΩΝΤΑΝΗ ΦΟΡΤΩΣΗ: το τρέχον σύστημα ξαναδιαβάζει τα πακέτα όταν
;;;;     αλλάξουν (ENSURE-FRESH) — καμία επανεκκίνηση για νέα γνώση. Πακέτο
;;;;     που δεν περνά την επικύρωση ΔΕΝ εγκαθίσταται· μένει η προηγούμενη
;;;;     γνώση και το σφάλμα δηλώνεται (ποτέ σιωπηλή διαφθορά).
;;;;   • ΣΚΙΩΔΗΣ ΕΚΤΕΛΕΣΗ: WITH-PACKS-OVERLAY εγκαθιστά υποψήφια γνώση
;;;;     ΠΡΟΣΩΡΙΝΑ (snapshot→install→run→restore), ώστε η CLI να ξανατρέξει
;;;;     την κατανόηση σε ΟΛΟ το υπάρχον σώμα αποφάσεων και να αποδείξει
;;;;     μη-παλινδρόμηση ΠΡΙΝ την υιοθέτηση. Το «0 λάθος» ως μηχανικός
;;;;     φραγμός, όχι ως υπόσχεση.
;;;;
;;;; Μορφή πακέτου (ένα s-expression, αναγνωσμένο με *READ-EVAL* nil):
;;;;   (:knowledge-pack <kind> <version>
;;;;     (<entry-keyword> ...) ...)
;;;; Τα είδη (<kind>) και η σημασιολογία των entries ορίζονται από τους
;;;; ΚΑΤΑΝΑΛΩΤΕΣ μέσω DEFINE-KNOWLEDGE-KIND — αυτό το module ξέρει μόνο
;;;; ταυτότητα, φρεσκάδα, επικύρωση σχήματος και overlay. Καμία λογική
;;;; πεδίου εδώ (no duplicate code).

(defpackage :orchestrator.knowledge-packs
  (:use :cl)
  (:export #:define-knowledge-kind #:ensure-fresh #:with-packs-overlay
           #:active-packs #:describe-active #:*knowledge-dir* #:knowledge-dir
           #:pack-sha #:load-pack))

(in-package :orchestrator.knowledge-packs)

(orchestrator.paths:define-store-path knowledge-dir *knowledge-dir*
  "deployment/knowledge/" "Τα ενεργά πακέτα γνώσης — versioned όπως ο νόμος.")

(defvar *kinds* (make-hash-table :test 'eq)
  "kind → plist (:install fn :snapshot fn :restore fn :doc string).")

(defvar *active* (make-hash-table :test 'equal)
  "namestring → plist (:sha :kind :version :entries-count) — τι τρέχει ΤΩΡΑ.")

(defun define-knowledge-kind (kind &key install snapshot restore doc)
  "Ένας καταναλωτής δηλώνει πώς εγκαθίσταται/φωτογραφίζεται/επανέρχεται το
   είδος γνώσης KIND. INSTALL: (entries)→. SNAPSHOT: ()→state.
   RESTORE: (state)→. Όλα κλεισίματα του καταναλωτή — το module μένει αγνό."
  (check-type kind keyword)
  (assert (and install snapshot restore) ()
          "define-knowledge-kind ~A: χρειάζονται install+snapshot+restore" kind)
  (setf (gethash kind *kinds*)
        (list :install install :snapshot snapshot :restore restore :doc doc))
  kind)

(defun pack-sha (path)
  "SHA-256 του πακέτου — η ταυτότητα της γνώσης, όπως των άρθρων."
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-file :sha256 path)))

(defun load-pack (path)
  "Διάβασε+επικύρωσε ένα πακέτο. Επιστρέφει plist (:kind :version :entries
   :sha :path) ή σφάλμα με ΣΥΓΚΕΚΡΙΜΕΝΗ αιτία — ποτέ μισοφορτωμένη γνώση."
  (let ((form (with-open-file (s path :external-format :utf-8)
                (with-standard-io-syntax
                  (let ((*read-eval* nil)
                        (*package* (find-package :keyword)))
                    (read s))))))
    (unless (and (listp form) (eq (first form) :knowledge-pack))
      (error "~A: δεν είναι (:knowledge-pack …)" path))
    (destructuring-bind (marker kind version &rest entries) form
      (declare (ignore marker))
      (unless (keywordp kind) (error "~A: kind πρέπει να είναι keyword" path))
      (unless (integerp version) (error "~A: version πρέπει να είναι ακέραιος" path))
      (unless (gethash kind *kinds*)
        (error "~A: άγνωστο είδος γνώσης ~A — κανείς καταναλωτής δεν το όρισε" path kind))
      (dolist (e entries)
        (unless (and (listp e) (keywordp (first e)))
          (error "~A: κάθε entry είναι (keyword …), βρέθηκε: ~S" path e)))
      (list :kind kind :version version :entries entries
            :sha (pack-sha path) :path (namestring path)))))

(defun %stat (path)
  "(mtime . size) του PATH ή nil — το φθηνό αποτύπωμα αλλαγής (Φάση 1):
   το SHA-256 υπολογίζεται ΜΟΝΟ όταν αυτό αλλάξει, όχι σε κάθε ensure-fresh."
  (let ((st (ignore-errors (sb-posix:stat (namestring path)))))
    (when st (cons (sb-posix:stat-mtime st) (sb-posix:stat-size st)))))

(defun %install (pack)
  (funcall (getf (gethash (getf pack :kind) *kinds*) :install)
           (getf pack :entries))
  (setf (gethash (getf pack :path) *active*)
        (list :sha (getf pack :sha) :kind (getf pack :kind)
              :version (getf pack :version)
              :entries-count (length (getf pack :entries))
              :stat (%stat (getf pack :path)))))

(defvar *fresh-lock* (sb-thread:make-mutex :name "knowledge-packs-fresh")
  "Ένας εγκαταστάτης γνώσης τη φορά — το ensure-fresh καλείται σε ΚΑΘΕ /ask και
   δύο ταυτόχρονα αιτήματα δεν επιτρέπεται να ξανεγκαθιστούν πακέτα μαζί (Φάση 0).")

(defun ensure-fresh (&key (dir (knowledge-dir)) (stream nil))
  "Φόρτωσε/ξαναφόρτωσε ό,τι πακέτο άλλαξε (κατά SHA). Άκυρο πακέτο ⇒ μένει
   η προηγούμενη γνώση και το σφάλμα ΔΗΛΩΝΕΤΑΙ. Επιστρέφει πλήθος αλλαγών.
   Thread-safe: ένας εγκαταστάτης τη φορά (αναδρομικό κλείδωμα)."
  (sb-thread:with-recursive-lock (*fresh-lock*)
    (%ensure-fresh dir stream)))

(defun %ensure-fresh (dir stream)
  (let ((n 0))
    (when (probe-file dir)
      (dolist (f (sort (directory (merge-pathnames "*.sexp" dir))
                       #'string< :key #'namestring))
        (let* ((key (namestring f))
               (info (gethash key *active*))
               (stat (%stat f)))
          ;; προ-φίλτρο (Φάση 1): ίδιο (mtime . μέγεθος) ⇒ τίποτα δεν άλλαξε —
          ;; κανένα SHA, καμία ανάγνωση. Το ensure-fresh τρέχει σε ΚΑΘΕ /ask.
          (unless (and info stat (equal stat (getf info :stat)))
            (let ((sha (ignore-errors (pack-sha f)))
                  (known (getf info :sha)))
              (cond ((null sha))            ; μη αναγνώσιμο — θα δηλωθεί όταν διαβαστεί
                    ((equal sha known)
                     ;; ίδιο περιεχόμενο, νέο αποτύπωμα (πχ touch/checkout) —
                     ;; μόνο ανανέωση αποτυπώματος, όχι επανεγκατάσταση
                     (setf (getf (gethash key *active*) :stat) stat))
                    (t
                     ;; ΑΤΟΜΙΚΟΤΗΤΑ (εύρημα επιθεώρησης 05-07-2026): snapshot του
                     ;; είδους ΠΡΙΝ την εγκατάσταση — σφάλμα στη μέση ⇒ ΠΛΗΡΗΣ
                     ;; επαναφορά, ώστε το «κρατιέται η προηγούμενη γνώση» να
                     ;; είναι αλήθεια και όχι ευχή (καμία μισο-εγκατεστημένη γνώση)
                     (handler-case
                         (let* ((pack (load-pack f))
                                (fns (gethash (getf pack :kind) *kinds*))
                                (snap (funcall (getf fns :snapshot))))
                           (handler-case
                               (progn (%install pack) (incf n)
                                      (when stream
                                        (format stream "  ✓ γνώση: ~A (~A…)~%"
                                                (file-namestring f) (subseq sha 0 12))))
                             (error (e)
                               (funcall (getf fns :restore) snap)
                               (error e))))
                       (error (e)
                         (format (or stream *standard-output*)
                                 "  ✗ πακέτο ~A ΑΠΟΡΡΙΦΘΗΚΕ (κρατιέται η προηγούμενη γνώση): ~A~%"
                                 (file-namestring f) e))))))))))
    n))

(defun with-packs-overlay (paths thunk)
  "ΣΚΙΩΔΗΣ ΕΚΤΕΛΕΣΗ: φωτογράφισε την κατάσταση ΟΛΩΝ των ειδών, εγκατάστησε
   προσωρινά τα PATHS, τρέξε το THUNK, επανάφερε ΕΓΓΥΗΜΕΝΑ (unwind-protect).
   Η ενεργή γνώση δεν αγγίζεται ποτέ από υποψήφια πακέτα."
  (let ((snaps (loop for kind being the hash-keys of *kinds*
                     using (hash-value fns)
                     collect (cons kind (funcall (getf fns :snapshot))))))
    (unwind-protect
         (progn
           (dolist (p paths) (%install (load-pack p)))
           (funcall thunk))
      (loop for (kind . state) in snaps
            do (funcall (getf (gethash kind *kinds*) :restore) state))
      ;; τα *active* των υποψηφίων δεν είναι πλέον αλήθεια — καθάρισε
      (dolist (p paths) (remhash (namestring (pathname p)) *active*)))))

(defun active-packs ()
  (loop for k being the hash-keys of *active* using (hash-value v)
        collect (cons k v)))

(defun describe-active (&optional (stream *standard-output*))
  (let ((packs (active-packs)))
    (if packs
        (progn
          (format stream "~%── ΕΝΕΡΓΗ ΓΝΩΣΗ (~D πακέτα) ──~%" (length packs))
          (dolist (p (sort packs #'string< :key #'car))
            (format stream "  ~A · ~A v~D · ~D entries · sha ~A…~%"
                    (file-namestring (car p)) (getf (cdr p) :kind)
                    (getf (cdr p) :version) (getf (cdr p) :entries-count)
                    (subseq (getf (cdr p) :sha) 0 12))))
        (format stream "~%(καμία εξωτερική γνώση — τρέχει μόνο η ενσωματωμένη)~%"))))
