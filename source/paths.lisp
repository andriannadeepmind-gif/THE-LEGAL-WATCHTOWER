;;;; paths.lisp
;;;; Path abstraction layer - Zero hardcoded paths
;;;; All filesystem paths must go through this module

(defpackage #:orchestrator.paths
  (:use :cl)
  (:import-from :alexandria
                #:hash-table-keys)
  (:import-from :uiop
                #:getenv
                #:merge-pathnames*
                #:default-temporary-directory)
  (:export #:resolve-path
           #:register-path
           #:initialize-paths
           #:path-exists-p
           #:*path-registry*
           #:ensure-directory
           #:with-temp-file
           #:make-relative-path
           ;; [0086] ταυτότητα φορτωνόμενου αρχείου (ΟΧΙ ρίζα) — για μητρώα ιδιοκτησίας
           #:current-load-file
           #:+anonymous-load-site+
           #:load-site-attributable-p
           ;; [0086+] Η ΜΙΑ έδρα του μοτίβου store-path (override + τεμπέλικη ρίζα)
           #:define-store-path
           ;; FF1 — Η ΜΙΑ έδρα ρίζας του Ιδρύματος (φορητή)
           #:institution-root
           #:institution-dir))

(in-package :orchestrator.paths)

;;;; ========================================================================
;;;; CONSTANTS
;;;; ========================================================================

(defparameter +default-base-path+ "/app"
  "Deployment default — ΜΟΝΟ τελευταία λύση (docker). Ποτέ ξανά ως σκληρή
   αλήθεια σε runtime path decision εκτός αυτής της έδρας (FF1).")

(defparameter +max-path-components+ 20
  "Maximum number of path components to merge")

;;;; ========================================================================
;;;; FF1 — ΡΙΖΑ ΤΟΥ ΙΔΡΥΜΑΤΟΣ: Η ΜΙΑ ΑΛΗΘΕΙΑ, ΦΟΡΗΤΗ
;;;; ========================================================================
;;;;
;;;; Πριν το FF1: 33 runtime path decisions είχαν το καθένα δικό του literal
;;;; "/app" — μη-φορητό, docker-δεμένο. Τώρα υπάρχει ΜΙΑ έδρα· τα υπόλοιπα
;;;; γίνονται καταναλωτές της. Ιεραρχία επίλυσης (INSTITUTION-ROOT):
;;;;   1. LAWMAX_ROOT        — ρητή παράκαμψη
;;;;   2. ORCHESTRATOR_ROOT  — legacy, τιμάται
;;;;   3. φυσική θέση του κώδικα, ΑΝ υπάρχει στον δίσκο — φορητότητα
;;;;   4. /app               — deployment default, τελευταία λύση

(defparameter +seat-source-file+
  #.(or *compile-file-truename* *load-truename* *load-pathname*)
  "Η ΦΥΣΙΚΗ θέση αυτού του αρχείου, αποτυπωμένη τη ΣΤΙΓΜΗ ΤΗΣ ΜΕΤΑΓΛΩΤΤΙΣΗΣ.
   ΚΑΝΟΝΑΣ ΚΡΙΤΗ (0021): το #. ΒΟΗΘΑ να βρεθεί πού ΧΤΙΣΤΗΚΕ το σύστημα —
   ΔΕΝ αποφασίζει πού ΖΕΙ το Ίδρυμα. Είναι μόνο ΥΠΟΨΗΦΙΟ, όχι έμπιστη ρίζα:
   το fasl μπορεί να μεταφέρθηκε, το checkout να είναι stale. Περνά ΤΟΝ ΙΔΙΟ
   έλεγχο ταυτότητας με κάθε άλλο υποψήφιο.")

(defparameter +institution-sentinels+
  '("orchestrator-cli.asd"
    "deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp")
  "Αρχεία-ΤΑΥΤΟΤΗΤΑ: η ύπαρξη ΟΛΩΝ αποδεικνύει ότι ένας κατάλογος είναι ρίζα
   ΑΥΤΟΥ του LAWMAX — όχι απλώς ένας κατάλογος που τυχαίνει να υπάρχει
   (παλιό/λάθος checkout, stale build root). Η ταυτότητα ΓΕΝΙΑΣ (ποια έκδοση)
   είναι δουλειά του kernel-freeze manifest (FF4)· εδώ: «είναι LAWMAX ρίζα;».")

(defun %nonblank-env (name)
  "Η τιμή env NAME αν δεν είναι NIL/κενή/whitespace, αλλιώς NIL."
  (let ((v (getenv name)))
    (and v (stringp v)
         (plusp (length (string-trim '(#\Space #\Tab #\Newline #\Return) v)))
         v)))

(defun %verified-root (candidate)
  "Ο ΕΛΕΓΧΟΣ ΤΑΥΤΟΤΗΤΑΣ (όχι απλή ύπαρξη): ο CANDIDATE είναι ρίζα LAWMAX
   ΜΟΝΟ αν ΟΛΑ τα sentinel αρχεία υπάρχουν από κάτω του. Επιστρέφει το
   ensure-directory pathname ή NIL. Ρίζα που δεν αποδεικνύεται ⇒ ΔΕΝ
   εμπιστεύεται, ό,τι κι αν είναι η πηγή της (env/asdf/#./default)."
  (when candidate
    (let ((dir (ignore-errors (uiop:ensure-directory-pathname candidate))))
      (when (and dir
                 (every (lambda (s) (probe-file (merge-pathnames* s dir)))
                        +institution-sentinels+))
        dir))))

(defun %compile-time-candidate ()
  "source/paths.lisp → source/ → <root> από το compile-time #. — ΥΠΟΨΗΦΙΟ
   μόνο. Επιστρέφει το pathname (ο έλεγχος ταυτότητας γίνεται χωριστά)."
  (when +seat-source-file+
    (uiop:pathname-parent-directory-pathname
     (uiop:pathname-directory-pathname +seat-source-file+))))

(defun %asdf-runtime-candidate ()
  "Πού φορτώθηκε ΟΝΤΩΣ το .asd αυτού του LAWMAX τη ΣΤΙΓΜΗ ΕΚΤΕΛΕΣΗΣ —
   ΥΠΟΨΗΦΙΟ (πιο αξιόπιστο από το #. γιατί αντανακλά το runtime load), αλλά
   περνά κι αυτό έλεγχο ταυτότητας. NIL αν το σύστημα δεν είναι φορτωμένο."
  (ignore-errors
    (let ((sys (asdf:find-system :orchestrator-cli nil)))
      (and sys (asdf:system-source-directory sys)))))

(defun institution-root ()
  "Η ΜΙΑ αλήθεια για τη ρίζα του Ιδρύματος — με ΕΛΕΓΧΟ ΤΑΥΤΟΤΗΤΑΣ σε ΚΑΘΕ
   υποψήφιο (κανόνας Κριτή 0021: ύπαρξη δεν αρκεί). Σειρά προτεραιότητας:
     1. LAWMAX_ROOT          — ρητή παράκαμψη, ΑΝ περνά ταυτότητα
     2. ORCHESTRATOR_ROOT    — legacy, ΑΝ περνά ταυτότητα
     3. ASDF runtime location — πού φορτώθηκε το .asd, ΑΝ περνά ταυτότητα
     4. compile-time #.       — candidate μόνο, ΑΝ περνά ταυτότητα
     5. /app                 — deployment default, τελευταία λύση (χωρίς
                               ταυτότητα: είναι ο δηλωμένος default, όχι εικασία)
   Ένας ρητός override (1/2) που ΑΠΟΤΥΓΧΑΝΕΙ στην ταυτότητα ΔΕΝ γίνεται
   έμπιστος — προσπερνιέται σιωπηλά προς τον επόμενο αποδεδειγμένο."
  (or (%verified-root (%nonblank-env "LAWMAX_ROOT"))
      (%verified-root (%nonblank-env "ORCHESTRATOR_ROOT"))
      (%verified-root (%asdf-runtime-candidate))
      (%verified-root (%compile-time-candidate))
      (uiop:ensure-directory-pathname +default-base-path+)))

(defun institution-dir (subpath)
  "Namestring καταλόγου/αρχείου κάτω από τη ρίζα. SUBPATH σχετικό, π.χ.
   \"output/\", \"keys/private.pem\". Ο ΜΟΝΟΣ τρόπος να μιλήσει runtime
   κώδικας για θέση κάτω από τη ρίζα (FF1 — κανένα literal /app αλλού)."
  (namestring (merge-pathnames* subpath (institution-root))))

;;;; ========================================================================
;;;; PATH REGISTRY
;;;; ========================================================================

(defparameter *path-registry* (make-hash-table :test 'eq)
  "Central registry of all configured paths")

(defparameter *default-paths* nil
  "Default path configuration")

;;;; ========================================================================
;;;; PATH SECURITY (DARPA-GRADE)
;;;; ========================================================================

(define-condition path-traversal-error (error)
  ((attempted-path :initarg :attempted-path :reader attempted-path)
   (base-path :initarg :base-path :reader base-path))
  (:report (lambda (c s)
             (format s "Path traversal attack blocked: ~A escapes base ~A"
                     (attempted-path c) (base-path c)))))

(defun contains-traversal-p (path-string)
  "Check if path string contains directory traversal sequences"
  (or (search ".." (namestring path-string))
      (search "~" (namestring path-string))  ; Home directory expansion
      (and (> (length (namestring path-string)) 0)
           (char= (char (namestring path-string) 0) #\/))))  ; Absolute path

(defun path-within-base-p (resolved-path base-path)
  "Verify resolved path is within base directory (canonicalized check)"
  (let ((resolved-str (namestring (truename resolved-path)))
        (base-str (namestring (truename base-path))))
    ;; Resolved path must start with base path
    (and (>= (length resolved-str) (length base-str))
         (string= base-str (subseq resolved-str 0 (length base-str))))))

(defun validate-path-component (component base-path)
  "Validate a single path component against traversal attacks
   Signals path-traversal-error if attack detected"
  (let ((comp-str (etypecase component
                    (string component)
                    (pathname (namestring component)))))
    (when (contains-traversal-p comp-str)
      (error 'path-traversal-error
             :attempted-path comp-str
             :base-path base-path))))

;;;; ========================================================================
;;;; PATH RESOLUTION
;;;; ========================================================================

(defun resolve-path (key &rest components)
  "Resolve a path from registry and optional path components.

   DARPA-GRADE: Validates all components against path traversal attacks.
   Rejects: '..' sequences, '~' expansion, absolute paths in components.

   Example: (resolve-path :scripts \"pdf_parser.py\")
            => \"/app/scripts/pdf_parser.py\""
  (declare (type symbol key))
  (declare (type list components))
  (declare (optimize (speed 3) (safety 1)))
  (check-type key symbol)
  (let ((base-path (gethash key *path-registry*)))
    (unless base-path
      (error "Path key ~A not registered. Available keys: ~A"
             key
             (hash-table-keys *path-registry*)))
    (if components
        (progn
          ;; Validate each component against traversal attacks
          (dolist (comp components)
            (validate-path-component comp base-path))
          (let ((resolved (apply #'merge-pathnames*
                                 (reverse (cons base-path
                                               (mapcar #'pathname components))))))
            ;; Double-check: verify resolved path is within base
            ;; (handles edge cases where merge could escape)
            (when (probe-file resolved)
              (unless (path-within-base-p resolved base-path)
                (error 'path-traversal-error
                       :attempted-path resolved
                       :base-path base-path)))
            resolved))
        base-path)))

(defun register-path (key path)
  "Register a path in the global registry"
  (declare (type symbol key))
  (declare (type (or string pathname) path))
  (declare (optimize (speed 3) (safety 1)))
  (check-type key symbol)
  (setf (gethash key *path-registry*)
        (pathname path)))

(defun path-exists-p (key)
  "Check if a path key is registered"
  (declare (type symbol key))
  (declare (optimize (speed 3) (safety 1)))
  (nth-value 1 (gethash key *path-registry*)))

;;;; ========================================================================
;;;; INITIALIZATION
;;;; ========================================================================

(defun initialize-paths (&key (base-dir nil))
  "Initialize path registry with defaults or config-provided values"
  (declare (type (or null string pathname) base-dir))
  (declare (optimize (speed 3) (safety 1)))
  ;; FF1: η ρίζα έρχεται από τη ΜΙΑ έδρα (institution-root) — τέλος στο
  ;; «/app πάντα, getcwd νεκρός κώδικας». Ρητό base-dir υπερισχύει.
  (let ((root (if base-dir
                  (uiop:ensure-directory-pathname base-dir)
                  (institution-root))))
    (setf *default-paths*
          `((:base    . ,(pathname root))
            (:config  . ,(merge-pathnames* "configs/" root))
            (:output  . ,(merge-pathnames* "output/" root))
            (:input   . ,(merge-pathnames* "input/" root))
            (:scripts . ,(merge-pathnames* "scripts/" root))
            (:shapes  . ,(merge-pathnames* "shapes/" root))
            (:temp    . ,(pathname (default-temporary-directory)))
            (:logs    . ,(merge-pathnames* "logs/" root))
            (:data    . ,(merge-pathnames* "data/" root))
            (:cache   . ,(merge-pathnames* "cache/" root))
            (:source  . ,(merge-pathnames* "source/" root))
            (:tests   . ,(merge-pathnames* "tests/" root))))
    
    ;; Register all default paths
    (loop for (key . path) in *default-paths*
          do (register-path key path))
    
    (values *path-registry*)))

;;;; ========================================================================
;;;; UTILITY FUNCTIONS
;;;; ========================================================================

(defun ensure-directory (key &rest components)
  "Ensure directory exists for given path key"
  (declare (type symbol key))
  (declare (type list components))
  (declare (optimize (speed 3) (safety 1)))
  (let ((dir (apply #'resolve-path key components)))
    (ensure-directories-exist dir)
    dir))

(defmacro with-temp-file ((var &key (directory :temp) (prefix "orch-") (suffix ".tmp")) 
                          &body body)
  "Execute body with a temporary file path bound to VAR"
  `(let ((,var (merge-pathnames* 
                (format nil "~A~A~A" 
                        ,prefix 
                        (orchestrator.time:get-unix-timestamp)
                        ,suffix)
                (resolve-path ,directory))))
     (unwind-protect
          (progn ,@body)
       (when (probe-file ,var)
         (delete-file ,var)))))

(defun make-relative-path (key relative-path)
  "Make a relative path from a base key

   DARPA-GRADE: Validates relative-path against path traversal attacks."
  (declare (type symbol key))
  (declare (type (or string pathname) relative-path))
  (declare (optimize (speed 3) (safety 1)))
  (let ((base-path (resolve-path key)))
    ;; Validate against traversal attacks
    (validate-path-component relative-path base-path)
    (merge-pathnames* relative-path base-path)))

;;;; ========================================================================
;;;; MIGRATION UTILITIES
;;;; ========================================================================

(defun migrate-hardcoded-path (old-path)
  "Convert a hardcoded path to path-resolved equivalent.
   For development/migration purposes only."
  (cond
    ((search "/scripts/" old-path) 
     (list :scripts (file-namestring old-path)))
    ((search "/shapes/" old-path)
     (list :shapes (file-namestring old-path)))
    ((search "/output/" old-path)
     (list :output (file-namestring old-path)))
    ((search "/config" old-path)
     (list :config (file-namestring old-path)))
    ((search "/input/" old-path)
     (list :input (file-namestring old-path)))
    (t 
     (warn "Cannot migrate path: ~A" old-path)
     nil)))

;;;; ========================================================================
;;;; INITIALIZE ON LOAD
;;;; ========================================================================

;; Initialize with defaults when loaded
(initialize-paths)


(defparameter +anonymous-load-site+ "<runtime>"
  "[audit#6 / re-review B-5] Η ΜΗ-αποδώσιμη ταυτότητα έδρας εκτός φόρτωσης. ΔΕΝ
   ταυτοποιεί ΜΟΝΑΔΙΚΟ αρχείο — ΚΑΘΕ runtime εγγραφή τη μοιράζεται, άρα ΔΕΝ μπορεί
   να αποδείξει single-ownership. Τα μητρώα εδρών (register-command/-capability)
   την αντιμετωπίζουν fail-closed: ανώνυμο site παίρνει ΝΕΑ έδρα αλλά ΠΟΤΕ δεν
   επαναδιεκδικεί υπάρχουσα (αλλιώς δύο ανώνυμες εγγραφές θα αντικαθιστούσαν σιωπηλά).")

(defun current-load-file ()
  "[0086+] Ταυτότητα έδρας του αρχείου που φορτώνεται/μεταγλωττίζεται ΤΩΡΑ:
   «γονικός-κατάλογος/όνομα» ΧΩΡΙΣ type — το ASDF output translation διατηρεί
   τη δομή καταλόγων, άρα fasl ≡ source (ίδια ταυτότητα, κανένα ψευδο-collision
   σε hot reload) ΚΑΙ δύο ομώνυμα αρχεία σε ΑΛΛΟΥΣ καταλόγους διακρίνονται.
   +anonymous-load-site+ εκτός φόρτωσης — ΜΗ-αποδώσιμη ταυτότητα (βλ. εκεί).
   ΤΑΥΤΟΤΗΤΑ ΜΟΝΟ, ποτέ ρίζα/διαδρομή (FF1 ⑭: το load-truename ζει ΜΟΝΟ εδώ)."
  (let ((p (or *load-truename* *compile-file-truename*)))
    (if p
        (format nil "~A/~A"
                (or (car (last (pathname-directory p))) "")
                (pathname-name p))
        +anonymous-load-site+)))

(defun load-site-attributable-p (site)
  "Αποδίδεται το SITE σε ΜΟΝΑΔΙΚΟ αρχείο-έδρα; (δηλ. ΔΕΝ είναι το ανώνυμο runtime
   sentinel). ΜΟΝΟ αποδώσιμο site μπορεί να επαναδιεκδικήσει τη δική του έδρα
   (idempotent reload ίδιου αρχείου)· ανώνυμο ΠΟΤΕ — έτσι η σιωπηλή αντικατάσταση
   από δύο μη-αποδώσιμες runtime εγγραφές γίνεται ΔΟΜΙΚΑ αδύνατη."
  (and (stringp site) (string/= site +anonymous-load-site+)))

(defmacro define-store-path (accessor var relpath &optional (doc ""))
  "[0086+] Η ΜΙΑ έδρα του μοτίβου «διαρκές store κάτω από τη ρίζα»: ορίζει
   override-var (NIL ⇒ κανονική θέση· τα gates το δένουν σε tmp) + ΤΕΜΠΕΛΙΚΟ
   accessor μέσω institution-root (ποτέ παγωμένο από load/saved-image/ξένο cwd).
   Πριν: το ίδιο σχήμα copy-paste ×6 — διπλή έδρα έννοιας, νεκρή εδώ."
  `(progn
     (defvar ,var nil
       ,(format nil "Override του store (gates→tmp). NIL ⇒ ~A υπό institution-root (τεμπέλικα). ~A"
                relpath doc))
     (defun ,accessor ()
       ,(format nil "Η ΜΙΑ θέση του store ~A (override ή institution-root). ~A" relpath doc)
       (or ,var (merge-pathnames ,relpath (institution-root))))))
