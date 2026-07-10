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

(defun article-label-suffix (suffix-or-label)
  "Το γράμμα-επίθημα από το SUFFIX-OR-LABEL: γυμνό επίθημα (\"Α\"), πλήρες
   label (\"100Α\"), σύμβολο/χαρακτήρας, ή NIL. Επιστρέφει \"\" όταν δεν υπάρχει.

   Συμβόλαιο: αριθμός ΔΕΝ είναι label — (STRING 5) σηματοδοτεί TYPE-ERROR."
  (if (null suffix-or-label)
      ""
      (string-left-trim "0123456789 " (string suffix-or-label))))

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
  (pad-article-id (article-number article) (article-label article)))

(defun article-identity< (a b)
  "Κανονική ολική διάταξη άρθρων: αριθμητική ΒΑΣΗ, μετά γράμμα-επίθημα
   (5, 5Α, 6, …). Η ΜΙΑ έδρα διάταξης για καταλόγους/manifests/consolidation —
   ΠΟΤΕ διάταξη με τον εσωτερικό συνθετικό αριθμό (5Α ⇒ 5001), που έστελνε τα
   lettered άρθρα στο τέλος, μακριά από τη βάση τους."
  (let ((base-a (article-base-number (article-number a) (article-label a)))
        (base-b (article-base-number (article-number b) (article-label b))))
    (or (< base-a base-b)
        (and (= base-a base-b)
             (string< (article-label-suffix (article-label a))
                      (article-label-suffix (article-label b)))))))

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
