;;;; systems/orchestrator-model/article.lisp
;;;; ARTICLE class definition with MOP hooks

(in-package :orchestrator.model)

;;; ============================================================================
;;; ARTICLE CLASS
;;; ============================================================================

(defclass article ()
  ((number
    :accessor article-number
    :initarg :number
    :type integer
    :documentation "Article number (1-120 for Greek Constitution)")

   (label
    :accessor article-label
    :initarg :label
    :initform nil
    :documentation "Full article label preserving any letter suffix (e.g. '70Α').
                    NIL for plain numeric articles; used so lettered articles do
                    not collide with their base number in filenames/URIs.")

   (identity-segment
    :reader article-identity
    :initform nil
    :documentation "[0088 Φ6γ-Δ³] TYPED ταυτότητα άρθρου από την έδρα
                    orchestrator.identity — ΠΑΡΑΓΩΓΗ, ΟΧΙ injectable:
                    ΚΑΝΕΝΑ initarg, ΚΑΝΕΝΑ δημόσιο setf· μεταβάλλεται ΜΟΝΟ
                    μέσω number/label (τα :after hooks επανυπολογίζουν από
                    την έδρα). Άρθρο με δεμένο number ΧΩΡΙΣ υπολογίσιμη
                    ταυτότητα ΔΕΝ κατασκευάζεται (typed σφάλμα — unresolved
                    υλικό = καραντίνα, ποτέ article). NIL ΜΟΝΟ στο εμβρυϊκό
                    στάδιο (number ΚΑΙ label αδέσμευτα)· κάθε προβολή πάνω
                    σε NIL σκάει fail-closed.")

   (title
    :accessor article-title
    :initarg :title
    :type string
    :initform ""
    :documentation "Article title in Greek")
   
   (content
    :accessor article-content
    :initarg :content
    :type string
    :initform ""
    :documentation "Full article text")
   
   (state
    :accessor article-processing-state
    :initarg :state
    :type orchestrator.spec:article-state
    :initform :queued
    :documentation "Current processing state")
   
   (eli-uri
    :accessor article-eli-uri
    :type string
    :documentation "European Legislation Identifier")
   
   (rdf-turtle
    :accessor article-rdf-turtle
    :type (or null string)
    :initform nil
    :documentation "Generated RDF in Turtle format")
   
   (json-ld
    :accessor article-json-ld
    :type (or null string)
    :initform nil
    :documentation "Generated JSON-LD representation")
   
   (html
    :accessor article-html
    :type (or null string)
    :initform nil
    :documentation "AI-optimized HTML with RDFa")
   
   (blake3-hash
    :accessor article-hash
    :type (or null string)
    :initform nil
    :documentation "Blake3 hash of content")
   
   (blockchain-proof
    :accessor article-blockchain-proof
    :type list
    :initform nil
    :documentation "List of blockchain transaction hashes")
   
   (errors
    :accessor article-errors
    :initform nil
    :documentation "Error log for this article")
   
   (retry-count
    :accessor article-retry-count
    :initform 0
    :type integer
    :documentation "Number of processing retries")
   
   (metadata
    :accessor article-metadata
    :initarg :metadata
    :initform nil
    :type list
    :documentation "Additional metadata as plist"))
  (:metaclass article-class)
  (:documentation "Legal article with full processing metadata"))

(defun %article-identity-segment-for (label number)
  "Το typed identity segment για LABEL (ή, χωρίς label, για κανονικό NUMBER
   1..9999· συνθετικός αριθμός χωρίς label ⇒ NIL — δηλωμένο identity-debt).
   Άκυρο label ⇒ orchestrator.spec:validation-error (το δημόσιο συμβόλαιο)."
  (cond
    (label
     (handler-case
         (multiple-value-bind (base ord)
             (orchestrator.identity:parse-article-label (string label))
           (orchestrator.identity:article-segment base ord))
       (orchestrator.identity:identity-parse-error (e)
         (error 'orchestrator.spec:validation-error
                :message (princ-to-string e)))))
    ((and (integerp number) (<= 1 number 9999))
     (orchestrator.identity:article-segment number 0))
    (t nil)))

(defun article-identity-segment (number &optional suffix-or-label &key context)
  "[0088 Φ6γ-Δ] Η ΜΙΑ δημόσια παραγωγή typed segment από raw ζεύγος
   (NUMBER, SUFFIX-OR-LABEL) στα όρια των μοντέλων (FRBR κ.λπ.):
   — πλήρες label («5Α») ⇒ parse από την έδρα ταυτότητας·
   — γυμνό επίθημα («Α») ⇒ ο NUMBER ΕΙΝΑΙ η αληθινή βάση (συμβόλαιο των
     καλούντων από το [0050]#2 — δηλωμένο αφρούρητο υπόλοιπο: συνθετικός
     με γυμνό επίθημα δεν διακρίνεται μηχανικά εδώ)·
   — κενό ⇒ segment κανονικού αριθμού 1..9999, αλλιώς NIL (δηλωμένο debt).
   Με CONTEXT (string): το NIL γίνεται typed σφάλμα ΕΔΩ, στην έδρα — οι
   καλούντες που απαιτούν νόμιμη ταυτότητα δεν ξαναγράφουν φρουρό.
   Άκυρη είσοδος ⇒ orchestrator.spec:validation-error — ποτέ σιωπηλά."
  (let* ((s (and suffix-or-label (string suffix-or-label)))
         (seg (if (and s (plusp (length s)))
                  (%article-identity-segment-for
                   (if (char<= #\0 (char s 0) #\9) s (format nil "~D~A" number s))
                   nil)
                  (%article-identity-segment-for nil number))))
    (or seg
        (and context
             (error 'orchestrator.spec:validation-error
                    :message (format nil "~A: άρθρο χωρίς νόμιμη ταυτότητα (number=~S suffix=~S)"
                                     context number suffix-or-label))))))

(defun segment-uri-id (seg)
  "Η ΜΙΑ προβολή typed segment → UNPADDED δημόσιο id («5», «5Α») — καμία
   inline επανάληψη του κανόνα suffix rendering (κριτής B1)."
  (format nil "~D~A" (second seg)
          (orchestrator.identity:ordinal-suffix (third seg) :sequence :upper)))

(defun segment-file-id (seg)
  "Η ΜΙΑ προβολή typed segment → PADDED id αρχείων/eIds («005», «005Α»)."
  (format nil "~3,'0D~A" (second seg)
          (orchestrator.identity:ordinal-suffix (third seg) :sequence :upper)))

(defun synthetic-article-number (base ord)
  "[Δ³-κριτής A] Η ΜΙΑ έδρα του συνθετικού σχήματος αποσαφήνισης lettered
   άρθρων: base×1000+ord (5Α ⇒ 5001, 70Α ⇒ 70001, 272Ε ⇒ 272005) — ο
   json-adapter την ΚΑΤΑΝΑΛΩΝΕΙ, δεν την ξαναορίζει."
  (+ (* base 1000) ord))

(defun %set-identity-slot! (obj label number context)
  "[0088 Φ6γ-Δ³] Ο ΜΟΝΑΔΙΚΟΣ δίαυλος εγγραφής identity slot (article ΚΑΙ
   IIR): υπολογίζει από την έδρα βάσει (label, number)· ΔΕΜΕΝΟ number
   χωρίς υπολογίσιμη ταυτότητα ⇒ typed σφάλμα (unresolved = καραντίνα)·
   [κριτής A#2] ΣΥΝΟΧΗ number↔ταυτότητα: με label παρόν, το number
   πρέπει να είναι η ΒΑΣΗ ή ο συνθετικός της έδρας — αποκλίνον ζεύγος
   (6001,«5Α») δεν μπορεί να ΥΠΑΡΞΕΙ, ούτε με setf ούτε με reinitialize."
  (let ((seg (%article-identity-segment-for label number)))
    (when (and number (null seg))
      (error 'orchestrator.spec:validation-error
             :message (format nil "~A χωρίς νόμιμη ταυτότητα: number=~S label=~S — συνθετικός αριθμός απαιτεί label· unresolved υλικό = καραντίνα"
                              context number label)))
    (when (and number seg label)
      (let ((base (second seg)) (ord (third seg)))
        (unless (or (= number base)
                    (= number (synthetic-article-number base ord)))
          (error 'orchestrator.spec:validation-error
                 :message (format nil "~A: ασυνεπές ζεύγος number=~D ↔ label=~S (ταυτότητα βάση=~D θέση=~D) — νόμιμα: ~D ή ~D"
                                  context number label base ord
                                  base (synthetic-article-number base ord))))))
    (setf (slot-value obj 'identity-segment) seg)))

(defun %recompute-article-identity! (article)
  (%set-identity-slot! article
                       (and (slot-boundp article 'label) (article-label article))
                       (and (slot-boundp article 'number) (article-number article))
                       "article"))

(defmethod shared-initialize :after ((article article) slot-names &key)
  "[0088 Φ6γ-Δ³ + κριτής A#3] Η typed ταυτότητα υπολογίζεται σε ΚΑΘΕ
   δίαυλο αρχικοποίησης του CLOS πρωτοκόλλου — make-instance,
   reinitialize-instance, change-class, update-instance-* — όχι μόνο στη
   γέννηση: stale ταυτότητα μέσω reinitialize είναι δομικά αδύνατη.
   Κανένα :identity initarg (άγνωστο ⇒ σφάλμα CLOS), κανένα
   &allow-other-keys, κανένα δημόσιο setf."
  (declare (ignore slot-names))
  (%recompute-article-identity! article))

(defmethod (setf article-number) :after (new-number (article article))
  "Η ταυτότητα ΠΑΡΑΚΟΛΟΥΘΕΙ το number — stale/ασυνεπές δομικά αδύνατο."
  (declare (ignore new-number))
  (%recompute-article-identity! article))

(defmethod (setf article-label) :after (new-label (article article))
  "Η ταυτότητα ΠΑΡΑΚΟΛΟΥΘΕΙ το label — stale/ασυνεπές δομικά αδύνατο."
  (declare (ignore new-label))
  (%recompute-article-identity! article))

(defmethod print-object ((article article) stream)
  "Print article in readable format"
  (print-unreadable-object (article stream :type t :identity t)
    (format stream "~D:~A [~A]"
            (if (slot-boundp article 'number)
                (article-number article)
                "?")
            (if (slot-boundp article 'title)
                (article-title article)
                "?")
            (if (slot-boundp article 'state)
                (article-processing-state article)
                "?"))))

;;; ============================================================================
;;; STATE TRANSITION
;;; ============================================================================

(defparameter *valid-transitions*
  '((:queued . (:parsing :failed))
    (:parsing . (:generating :failed))
    (:generating . (:validating :failed))
    (:validating . (:reviewing :failed))
    (:reviewing . (:hashing :rejected))
    (:hashing . (:anchoring :failed))
    (:anchoring . (:deploying :failed))
    (:deploying . (:live :failed)))
  "Valid state transitions for articles")

(defmethod orchestrator.spec:valid-transition-p ((from symbol)
                                                  (to symbol))
  "Check if state transition is valid"
  (member to (cdr (assoc from *valid-transitions*))))

(defmethod orchestrator.spec:transition ((article article) new-state &optional metadata)
  "Transition article to new state with validation"
  (let ((current (article-processing-state article)))
    (unless (orchestrator.spec:valid-transition-p current new-state)
      (error 'orchestrator.spec:orchestrator-error
             :component 'state-machine
             :message (format nil "Invalid transition: ~A → ~A" current new-state)
             :article (when (slot-boundp article 'number)
                       (article-number article))))

    (setf (article-processing-state article) new-state)
    
    (when metadata
      (push metadata (article-errors article)))
    
    new-state))

;;; ============================================================================
;;; ARTICLE UTILITIES
;;; ============================================================================

;;; ----------------------------------------------------------------------------
;;; CANONICAL ARTICLE IDENTITY  (single source of truth)
;;;
;;; A lettered article (100Α) must NEVER collapse onto its base number (100) —
;;; that is silent data loss and breaks the corpus guarantee that "100" and
;;; "100Α" are different articles. Every id/eId/URI in the system is built from
;;; the two functions below; nothing reimplements the padding/suffix rule.
;;; ----------------------------------------------------------------------------

(defun article-base-number (number suffix-or-label)
  "Η αριθμητική ΒΑΣΗ μιας ταυτότητας άρθρου. Όταν το SUFFIX-OR-LABEL είναι
   ΠΛΗΡΕΣ label με ψηφία («100Α»), η βάση προκύπτει από ΑΥΤΟ — τη μία πηγή
   αλήθειας ταυτότητας — και ΟΧΙ από το NUMBER, που για lettered άρθρα είναι
   εσωτερικός συνθετικός αριθμός αποσαφήνισης (5Α ⇒ 5001). Γυμνό επίθημα
   («Α»), κενό string ή NIL ⇒ NUMBER.

   Συμβόλαιο: SUFFIX-OR-LABEL ∈ {NIL, string, symbol, character}. Αριθμός
   ΔΕΝ είναι label — (STRING 5) σηματοδοτεί TYPE-ERROR, δυνατά και τίμια."
  (or (and suffix-or-label
           (parse-integer (string suffix-or-label) :junk-allowed t))
      number))

(defun article-suffix-ordinal (suffix)
  "Η τακτική θέση του γράμμα-επιθήματος στη ΝΟΜΟΘΕΤΙΚΗ ακολουθία
   Α,Β,Γ,Δ,Ε,ΣΤ,Ζ,Η,Θ,Ι,ΙΑ,…: \"\" ⇒ 0, «Α» ⇒ 1, «ΣΤ» ⇒ 6, «ΙΑ» ⇒ 11.
   [0088] Η έδρα της ακολουθίας ΚΑΙ της εγκυρότητας ζει πλέον στο
   orchestrator.identity (suffix-ordinal, :upper) — εδώ ΔΗΛΩΜΕΝΟΣ adapter
   (θάνατος: Φ6 του LAWMAX-TEMPORAL-IDENTITY-DESIGN) που διατηρεί το
   δημόσιο συμβόλαιο σήματος: άκυρο επίθημα ⇒ orchestrator.spec:validation-error."
  (handler-case
      (orchestrator.identity:suffix-ordinal (string suffix) :sequence :upper)
    (orchestrator.identity:identity-parse-error (e)
      (error 'orchestrator.spec:validation-error
             :message (princ-to-string e)))))

(defun article-label-suffix (suffix-or-label)
  "Το γράμμα-επίθημα από το SUFFIX-OR-LABEL: γυμνό επίθημα (\"Α\"), πλήρες
   label (\"100Α\"), σύμβολο/χαρακτήρας, ή NIL. Επιστρέφει \"\" όταν δεν υπάρχει.

   Συμβόλαιο: αριθμός ΔΕΝ είναι label — (STRING 5) σηματοδοτεί TYPE-ERROR.
   Το επίθημα ΕΠΙΚΥΡΩΝΕΤΑΙ από τη μία έδρα (article-suffix-ordinal): «Α5»,
   «5Α », «5A» (λατινικό), «5α» ⇒ ΣΦΑΛΜΑ αντί για σιωπηλή ψευδοταυτότητα.
   P1b [0052]#1β: κενό ΜΕΣΑ στο label («5 Α») ⇒ ΣΦΑΛΜΑ — το αριστερό trim
   το κανονικοποιούσε σιωπηλά σε «Α», αποδίδοντας ταυτότητα σε άκυρη μορφή."
  (if (null suffix-or-label)
      ""
      (let ((s (string suffix-or-label)))
        (when (find #\Space s)
          (error 'orchestrator.spec:validation-error
                 :message (format nil "Άκυρο label/επίθημα άρθρου ~S — περιέχει κενό· η κανονική μορφή είναι «5Α»/«Α» χωρίς κενά" s)))
        (let ((suffix (string-left-trim "0123456789" s)))
          (article-suffix-ordinal suffix)   ; επικύρωση — σφάλμα αν άκυρο
          suffix))))

(defun pad-article-id (number &optional suffix-or-label)
  "Canonical PADDED article id (filesystem ids + eIds): NUMBER zero-padded to 3
   digits, with any letter suffix preserved. 70 -> \"070\", (70 \"Α\") -> \"070Α\",
   (100 \"100Α\") -> \"100Α\". THE single source of truth — do not reimplement."
  (let ((suffix (article-label-suffix suffix-or-label))
        (base (article-base-number number suffix-or-label)))
    (if (plusp (length suffix))
        (format nil "~3,'0D~A" base suffix)
        (format nil "~3,'0D" base))))

(defun article-uri-id (number &optional suffix-or-label)
  "Canonical UNPADDED article id for URI/ELI path segments (.../art/100Α): NUMBER
   with any letter suffix preserved, NOT zero-padded. 70 -> \"70\", (70 \"Α\") ->
   \"70Α\". THE single source of truth for URI path ids — do not reimplement."
  (let ((suffix (article-label-suffix suffix-or-label))
        (base (article-base-number number suffix-or-label)))
    (if (plusp (length suffix))
        (format nil "~D~A" base suffix)
        (format nil "~D" base))))

(defun article-file-id (article)
  "Canonical filesystem/eId identifier for ARTICLE that PRESERVES a letter
   suffix: '070' for article 70, '070Α' for article 70Α — από το typed
   identity slot μέσω της ΜΙΑΣ προβολής segment-file-id."
  ;; [0088 Φ6γ-Δ³] καμία fallback προβολή: άρθρο χωρίς ταυτότητα δεν αποκτά
  ;; δημόσιο id — fail-closed (το εμβρυϊκό στάδιο δεν προβάλλεται ποτέ).
  (segment-file-id (%article-identity-required article "article-file-id")))

(defun article-uri (article)
  "[0088 Φ6γ-Δ2] Η κανονική UNPADDED uri ταυτότητα ΕΝΟΣ ΑΝΤΙΚΕΙΜΕΝΟΥ άρθρου
   («5», «5Α») — από το typed identity slot· [Δ³] ΚΑΜΙΑ fallback προβολή:
   άρθρο χωρίς ταυτότητα ⇒ typed σφάλμα. Καταναλωτές με το ΑΝΤΙΚΕΙΜΕΝΟ
   περνούν από εδώ — όχι από το raw ζεύγος (number,label)."
  (segment-uri-id (%article-identity-required article "article-uri")))

(defun %article-identity-required (article context)
  "Το typed segment ή typed σφάλμα — καμία προβολή/σύνθεση χωρίς ταυτότητα."
  (or (article-identity article)
      (error 'orchestrator.spec:validation-error
             :message (format nil "~A: άρθρο χωρίς ταυτότητα (εμβρυϊκό — number/label αδέσμευτα)" context))))

(defun provision-id (corpus article)
  "[0088 Φ6γ-Δ³] Η ΠΛΗΡΗΣ παγκόσμια ταυτότητα διάταξης — ΑΠΟΚΛΕΙΣΤΙΚΑ μέσω
   της έδρας orchestrator.identity (make-provision-id): typed body × typed
   article segment. ΚΑΜΙΑ δεύτερη model-level σημασιολογία — αυτό που
   επιστρέφεται ΕΙΝΑΙ orchestrator.identity:provision-id (provision-id-p T).
   Fail-closed: corpus χωρίς typed body ή άρθρο χωρίς ταυτότητα ⇒ σφάλμα."
  (let ((body (corpus-legal-body-id corpus))
        (seg (%article-identity-required article "provision-id")))
    (unless (orchestrator.identity:body-id-p body)
      (error 'orchestrator.spec:validation-error
             :message (format nil "provision-id: corpus ~S χωρίς TYPED legal-body-id (orchestrator.identity)"
                              (and (slot-boundp corpus 'short-name)
                                   (corpus-short-name corpus)))))
    (orchestrator.identity:make-provision-id body (list seg))))

(defun provision-uri (corpus article)
  "Η URI προβολή της πλήρους provision identity: {eli-prefix}/art/{uri-id},
   με το uri-id ΑΠΟ ΤΗΝ ΕΔΡΑ (uri-id<-provision-id πάνω στο typed
   provision-id) — όχι χωριστή σύνθεση. Το eli-prefix είναι ΤΟΠΟΘΕΣΙΑ
   δημοσίευσης· η ταυτότητα είναι το typed provision-id."
  (eli-art-uri (corpus-eli-prefix corpus)
               (orchestrator.identity:uri-id<-provision-id
                (provision-id corpus article))))

(defun %article-order-key (a)
  "(βάση . τακτική-θέση) — από το typed slot· [Δ³] χωρίς ταυτότητα ⇒ σφάλμα."
  (let ((seg (%article-identity-required a "article-identity<")))
    (cons (second seg) (third seg))))

(defun article-identity< (a b)
  "Κανονική ολική διάταξη άρθρων: αριθμητική ΒΑΣΗ, μετά η ΝΟΜΟΘΕΤΙΚΗ τακτική
   θέση του επιθήματος (5, 5Α, …, 5Ε, 5ΣΤ, 5Ζ, …) — [0088 Φ6γ] από το typed
   identity slot (η έδρα, μία φορά στην κατασκευή)· ΠΟΤΕ ο εσωτερικός
   συνθετικός αριθμός (5Α ⇒ 5001) ούτε λεξικογραφικό string<."
  (let ((ka (%article-order-key a)) (kb (%article-order-key b)))
    (or (< (car ka) (car kb))
        (and (= (car ka) (car kb)) (< (cdr ka) (cdr kb))))))

(defun articles-in-identity-order (articles)
  "Η ΜΙΑ έδρα «κατάλογος άρθρων σε κανονική σειρά»: φρέσκια λίστα των ARTICLES
   σε σταθερή (stable) κανονική διάταξη article-identity<. Κάθε καταναλωτής
   που σειριοποιεί άρθρα (deploy manifest, ai manifests, provenance, consolidate)
   περνά από εδώ — το λάθος κλειδί ταξινόμησης δεν μπορεί να ξαναγραφτεί."
  (stable-sort (copy-list articles) #'article-identity<))

(defun article-live-p (article)
  "Check if article is in live state"
  (eq (article-processing-state article) :live))

(defun article-failed-p (article)
  "Check if article processing failed"
  (eq (article-processing-state article) :failed))

(defun article-processing-p (article)
  "Check if article is currently being processed"
  (member (article-processing-state article)
          '(:parsing :generating :validating :reviewing :hashing :anchoring :deploying)))

(defun article-ready-for-deploy-p (article)
  "Check if article is ready for deployment"
  (and (slot-boundp article 'rdf-turtle)
       (article-rdf-turtle article)
       (slot-boundp article 'json-ld)
       (article-json-ld article)
       (slot-boundp article 'blake3-hash)
       (article-hash article)
       (not (article-failed-p article))))
