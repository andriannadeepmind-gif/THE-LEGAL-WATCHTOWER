;;;; source/what-if.lisp
;;;; ============================================================================
;;;; ΠΡΟΤΑΣΗ ΑΛΛΑΓΗΣ + WHAT-IF — «τι θα συμβεί ΑΝ», πριν συμβεί
;;;; ============================================================================
;;;;
;;;; Κάθε αλλαγή είναι FIRST-CLASS αντικείμενο (change-proposal) και πριν από
;;;; κάθε υιοθέτηση τρέχει ο προσομοιωτής what-if: dry-run ανάλυση επίπτωσης
;;;; που ΚΑΤΑΝΑΛΩΝΕΙ τα πέντε στρώματα αυτοεπίγνωσης — ταυτότητα, ικανότητες,
;;;; συμβόλαια, συστατικά (hashes), ίχνη/αποδείξεις εκτέλεσης — και παράγει
;;;; ΔΟΜΗΜΕΝΟ αντικείμενο (όχι πρόζα) που τρέφει την απόφαση υιοθέτησης.
;;;; Καμία εικασία: ό,τι δεν επιλύεται, βγαίνει ΕΛΛΕΙΨΗ που μπλοκάρει.

(defpackage :orchestrator.whatif
  (:use :cl)
  (:export #:declare-proposal! #:find-proposal #:all-proposals
           #:proposal-id #:proposal-type #:proposal-purpose
           #:proposal-files #:proposal-symbols #:proposal-capabilities
           #:proposal-improvement #:proposal-risk #:proposal-legal-critical
           #:proposal-approvals #:proposal-sandbox #:proposal-rollback
           #:proposal-acceptance #:proposal-old-hashes
           #:what-if #:report-get #:load-proposal-file!))

(in-package :orchestrator.whatif)

(defstruct (change-proposal (:constructor %make-proposal)
                            (:conc-name proposal-))
  id            ; string — μοναδικό
  type          ; :knowledge :contract :component :capability :policy :code :corpus :article-identity
  purpose       ; γιατί — δηλωμένος σκοπός
  files         ; αρχεία που αγγίζει (σχετικές διαδρομές)
  symbols       ; κρίσιμες συναρτήσεις/σύμβολα που αγγίζει (strings)
  capabilities  ; ικανότητες που δηλώνει ότι αφορά
  improvement   ; plist (:metric … :baseline … :target …) — ΤΙ βελτιώνει, μετρήσιμα
  risk          ; :low :medium :high
  legal-critical
  approvals     ; ποιες εγκρίσεις ΦΕΡΕΙ ήδη: (:creator-cli) / (:policy "κλάση") / ()
  sandbox       ; σχέδιο σκιάς (string — πώς δοκιμάζεται χωρίς μόλυνση)
  rollback      ; σχέδιο αναστροφής (plist :restores :files :verify) ή NIL = ΜΠΛΟΚΟ
  acceptance    ; κριτήρια αποδοχής (λίστα strings)
  old-hashes)   ; δηλωμένα hashes των αρχείων ΟΠΩΣ τα ξέρει η πρόταση (alist)

(defvar *proposals* '())

(defun declare-proposal! (id &rest keys &key type purpose files symbols
                                             capabilities improvement risk
                                             legal-critical approvals sandbox
                                             rollback acceptance old-hashes)
  (declare (ignore type purpose files symbols capabilities improvement risk
                   legal-critical approvals sandbox rollback acceptance old-hashes))
  (let ((p (apply #'%make-proposal :id (string id) keys)))
    (setf *proposals*
          (append (remove (string id) *proposals*
                          :key #'proposal-id :test #'string=)
                  (list p)))
    p))

(defun find-proposal (id)
  (find (string id) *proposals* :key #'proposal-id :test #'string=))

(defun all-proposals () (copy-list *proposals*))

(defun load-proposal-file! (path)
  "ΕΞΩΤΕΡΙΚΗ ΠΡΟΤΑΣΗ από αρχείο: data-only ανάγνωση (*read-eval* NIL,
   keyword package) ενός plist (:id … :type … :rollback …) και δήλωσή του
   στο μητρώο. ΑΣΦΑΛΕΙΑ: μόνο .sexp, μόνο κάτω από τους εγκεκριμένους
   φακέλους της εγκατάστασης (output/, deployment/) — ποτέ path traversal.
   Επιστρέφει (values proposal-id λόγος-άρνησης)."
  (let* ((root (uiop:getcwd))
         (true (ignore-errors (truename path))))
    (cond
      ((null true) (values nil (format nil "το αρχείο «~A» δεν υπάρχει" path)))
      ((not (string-equal "sexp" (pathname-type true)))
       (values nil "δεκτά ΜΟΝΟ αρχεία .sexp — τίποτα εκτελέσιμο"))
      ((not (or (uiop:subpathp true (merge-pathnames "output/" root))
                (uiop:subpathp true (merge-pathnames "deployment/" root))))
       (values nil "εκτός εγκεκριμένων φακέλων (output/, deployment/) — απορρίπτεται"))
      (t
       (let ((form (handler-case
                       (with-open-file (s true :external-format :utf-8)
                         (let ((*read-eval* nil)
                               (*package* (find-package :keyword)))
                           (read s nil nil)))
                     (error (e) (return-from load-proposal-file!
                                  (values nil (format nil "μη αναγνώσιμα δεδομένα: ~A" e)))))))
         (unless (and (listp form) (getf form :id))
           (return-from load-proposal-file!
             (values nil "περιμένω plist με :id — δομημένη πρόταση, όχι ελεύθερο κείμενο")))
         (flet ((s* (x) (and x (string x)))
                (l* (x) (mapcar #'string (if (listp x) x (list x)))))
           (declare-proposal! (s* (getf form :id))
            :type (let ((ty (getf form :type)))
                    (if (member ty '(:knowledge :contract :component :capability
                                     :policy :code :corpus :article-identity))
                        ty :code))
            :purpose (s* (getf form :purpose))
            :files (l* (getf form :files))
            :symbols (l* (getf form :symbols))
            :capabilities (l* (getf form :capabilities))
            :improvement (getf form :improvement)
            :risk (getf form :risk)
            :legal-critical (getf form :legal-critical)
            :approvals (getf form :approvals)
            :sandbox (s* (getf form :sandbox))
            :rollback (getf form :rollback)
            :acceptance (l* (getf form :acceptance))
            :old-hashes (getf form :old-hashes)))
         (values (string (getf form :id)) nil))))))

(defun %affected-capabilities (proposal)
  "Άμεσες ικανότητες: δηλωμένες + όσων τα συμβόλαια/πάροχοι ταιριάζουν στα
   σύμβολα της πρότασης."
  (let ((caps (copy-list (proposal-capabilities proposal))))
    (dolist (s (proposal-symbols proposal))
      (let ((c (orchestrator.contracts:find-contract s)))
        (when (and c (orchestrator.contracts:contract-capability c))
          (pushnew (orchestrator.contracts:contract-capability c) caps
                   :test #'string-equal)))
      (dolist (cap (orchestrator.self-model:all-capabilities))
        (when (member s (orchestrator.self-model:capability-functions cap)
                      :test #'string-equal)
          (pushnew (orchestrator.self-model:capability-name cap) caps
                   :test #'string-equal))))
    caps))

(defun what-if (proposal)
  "Ο ΠΡΟΣΟΜΟΙΩΤΗΣ: δομημένη αναφορά επίπτωσης — plist, ΟΧΙ πρόζα. Καταναλώνει
   μητρώο συστατικών (φρέσκο), συμβόλαια, αιτιώδη γράφο, ίχνη εκτέλεσης."
  (orchestrator.component-scan:build-component-registry!)
  (let* ((direct (%affected-capabilities proposal))
         (all-caps direct) (gates '()) (contracts '()) (missing '())
         (file-impact '()))
    ;; μεταβατικό κλείσιμο + ελάχιστο regression από τον αιτιώδη γράφο
    (dolist (c direct)
      (multiple-value-bind (caps gs) (orchestrator.self-model:capability-impact c)
        (dolist (k caps)
          (pushnew (orchestrator.self-model:capability-name k) all-caps
                   :test #'string-equal))
        (dolist (g gs) (pushnew g gates :test #'string=))))
    ;; συμβόλαια των επηρεαζόμενων ικανοτήτων + τα τεστ τους στο regression
    (dolist (cap all-caps)
      (dolist (c (orchestrator.contracts:contracts-for-capability cap))
        (pushnew (orchestrator.contracts:contract-name c) contracts :test #'string=)
        (dolist (tst (orchestrator.contracts:contract-tests c))
          (pushnew tst gates :test #'string=))))
    ;; ταυτότητα συστατικών: αρχεία με παλιό/νέο hash — αταυτοποίητο = ΕΛΛΕΙΨΗ
    (dolist (f (proposal-files proposal))
      (let* ((comp (orchestrator.components:find-component (format nil "file:~A" f)))
             (now (and comp (orchestrator.components:component-hash comp)))
             (declared (cdr (assoc f (proposal-old-hashes proposal) :test #'string=))))
        (cond
          ((null comp)
           (push (format nil "αρχείο «~A» ΧΩΡΙΣ ταυτότητα συστατικού" f) missing))
          (t (push (list :file f :old-hash now
                         :declared-hash declared
                         :stale (and declared (string/= declared now))
                         :system (orchestrator.components:component-parent comp)
                         :packages (orchestrator.components:meta-get comp :defpackages))
                   file-impact)))))
    ;; σύμβολα: επιλύσιμα στη ζωντανή εικόνα ή ΕΛΛΕΙΨΗ
    (dolist (s (proposal-symbols proposal))
      (unless (orchestrator.component-scan:resolve-critical-symbol s :orchestrator.cli)
        (push (format nil "σύμβολο «~A» δεν επιλύεται στη ζωντανή εικόνα" s) missing)))
    ;; runtime προέλευση: ίχνη/αποδείξεις/συμπεράσματα που αγγίζονται
    (let* ((events (orchestrator.trace:all-events))
           (touched (remove-if-not
                     (lambda (ev)
                       (or (member (orchestrator.trace:tevent-symbol ev)
                                   (proposal-symbols proposal) :test #'equal)
                           (member (orchestrator.trace:tevent-source ev)
                                   (proposal-files proposal) :test #'equal)))
                     events))
           (stale-proofs (remove-if-not
                          (lambda (ev) (eq (orchestrator.trace:tevent-kind ev) :conclusion))
                          touched)))
      ;; legal-critical + έγκριση + rollback + βελτίωση
      (let* ((lc-contracts (remove-if-not
                            (lambda (n)
                              (let ((c (orchestrator.contracts:find-contract n)))
                                (and c (orchestrator.contracts:contract-legal-critical c))))
                            contracts))
             (legal-critical (or (proposal-legal-critical proposal)
                                 (eq (proposal-type proposal) :article-identity)
                                 (and lc-contracts t)))
             (needs-human (or legal-critical
                              (eq (proposal-risk proposal) :high)))
             (identity-debt-baseline
               (length (orchestrator.trace:events-where :kind :identity-debt
                                                        :limit 1000))))
        (unless (proposal-improvement proposal)
          (push "ΧΩΡΙΣ δηλωμένη μετρήσιμη βελτίωση — αλλαγή, όχι αυτοβελτίωση" missing))
        (unless (proposal-rollback proposal)
          (push "ΧΩΡΙΣ σχέδιο rollback" missing))
        (when (and stale-proofs
                   (not (member "revalidation" (proposal-acceptance proposal)
                                :test (lambda (a b) (search a b)))))
          (push (format nil "~D αποδείξεις/συμπεράσματα αγγίζονται ΧΩΡΙΣ σχέδιο επανεπικύρωσης"
                        (length stale-proofs))
                missing))
        (when (eq (proposal-type proposal) :article-identity)
          (unless (orchestrator.contracts:find-contract "article-identity-management")
            (push "μετάβαση ταυτότητας άρθρων ΧΩΡΙΣ το συμβόλαιό της" missing))
          (unless (member :creator-cli (proposal-approvals proposal))
            (push "μετάβαση ταυτότητας άρθρων ΧΩΡΙΣ ανθρώπινη έγκριση" missing)))
        (dolist (fi file-impact)
          (when (getf fi :stale)
            (push (format nil "ΞΕΠΕΡΑΣΜΕΝΟ hash: η πρόταση ξέρει άλλο «~A» από τον δίσκο"
                          (getf fi :file))
                  missing)))
        (list :proposal (proposal-id proposal)
              :type (proposal-type proposal)
              :direct-impact direct
              :downstream-impact (set-difference all-caps direct :test #'string-equal)
              :contracts contracts
              :file-impact file-impact
              :affected-traces (mapcar #'orchestrator.trace:tevent-id touched)
              :stale-proofs (mapcar #'orchestrator.trace:tevent-id stale-proofs)
              :regression (sort gates #'string<)
              :legal-critical legal-critical
              :needs-human needs-human
              :identity-debt-baseline identity-debt-baseline
              :rollback-feasible (and (proposal-rollback proposal) t)
              :improvement (proposal-improvement proposal)
              :missing (nreverse missing)
              :recommendation
              (cond (missing :denied)
                    ((and needs-human
                          (not (or (member :creator-cli (proposal-approvals proposal))
                                   (find :policy (proposal-approvals proposal)
                                         :key (lambda (a) (if (consp a) (car a) a))))))
                     :requires-human)
                    (t :allowed)))))))

(defun report-get (report key) (getf report key))
