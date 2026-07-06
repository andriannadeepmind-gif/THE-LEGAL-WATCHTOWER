;;;; source/component-scan.lisp
;;;; ============================================================================
;;;; Ο ΣΑΡΩΤΗΣ ΣΥΣΤΑΤΙΚΩΝ — το μητρώο χτίζεται από τη ΖΩΝΤΑΝΗ εικόνα, τώρα
;;;; ============================================================================
;;;;
;;;; Τίποτα χειρόγραφο: συστήματα από το ASDF, hashes από τα ίδια τα αρχεία
;;;; (SHA-256), πακέτα από την εικόνα, έδρες defpackage/defcontract/
;;;; declare-capability! από το κείμενο των αρχείων (ντετερμινιστική σάρωση),
;;;; πηγή κάθε κρίσιμου συμβόλου από το sb-introspect. Ό,τι δεν ταυτοποιείται
;;;; βγαίνει ΠΑΡΑΒΑΣΗ — όχι σιωπηλά άγνωστο.
;;;;
;;;; Στρωμάτωση: components = καθαρό μητρώο· scan = ο μόνος που ξέρει από
;;;; ASDF/MOP/introspection· ο καθρέφτης και οι πύλες είναι ΚΑΤΑΝΑΛΩΤΕΣ.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :sb-introspect))

(defpackage :orchestrator.component-scan
  (:use :cl)
  (:export #:build-component-registry! #:validate-components
           #:resolve-critical-symbol #:file-hash #:stale-components
           #:freeze-components! #:manifest-count #:known-file-hash))

(in-package :orchestrator.component-scan)

(defun file-hash (path)
  (ignore-errors
    (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path))))

(defun %lawmax-systems ()
  "Τα φορτωμένα συστήματα orchestrator-* — από το ASDF, όχι από λίστα."
  (sort (remove-if-not (lambda (n) (eql 0 (search "orchestrator" n)))
                       (asdf:already-loaded-systems))
        #'string<))

(defun %system-files (sys)
  "Όλα τα cl-source-file ενός συστήματος, αναδρομικά, με τη σειρά του .asd."
  (labels ((walk (c)
             (typecase c
               (asdf:cl-source-file (list (asdf:component-pathname c)))
               (asdf:parent-component
                (mapcan #'walk (asdf:component-children c))))))
    (walk sys)))

(defun %scan-file-text (path)
  "Ντετερμινιστική σάρωση κειμένου: (values defpackage-names contract-names
   capability-names) — οι ΕΔΡΕΣ των δηλώσεων."
  (let ((text (or (ignore-errors (uiop:read-file-string path :external-format :utf-8)) ""))
        (pkgs '()) (contracts '()) (caps '()))
    (cl-ppcre:do-register-groups (p) ("\\(defpackage\\s+[:#]*([^\\s()]+)" text)
      (pushnew (string-downcase p) pkgs :test #'string=))
    (cl-ppcre:do-register-groups (c) ("defcontract\\s+\"([^\"]+)\"" text)
      (pushnew c contracts :test #'string=))
    (cl-ppcre:do-register-groups (c) ("declare-capability!\\s+\"([^\"]+)\"" text)
      (pushnew c caps :test #'string=))
    (values (nreverse pkgs) (nreverse contracts) (nreverse caps))))

;;; ── MANIFEST: οι ταυτότητες παγώνουν στο BUILD, όταν οι πηγές υπάρχουν ────
;;; Το runtime image (native executable) ΔΕΝ κουβαλά τα source αρχεία. Χωρίς
;;; manifest, 250+ αρχεία θα ήταν «αταυτοποίητη ύλη». Το build.lisp καλεί
;;; freeze-components! με τις πηγές παρούσες· στο runtime το μητρώο διαβάζει
;;; το manifest (data-only, *read-eval* NIL) ως την αλήθεια του build.

(defun %manifest-file ()
  (merge-pathnames "deployment/self/component-manifest.sexp" (uiop:getcwd)))

(defvar *manifest* nil "cache: σχετική-διαδρομή → plist (:hash :defpackages …)")

(defun %load-manifest ()
  (or *manifest*
      (setf *manifest*
            (let ((h (make-hash-table :test 'equal)))
              (ignore-errors
                (with-open-file (s (%manifest-file) :external-format :utf-8
                                                    :if-does-not-exist nil)
                  (when s
                    (let ((*read-eval* nil))   ; ΜΟΝΟ δεδομένα — ποτέ εκτέλεση
                      (dolist (e (read s nil nil))
                        (setf (gethash (getf e :file) h) e))))))
              h))))

(defun manifest-count () (hash-table-count (%load-manifest)))

(defun known-file-hash (rel-path)
  "Η ΓΝΩΣΤΗ αλήθεια για ένα αρχείο πηγής: ο δίσκος αν υπάρχει, αλλιώς το
   παγωμένο manifest του build — ώστε ο έλεγχος ξεπερασμένων hashes να έχει
   μέτρο σύγκρισης ΚΑΙ στο source-less runtime."
  (or (file-hash (merge-pathnames rel-path (uiop:getcwd)))
      (getf (gethash (string rel-path) (%load-manifest)) :hash)))

(defun freeze-components! ()
  "Πάγωμα ταυτοτήτων ΟΛΩΝ των αρχείων πηγής (SHA-256 + έδρες δηλώσεων) στο
   manifest — καλείται στο BUILD. Επιστρέφει πλήθος αρχείων."
  (let ((rows '()))
    (dolist (sysname (%lawmax-systems))
      (dolist (path (%system-files (asdf:find-system sysname)))
        (let ((h (file-hash path)))
          (when h
            (multiple-value-bind (pkgs contracts caps) (%scan-file-text path)
              (push (list :file (enough-namestring path (uiop:getcwd))
                          :hash h :defpackages pkgs
                          :contracts contracts :capabilities caps)
                    rows))))))
    (let ((all (nreverse rows)))
      (ensure-directories-exist (%manifest-file))
      (with-open-file (s (%manifest-file) :direction :output
                                          :if-exists :supersede
                                          :external-format :utf-8)
        (let ((*print-pretty* nil))
          (format s ";; ΤΑΥΤΟΤΗΤΕΣ ΣΥΣΤΑΤΙΚΩΝ — παγωμένες στο build (data-only)~%")
          (prin1 all s)
          (terpri s)))
      (setf *manifest* nil)
      (length all))))

(defun resolve-critical-symbol (name package-designator)
  "Όνομα κρίσιμης συνάρτησης/κλάσης → (values σύμβολο αρχείο-πηγής) ή NIL.
   Ψάχνει πρώτα στην έδρα-πακέτο, μετά σε ΟΛΑ τα orchestrator.* (ικανότητες
   με CLI-παρόχους). Πηγή από το sb-introspect — η αλήθεια του compiler."
  (labels ((try (pkg)
             (let ((s (and pkg (find-symbol (string-upcase name) pkg))))
               (when s
                 (let ((src (cond
                              ((fboundp s)
                               (ignore-errors
                                 (sb-introspect:definition-source-pathname
                                  (sb-introspect:find-definition-source
                                   (or (macro-function s) (fdefinition s))))))
                              ((find-class s nil)
                               (ignore-errors
                                 (sb-introspect:definition-source-pathname
                                  (sb-introspect:find-definition-source
                                   (find-class s))))))))
                   (when src (return-from resolve-critical-symbol
                               (values s src))))))))
    (try (find-package (string-upcase (string package-designator))))
    (dolist (p (list-all-packages))
      (when (eql 0 (search "ORCHESTRATOR." (package-name p)))
        (try p)))
    nil))

(defun %critical-symbols ()
  "Το σύνολο των κρίσιμων συμβόλων: πάροχοι ικανοτήτων + :function συμβόλαια.
   Επιστρέφει λίστα (name package capability contract-p)."
  (let ((out '()))
    (dolist (cap (orchestrator.self-model:all-capabilities))
      (dolist (f (orchestrator.self-model:capability-functions cap))
        (push (list f (orchestrator.self-model:capability-package cap)
                    (orchestrator.self-model:capability-name cap) nil)
              out)))
    (dolist (c (orchestrator.contracts:all-contracts))
      (when (eq (orchestrator.contracts:contract-kind c) :function)
        (pushnew (list (orchestrator.contracts:contract-name c)
                       (orchestrator.contracts:contract-package c)
                       (orchestrator.contracts:contract-capability c) t)
                 out :key #'first :test #'string=)))
    (nreverse out)))

(defun %role-of-package (pkg-name)
  "Ρόλος πακέτου: κληρονομείται από τα συμβόλαια που εδρεύουν σε αυτό —
   υπολογισμένος, όχι αφηγημένος. NIL = ορατό χρέος."
  (let ((c (find-if (lambda (c)
                      (and (orchestrator.contracts:contract-package c)
                           (string-equal (string (orchestrator.contracts:contract-package c))
                                         pkg-name)))
                    (orchestrator.contracts:all-contracts))))
    (and c (orchestrator.contracts:contract-role c))))

(defun build-component-registry! ()
  "Χτίζει το μητρώο από τη ζωντανή εικόνα. Επιστρέφει (values #συστατικών #ακμών)."
  (orchestrator.components:clear-registry!)
  (let ((pkg-home (make-hash-table :test 'equal)))   ; package → file-id
    ;; ① Συστήματα + αρχεία (με SHA-256) + έδρες δηλώσεων
    (dolist (sysname (%lawmax-systems))
      (let* ((sys (asdf:find-system sysname))
             (sys-id (format nil "system:~A" sysname)))
        (orchestrator.components:register-component!
         sys-id :system sysname
         :meta (list :version (ignore-errors (asdf:component-version sys))
                     :depends-on (asdf:system-depends-on sys)))
        (dolist (path (%system-files sys))
          (let* ((rel (enough-namestring path (uiop:getcwd)))
                 (file-id (format nil "file:~A" rel))
                 (disk-hash (file-hash path))
                 ;; πηγή απούσα (source-less runtime) ⇒ η αλήθεια του BUILD:
                 ;; το παγωμένο manifest — ποτέ σιωπηλά «αταυτοποίητο»
                 (m (and (null disk-hash) (gethash rel (%load-manifest)))))
            (multiple-value-bind (pkgs contracts caps)
                (if disk-hash
                    (%scan-file-text path)
                    (values (getf m :defpackages) (getf m :contracts)
                            (getf m :capabilities)))
              (orchestrator.components:register-component!
               file-id :file (file-namestring path)
               :parent sys-id :hash (or disk-hash (getf m :hash))
               :meta (list :path (namestring path) :defpackages pkgs
                           :contracts contracts :capabilities caps
                           :from-manifest (and m t)))
              (orchestrator.components:add-edge! :contains sys-id file-id)
              (dolist (p pkgs) (setf (gethash p pkg-home) file-id)))))))
    ;; ② Πακέτα της εικόνας — έδρα από το defpackage mapping
    (dolist (p (sort (remove-if-not
                      (lambda (p) (eql 0 (search "ORCHESTRATOR" (package-name p))))
                      (list-all-packages))
                     #'string< :key #'package-name))
      (let* ((pname (string-downcase (package-name p)))
             (pkg-id (format nil "package:~A" pname))
             (home (gethash pname pkg-home))
             (exports (let ((acc '()))
                        (do-external-symbols (s p) (push (symbol-name s) acc))
                        (sort acc #'string<))))
        (orchestrator.components:register-component!
         pkg-id :package pname :parent home
         :role (%role-of-package pname)
         :meta (list :exports-count (length exports) :exports exports
                     :uses (mapcar (lambda (u) (string-downcase (package-name u)))
                                   (package-use-list p))))
        (when home (orchestrator.components:add-edge! :defines home pkg-id))))
    ;; ③ Κρίσιμα σύμβολα — πηγή από τον compiler (sb-introspect)
    (dolist (entry (%critical-symbols))
      (destructuring-bind (name pkg cap contract-p) entry
        (multiple-value-bind (sym src) (resolve-critical-symbol name pkg)
          (let* ((real-pkg (and sym (string-downcase (package-name (symbol-package sym)))))
                 (sym-id (format nil "symbol:~A::~A" (or real-pkg ";ΑΓΝΩΣΤΟ;")
                                 (string-downcase name))))
            (unless (orchestrator.components:find-component sym-id)
              (orchestrator.components:register-component!
               sym-id :symbol name
               :parent (and real-pkg (format nil "package:~A" real-pkg))
               :role (let ((c (orchestrator.contracts:find-contract name)))
                       (and c (orchestrator.contracts:contract-role c)))
               :meta (list :capability cap :contract contract-p
                           :source (and src (enough-namestring src (uiop:getcwd)))
                           :resolved (and sym t))))
            (when real-pkg
              (orchestrator.components:add-edge!
               :exports (format nil "package:~A" real-pkg) sym-id))
            (when src
              (orchestrator.components:add-edge!
               :defined-in sym-id
               (format nil "file:~A" (enough-namestring src (uiop:getcwd)))))
            (when (orchestrator.contracts:find-contract name)
              (orchestrator.components:add-edge!
               :bound-by sym-id (format nil "contract:~A" name)))
            (when cap
              (orchestrator.components:add-edge!
               :provides sym-id (format nil "capability:~A" cap)))))))
    ;; ④ Ακμές συμβολαίων/ικανοτήτων/πυλών (οι κόμβοι τους ζουν στα μητρώα τους —
    ;;    εδώ μπαίνουν στον ΕΝΑ γράφο ως ταυτότητες)
    (dolist (c (orchestrator.contracts:all-contracts))
      (when (orchestrator.contracts:contract-capability c)
        (orchestrator.components:add-edge!
         :serves (format nil "contract:~A" (orchestrator.contracts:contract-name c))
         (format nil "capability:~A" (orchestrator.contracts:contract-capability c)))))
    (dolist (cap (orchestrator.self-model:all-capabilities))
      (when (orchestrator.self-model:capability-gate cap)
        (orchestrator.components:add-edge!
         :proven-by (format nil "capability:~A" (orchestrator.self-model:capability-name cap))
         (format nil "gate:~A" (orchestrator.self-model:capability-gate cap))))
      (dolist (dep (orchestrator.self-model:capability-depends-on cap))
        (orchestrator.components:add-edge!
         :depends-on (format nil "capability:~A" (orchestrator.self-model:capability-name cap))
         (format nil "capability:~A" dep)))))
  (values (length (orchestrator.components:all-components))
          (length (orchestrator.components:all-edges))))

(defun stale-components ()
  "Συστατικά-αρχεία των οποίων το ΑΠΟΘΗΚΕΥΜΕΝΟ hash ΔΕΝ συμφωνεί με τον δίσκο
   ΤΩΡΑ. Πηγή απούσα από τον δίσκο (source-less runtime με manifest) ΔΕΝ είναι
   stale — το manifest του build είναι η αλήθεια της· η απόκλιση ανιχνεύεται
   ΜΟΝΟ όταν υπάρχει τι να συγκριθεί."
  (remove-if (lambda (c)
               (let ((now (file-hash (orchestrator.components:meta-get c :path))))
                 (or (null now)
                     (equal (orchestrator.components:component-hash c) now))))
             (orchestrator.components:components-of-kind :file)))

(defun validate-components (&key test-exists-p)
  "Ο ΕΠΙΚΥΡΩΤΗΣ ΣΥΣΤΑΤΙΚΩΝ: λίστα παραβάσεων — κενή = πλήρης ταυτοποίηση."
  (let ((v '()))
    (flet ((bad (fmt &rest args) (push (apply #'format nil fmt args) v)))
      ;; αρχεία χωρίς hash
      (dolist (f (orchestrator.components:components-of-kind :file))
        (unless (orchestrator.components:component-hash f)
          (bad "Αρχείο «~A» χωρίς hash — αταυτοποίητη ύλη." (orchestrator.components:component-id f))))
      ;; πακέτα χωρίς έδρα-σύστημα
      (dolist (p (orchestrator.components:components-of-kind :package))
        (unless (orchestrator.components:component-parent p)
          (bad "Πακέτο «~A» χωρίς αρχείο-έδρα σε δηλωμένο σύστημα." (orchestrator.components:component-name p))))
      ;; κρίσιμα σύμβολα χωρίς πηγή
      (dolist (s (orchestrator.components:components-of-kind :symbol))
        (unless (orchestrator.components:meta-get s :resolved)
          (bad "Κρίσιμο σύμβολο «~A» (ικανότητα ~A) ΔΕΝ επιλύεται στη ζωντανή εικόνα."
               (orchestrator.components:component-name s)
               (orchestrator.components:meta-get s :capability)))
        (when (and (orchestrator.components:meta-get s :resolved)
                   (null (orchestrator.components:meta-get s :source)))
          (bad "Κρίσιμο σύμβολο «~A» χωρίς χαρτογραφημένη πηγή." (orchestrator.components:component-name s))))
      ;; κρίσιμα αρχεία (με legal-critical συμβόλαια) χωρίς ρόλο πακέτου
      (dolist (s (orchestrator.components:components-of-kind :symbol))
        (let ((c (orchestrator.contracts:find-contract
                  (orchestrator.components:component-name s))))
          (when (and c (orchestrator.contracts:contract-legal-critical c)
                     (null (orchestrator.components:component-role s)))
            (bad "Legal-critical σύμβολο «~A» χωρίς θεσμικό ρόλο." (orchestrator.components:component-name s)))))
      ;; τεστ συμβολαίων: υπαρκτά ως εντολές (το κατηγόρημα δίνει ο καλών)
      (when test-exists-p
        (dolist (c (orchestrator.contracts:all-contracts))
          (dolist (tst (orchestrator.contracts:contract-tests c))
            (unless (funcall test-exists-p tst)
              (bad "Συμβόλαιο «~A»: τεστ «~A» δεν χαρτογραφείται σε εντολή."
                   (orchestrator.contracts:contract-name c) tst)))))
      ;; απόκλιση hash μητρώου/δίσκου
      (dolist (f (stale-components))
        (bad "ΞΕΠΕΡΑΣΜΕΝΟ hash: «~A» — το μητρώο δεν συμφωνεί με τον δίσκο."
             (orchestrator.components:component-id f))))
    (nreverse v)))
