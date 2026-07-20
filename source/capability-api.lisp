;;;; source/capability-api.lisp
;;;; ============================================================================
;;;; CAPABILITY API PROJECTION — transport-agnostic προβολή της ΜΙΑΣ έδρας
;;;; ============================================================================
;;;;
;;;; Η προβολή που μετατρέπει ένα αίτημα (path + query key/value strings) σε κλήση
;;;; δυνατότητας: `/api/<name>` → coerce query σε typed args (κατά το δηλωμένο
;;;; συμβόλαιο) → invoke-capability → αποτέλεσμα. Καμία εξάρτηση από HTTP/MCP/CLI:
;;;; ο HTTP cockpit, το MCP-plug και το CLI είναι ΛΕΠΤΑ όρια μεταφοράς που καλούν
;;;; ΑΥΤΗ. Έτσι η δρομολόγηση+coercion+σφάλματα ζουν ΜΙΑ φορά, όχι ανά επιφάνεια.
;;;;
;;;; Η query είναι πάντα strings (HTTP)· εδώ γίνεται η ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ μετατροπή
;;;; σε τύπους κατά το συμβόλαιο — αποτυχία coercion = 400 (fail-closed), ποτέ
;;;; σιωπηλή αποδοχή λάθος τύπου.
;;;; ============================================================================

(defpackage :orchestrator.capability-api
  (:use :cl :orchestrator.capability)
  (:export #:*api-prefix* #:api-dispatch #:coerce-args #:api-catalog
           #:api-status #:api-payload))

(in-package :orchestrator.capability-api)

(defparameter *api-prefix* "/api/"
  "Το πρόθεμα κάτω από το οποίο κάθε δυνατότητα εκτίθεται ως /api/<name>.")

(defun %prefixp (prefix s)
  (and (>= (length s) (length prefix))
       (string= prefix s :end2 (length prefix))))

(defun %query-get (query key)
  "Τιμή (string) του KEY (string) στη QUERY (alist string.string), ή NIL."
  (cdr (assoc key query :test #'string=)))

(define-condition coercion-error (capability-error) ())

(defun %coerce-one (cap pname ptype s)
  "Μετατρέπει το string S στον τύπο PTYPE. Αποτυχία ⇒ coercion-error (→400)."
  (flet ((bad (want)
           (error 'coercion-error :cap (capability-name cap)
                  :reason (format nil "όρισμα ~A: μη έγκυρο ~A (~S)" pname want s))))
    (case ptype
      (:string  s)
      ;; [re-review adv2-F2] :keyword ΠΡΕΠΕΙ να παράγει keyword — το %type-ok-p ελέγχει
      ;; keywordp, άρα το παλιό «κράτα string» αποτύγχανε ΠΑΝΤΑ στο %check-params (400 σε
      ;; κάθε :keyword param). Τώρα intern-άρεται (upcased, όπως ο reader σε CLI/MCP), ώστε
      ;; coerce∘type-ok να ταιριάζει σε ΚΑΘΕ επιφάνεια. ΣΗΜΕΙΩΣΗ: interns στο keyword
      ;; package (bounded από request size)· :keyword παραμένει controlled-vocabulary param.
      (:keyword (intern (string-upcase s) :keyword))
      (:any     s)
      (:integer (or (ignore-errors (parse-integer s :junk-allowed nil)) (bad :integer)))
      ;; [0094]/Phase 1 commit 2A: ο :number κλάδος ΔΙΑΓΡΑΦΗΚΕ — 0 capability δήλωνε
      ;; :number-typed param (νεκρό contract). Το read-from-string→parse-number sink
      ;; καταργήθηκε ΜΕ ΔΙΑΓΡΑΦΗ, όχι νέα numeric έδρα. Μελλοντικό αριθμητικό param =
      ;; ρητή capability με schema/owner/fixtures (integer/quantity/score — όχι γενικό «number»).
      ;; Η bidirectional param-type gate (tests/param-type-coercion-gate) το επιβάλλει.
      (:boolean (cond ((member (string-downcase s) '("true" "1" "yes" "ναι") :test #'string=) t)
                      ((member (string-downcase s) '("false" "0" "no" "όχι" "οχι") :test #'string=) nil)
                      (t (bad :boolean))))
      ;; [audit#7] FAIL-CLOSED: άγνωστος τύπος ΔΕΝ υποβαθμίζεται σιωπηλά σε string
      ;; (το παλιό «(t s)»). Η register-capability εγγυάται ptype ∈ +param-types+, άρα
      ;; κάθε τύπος έχει ρητό κλάδο εδώ· ένας τύπος χωρίς κλάδο = δομικό σφάλμα, όχι σιωπή.
      (t (error 'coercion-error :cap (capability-name cap)
                :reason (format nil "άγνωστος param-type ~S — καμία coercion (fail-closed)" ptype))))))

(defun coerce-args (cap query)
  "QUERY (alist string.string) → args plist τυποποιημένο κατά το συμβόλαιο του CAP.
   Μόνο δηλωμένα ορίσματα περνούν (extra query keys αγνοούνται)· λείπον υποχρεωτικό
   το πιάνει το invoke-capability· λάθος τύπος ⇒ coercion-error εδώ."
  (loop for spec in (capability-params cap)
        for pname = (param-name spec)
        for ptype = (param-type spec)
        for s = (%query-get query (string-downcase (symbol-name pname)))
        when s
          append (list pname (%coerce-one cap pname ptype s))))

(defun api-dispatch (path query &key require-trust)
  "Δρομολόγηση ΕΝΟΣ αιτήματος. Επιστρέφει (values STATUS PAYLOAD):
     :not-api                       — δεν είναι /api/… (ο μεταφορέας σερβίρει αλλού)
     200 (:result <αποτέλεσμα>)     — επιτυχία
     403 (:error …)                 — REQUIRE-TRUST και η δυνατότητα δεν είναι :trusted
     404 (:error …)                 — άγνωστη δυνατότητα
     400 (:error … :capability n)   — παράβαση συμβολαίου (λείπον/λάθος τύπος)
     500 (:error …)                 — απρόβλεπτο σφάλμα της domain έδρας
   Καμία εξαίρεση δεν διαφεύγει (fail-closed, ίδια σε κάθε επιφάνεια).

   REQUIRE-TRUST t ⇒ η ΔΟΜΙΚΗ επιβολή «κανένα advisor/LLM στο trusted path» για
   ΑΥΤΗ την επιφάνεια: μια μη-:trusted δυνατότητα ΔΕΝ εκτελείται (403) — δεν
   φτάνει καν στο :fn. Ο trusted cockpit το περνά t· μια ρητά advisor projection
   το αφήνει nil. Η άμυνα είναι διπλή: pre-check εδώ + :require-trust στο
   invoke-capability (η έδρα αρνείται ξανά)."
  (if (not (%prefixp *api-prefix* path))
      (values :not-api nil)
      (let* ((name-part (subseq path (length *api-prefix*)))
             (capname (and (plusp (length name-part))
                           (intern (string-upcase name-part) :keyword)))
             (cap (and capname (find-capability capname))))
        (cond
          ((null cap)
           (values 404 (list :error "άγνωστη δυνατότητα" :name name-part)))
          ((and require-trust (not (trusted-capability-p cap)))
           (values 403 (list :error "advisor-only δυνατότητα σε trusted επιφάνεια — άρνηση"
                             :capability (string-downcase (symbol-name capname))
                             :trust (string-downcase (symbol-name (capability-trust cap))))))
          (t
           (handler-case
               (let ((result (invoke-capability capname (coerce-args cap query)
                                                :require-trust require-trust)))
                 (values 200 (list :result result
                                   :capability (string-downcase (symbol-name capname))
                                   :trust (string-downcase (symbol-name (capability-trust cap))))))
             (capability-error (e)
               (values 400 (list :error (capability-error-reason e)
                                 :capability (string-downcase (symbol-name capname)))))
             (error (e)
               (values 500 (list :error (format nil "εσωτερικό σφάλμα: ~A" e)
                                 :capability (string-downcase (symbol-name capname)))))))))))

(defun api-catalog (&key require-trust)
  "Αυτο-περιγραφή: δυνατότητες ως δεδομένα (για UI/MCP tools/list).
   (values 200 (:capabilities ((:name … :summary … :trust … :proof … :params …) …))).
   REQUIRE-TRUST t ⇒ μια trusted επιφάνεια ΔΕΝ διαφημίζει advisor δυνατότητες
   που θα αρνιόταν έτσι κι αλλιώς (καμία διαρροή ύπαρξης· ίδια στάση με api-dispatch)."
  (values
   200
   (list :capabilities
         (mapcar
          (lambda (c)
            (list :name (string-downcase (symbol-name (capability-name c)))
                  :summary (capability-summary c)
                  :trust (string-downcase (symbol-name (capability-trust c)))
                  :proof (and (capability-proof c) t)
                  :params (mapcar (lambda (p)
                                    (list :name (string-downcase (symbol-name (param-name p)))
                                          :type (string-downcase (symbol-name (param-type p)))
                                          :required (and (param-required-p p) t)))
                                  (capability-params c))))
          (if require-trust
              (remove-if-not #'trusted-capability-p (all-capabilities))
              (all-capabilities))))))
