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
    :accessor article-identity
    :initarg :identity
    :initform nil
    :documentation "[0088 Φ6γ] TYPED ταυτότητα άρθρου από την έδρα
                    orchestrator.identity: article-segment (:article ΒΑΣΗ
                    ΤΑΚΤΙΚΗ-ΘΕΣΗ), υπολογισμένο ΜΙΑ φορά στην κατασκευή
                    (make-article) — όχι επανα-parse του label ανά χρήση.
                    NIL μόνο σε αντικείμενα που κατασκευάστηκαν εκτός του
                    builder (tests) — μαζί με τους Δ-θανάτους της Φ6γ το
                    NIL πεθαίνει και το slot γίνεται υποχρεωτικό.")

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

(defmethod (setf article-label) :after (new-label (article article))
  "[0088 Φ6γ] Η typed ταυτότητα ΠΑΡΑΚΟΛΟΥΘΕΙ το label: κάθε αλλαγή label
   επανυπολογίζει το identity segment από την έδρα — stale/αποκλίνουσα
   ταυτότητα είναι ΔΟΜΙΚΑ αδύνατη (όχι φρουρημένη)."
  (setf (article-identity article)
        (%article-identity-segment-for
         new-label
         (and (slot-boundp article 'number) (article-number article)))))

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
   suffix: '070' for article 70, '070Α' for article 70Α. Delegates to the single
   source of truth PAD-ARTICLE-ID.

   P1b [0049]: όταν υπάρχει LABEL, η αριθμητική ΒΑΣΗ του ονόματος προκύπτει
   από το label (τη ΜΙΑ πηγή αλήθειας ταυτότητας) — ΟΧΙ από το article-number,
   που για lettered άρθρα είναι εσωτερικός συνθετικός αριθμός αποσαφήνισης
   (5Α ⇒ number 5001) και μόλυνε τα ονόματα αρχείων (article-5001Α αντί του
   κανονικού article-005Α)."
  ;; [0088 Φ6γ] το typed slot προηγείται (καμία επανερμηνεία label)· το
  ;; legacy μονοπάτι επιζεί ΜΟΝΟ για slot-less test αντικείμενα (πεθαίνει
  ;; με τους Δ-θανάτους). Η ισοδυναμία κλειδώνεται στο bijection gate 4694/0/0.
  (let ((seg (article-identity article)))
    (if seg
        (format nil "~3,'0D~A" (second seg)
                (orchestrator.identity:ordinal-suffix (third seg) :sequence :upper))
        (pad-article-id (article-number article) (article-label article)))))

(defun %article-order-key (a)
  "(βάση . τακτική-θέση) — από το typed slot όταν υπάρχει, αλλιώς legacy."
  (let ((seg (article-identity a)))
    (if seg
        (cons (second seg) (third seg))
        (cons (article-base-number (article-number a) (article-label a))
              (article-suffix-ordinal (article-label-suffix (article-label a)))))))

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
