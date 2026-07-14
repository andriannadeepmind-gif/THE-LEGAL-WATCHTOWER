;;;; systems/orchestrator-model/corpus.lisp
;;;; CORPUS class definition

(in-package :orchestrator.model)

;;; ============================================================================
;;; CORPUS CLASS
;;; ============================================================================

(defclass corpus ()
  ((name
    :accessor corpus-name
    :initarg :name
    :type string
    :documentation "Corpus name (e.g., 'Greek Constitution')")
   
   (short-name
    :accessor corpus-short-name
    :initarg :short-name
    :type string
    :documentation "Short identifier (e.g., 'constitution')")
   
   (legal-body-id
    :accessor corpus-legal-body-id
    :initarg :legal-body-id
    :initform nil
    :documentation "[0088 Φ6γ-Δ³] Η TYPED ταυτότητα του νομικού σώματος —
     ΑΠΟΚΛΕΙΣΤΙΚΑ orchestrator.identity:legal-body-id (jurisdiction/kind/
     year/number), ΠΟΤΕ string/ELI URI: η ταυτότητα ≠ τοποθεσία δημοσίευσης.
     Strings απορρίπτονται ΔΟΜΙΚΑ στη γέννηση (initialize-instance :after).
     Στην παραγωγή προέρχεται από τη ΜΙΑ έδρα orchestrator.identity:
     declared-body (config-δηλωμένο body_identity). NIL = ΜΟΝΟ δηλωμένο
     υπόλοιπο για μη-μεταναστευμένα νησιά — κάθε χρήση παγκόσμιας
     ταυτότητας (provision-id) fail-closes πάνω του.")

   (articles
    :accessor corpus-articles
    :initform (make-hash-table :test 'equal)
    :documentation "[0088 Φ6γ-Δ3] Hash table: κανονικό uri-id string («5»,«5Α»)
     → article — το κλειδί είναι η ΤΑΥΤΟΤΗΤΑ από την έδρα (article-uri), ποτέ
     ο εσωτερικός συνθετικός αριθμός.")
   
   (eli-prefix
    :accessor corpus-eli-prefix
    :initarg :eli-prefix
    :type string
    :documentation "ELI prefix for this corpus")
   
   (publication-date
    :accessor corpus-publication-date
    :initarg :publication-date
    :documentation "Original publication date")
   
   (language
    :accessor corpus-language
    :initarg :language
    :initform "el"
    :documentation "Primary language (ISO 639-1)")
   
   (webid
    :accessor corpus-webid
    :initarg :webid
    :initform "https://stavropouloslaw.com/#me"
    :documentation "WebID of corpus creator")
   
   (orcid
    :accessor corpus-orcid
    :initarg :orcid
    :initform "0009-0005-2832-2153"
    :documentation "ORCID of corpus creator")
   
   (blockchain-manifest
    :accessor corpus-blockchain-manifest
    :initform nil
    :documentation "Complete blockchain anchoring manifest")
   
   (master-hash
    :accessor corpus-master-hash
    :initform nil
    :documentation "Blake3 hash of complete corpus")
   
   (qes-signature
    :accessor corpus-qes-signature
    :initform nil
    :documentation "Qualified Electronic Signature")
   
   (metadata
    :accessor corpus-metadata
    :initarg :metadata
    :initform nil
    :type list
    :documentation "Additional metadata as plist"))
  (:metaclass corpus-class)
  (:documentation "Legal corpus container"))

(defmethod initialize-instance :after ((corpus corpus) &key)
  "[0088 Φ6γ-Δ³] Το legal-body-id είναι TYPED ή τίποτα: string/ELI URI/
   οτιδήποτε μη-typed απορρίπτεται ΣΤΗ ΓΕΝΝΗΣΗ — body-id/ELI drift είναι
   δομικά αδύνατο γιατί η ταυτότητα δεν μπορεί καν να ΕΙΝΑΙ URI string."
  (let ((body (and (slot-boundp corpus 'legal-body-id)
                   (slot-value corpus 'legal-body-id))))
    (when (and body (not (orchestrator.identity:body-id-p body)))
      (error 'orchestrator.spec:validation-error
             :message (format nil "corpus legal-body-id: απαιτείται TYPED orchestrator.identity:legal-body-id, όχι ~S — η ταυτότητα σώματος ΔΕΝ είναι string/URI" body)))))

(defmethod print-object ((corpus corpus) stream)
  "Print corpus in readable format"
  (print-unreadable-object (corpus stream :type t :identity t)
    (format stream "~A (~D articles)"
            (if (slot-boundp corpus 'name)
                (corpus-name corpus)
                "?")
            (if (slot-boundp corpus 'articles)
                (hash-table-count (corpus-articles corpus))
                0))))

;;; ============================================================================
;;; CORPUS METHODS
;;; ============================================================================

(defmethod orchestrator.spec:add-article ((corpus corpus) (article article))
  "Add an article to the corpus.

   P1b [0052]#Α3: κατειλημμένο κλειδί από ΑΛΛΟ άρθρο ⇒ ΣΦΑΛΜΑ — η σιωπηλή
   αντικατάσταση έκρυβε συγκρούσεις ταυτότητας/συνθετικού σχήματος (π.χ.
   δίγραμμα επιθήματος ή γνήσιο 4ψήφιο άρθρο πάνω σε συνθετικό αριθμό).
   Η επανακαταχώριση του ΙΔΙΟΥ αντικειμένου είναι ιδεμποτής."
  (let* ((key (article-uri article))   ; [0088 Φ6γ-Δ3] Η ΤΑΥΤΟΤΗΤΑ ως κλειδί
         (existing (gethash key (corpus-articles corpus))))
    (when (and existing (not (eq existing article)))
      (error 'orchestrator.spec:validation-error
             :message (format nil "add-article: το κλειδί ~A κατέχεται ήδη από άλλο άρθρο (~A) — σιωπηλή αντικατάσταση απαγορεύεται"
                              key (article-file-id existing))))
    (setf (gethash key (corpus-articles corpus)) article))
  article)

(defmethod orchestrator.spec:get-article ((corpus corpus) (id string))
  "[0088 Φ6γ-Δ3] Ανάκτηση με την ΚΑΝΟΝΙΚΗ ταυτότητα («5», «5Α») — το ΜΟΝΟ
   κλειδί. Ο παλιός integer τρόπος ΠΕΘΑΝΕ: ωμός αριθμός ΔΕΝ είναι ταυτότητα
   (5 ≠ 5Α ενώ ο συνθετικός 5001 τα μπέρδευε)."
  (gethash id (corpus-articles corpus)))

(defmethod orchestrator.spec:get-article ((corpus corpus) (number integer))
  "[0088 Φ6γ-Δ3 ΘΑΝΑΤΟΣ] Ο integer τρόπος αρνείται ΡΗΤΑ — typed σφάλμα,
   ποτέ σιωπηλή ψευδοταυτότητα από συνθετικό αριθμό."
  (declare (ignore number))
  (error 'orchestrator.spec:validation-error
         :message "get-article με ωμό ακέραιο ΠΕΘΑΝΕ [0088 Φ6γ] — χρησιμοποίησε την κανονική string ταυτότητα («5», «5Α»)"))

(defmethod orchestrator.spec:corpus-article-count ((corpus corpus))
  "Total number of articles in corpus"
  (hash-table-count (corpus-articles corpus)))

;;; ============================================================================
;;; CORPUS UTILITIES
;;; ============================================================================

(defun get-corpus-articles (corpus)
  "Get all articles from corpus as a list"
  (alexandria:hash-table-values (corpus-articles corpus)))

(defun get-corpus-eli-uris (corpus)
  "Get all ELI URIs from the corpus"
  (loop for article being the hash-values of (corpus-articles corpus)
        when (and (slot-boundp article 'eli-uri)
                 (article-eli-uri article))
        collect (article-eli-uri article)))

(defun corpus-articles-by-state (corpus state)
  "Get all articles in a specific state"
  (loop for article being the hash-values of (corpus-articles corpus)
        when (eq (article-processing-state article) state)
        collect article))

(defun corpus-live-count (corpus)
  "Count of articles in live state"
  (length (corpus-articles-by-state corpus :live)))

(defun corpus-failed-count (corpus)
  "Count of articles in failed state"
  (length (corpus-articles-by-state corpus :failed)))

(defun corpus-processing-count (corpus)
  "Count of articles currently being processed"
  (loop for article being the hash-values of (corpus-articles corpus)
        when (article-processing-p article)
        count 1))

(defun corpus-completion-percentage (corpus)
  "Calculate completion percentage"
  (let ((total (orchestrator.spec:corpus-article-count corpus)))
    (if (zerop total)
        0.0
        (* 100.0 (/ (corpus-live-count corpus) total)))))

(defun corpus-has-metadata (corpus metadata-key)
  "Check if corpus has specific metadata"
  (getf (corpus-metadata corpus) metadata-key))

(defun corpus-languages (corpus)
  "Get list of languages in corpus"
  (let ((langs (list (corpus-language corpus))))
    (or (getf (corpus-metadata corpus) :additional-languages)
        langs)))
