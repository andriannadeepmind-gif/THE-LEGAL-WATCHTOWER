;;;; systems/orchestrator-model/builders.lisp
;;;; Convenience constructors for model objects

(in-package :orchestrator.model)

;;; ============================================================================
;;; ARTICLE BUILDERS
;;; ============================================================================

(defun make-article (&key number label title content state metadata)
  "Create an article instance with validation

  Args:
    number: Article number (required, positive integer)
    label:  Πλήρες label ταυτότητας για lettered άρθρα (π.χ. \"5Α\") — χωρίς
            αυτό ένα lettered άρθρο ΔΕΝ κατασκευάζεται σωστά (P1b [0052]#Α7)
    title: Article title (string)
    content: Article content (string)
    state: Initial state (defaults to :queued)
    metadata: Additional metadata (plist)

  Returns:
    Article instance"
  (unless (and (integerp number) (> number 0))
    (error "Article number must be a positive integer"))

  ;; [0088 Φ6γ-Δ+κριτής B2] Η typed ταυτότητα ΔΕΝ υπολογίζεται εδώ: η ΜΙΑ
  ;; έδρα γέννησης είναι το initialize-instance :after του article —
  ;; ο builder απλώς κατασκευάζει. Άκυρο label σκάει στην ΚΑΤΑΣΚΕΥΗ
  ;; (validation-error από την έδρα), όχι βαθιά στο emit path.
  (make-instance 'article
                 :number number
                 :label label
                 :title (or title "")
                 :content (or content "")
                 :state (or state :queued)
                 :metadata metadata))

;;; ============================================================================
;;; CORPUS BUILDERS
;;; ============================================================================

(defun make-corpus (&key name short-name eli-prefix publication-date language
                         webid orcid metadata legal-body-id)
  "Create a corpus instance
  
  Args:
    name: Full corpus name (required)
    short-name: Short identifier (required)
    eli-prefix: ELI URI prefix (required)
    publication-date: Publication date
    language: ISO 639-1 language code (defaults to 'el')
    webid: Creator WebID
    orcid: Creator ORCID
    metadata: Additional metadata (plist)
  
  Returns:
    Corpus instance"
  (unless name
    (error "Corpus name is required"))
  (unless short-name
    (error "Corpus short-name is required"))
  (unless eli-prefix
    (error "Corpus ELI prefix is required"))
  
  (make-instance 'corpus
                 :name name
                 :short-name short-name
                 :eli-prefix eli-prefix
                 ;; [0088 #4] παγκόσμια ταυτότητα σώματος: ρητή ή το eli-prefix
                 :legal-body-id (or legal-body-id eli-prefix)
                 :publication-date publication-date
                 :language (or language "el")
                 :webid webid
                 :orcid orcid
                 :metadata metadata))

;;; ============================================================================
;;; ARTIFACT BUILDERS
;;; ============================================================================

(defun make-artifact (&key name type content dependencies metadata)
  "Create an artifact instance
  
  Args:
    name: Artifact name (symbol)
    type: Artifact type (keyword)
    content: Artifact content
    dependencies: List of artifact dependencies
    metadata: Additional metadata (plist)
  
  Returns:
    Artifact instance"
  (unless name
    (error "Artifact name is required"))
  (unless type
    (error "Artifact type is required"))
  
  (make-instance 'artifact
                 :name name
                 :type type
                 :content content
                 :dependencies dependencies
                 :metadata metadata))

;;; ============================================================================
;;; BULK BUILDERS
;;; ============================================================================

(defun make-articles-from-data (data-list)
  "Create multiple articles from list of plists
  
  Args:
    data-list: List of plists with :number, :title, :content, etc.
  
  Returns:
    List of article instances"
  (mapcar (lambda (data)
            (apply #'make-article data))
          data-list))

(defun populate-corpus (corpus article-data-list)
  "Populate corpus with articles from data list
  
  Args:
    corpus: Corpus instance
    article-data-list: List of article data plists
  
  Returns:
    Corpus with populated articles"
  (dolist (article-data article-data-list)
    (let ((article (apply #'make-article article-data)))
      (orchestrator.spec:add-article corpus article)))
  corpus)

;;; ============================================================================
;;; CLONING
;;; ============================================================================

(defun clone-article (article &rest override-slots)
  "Clone an article with optional slot overrides
  
  Args:
    article: Article to clone
    override-slots: Plist of slots to override
  
  Returns:
    Cloned article instance"
  (let ((new-article (make-instance 'article)))
    ;; Copy all slots
    (when (slot-boundp article 'number)
      (setf (article-number new-article) (article-number article)))
    ;; P1b [0052]#Α7: το label ΕΙΝΑΙ ταυτότητα — ο κλώνος χωρίς label έχανε
    ;; το επίθημα (100Α ⇒ 100, σιωπηλή σύμπτυξη ταυτότητας).
    (when (slot-boundp article 'label)
      (setf (article-label new-article) (article-label article)))
    ;; [0088 Φ6γ] το typed identity segment ΕΙΝΑΙ ταυτότητα — κλωνοποιείται
    (when (slot-boundp article 'identity-segment)
      (setf (article-identity new-article) (article-identity article)))
    (when (slot-boundp article 'title)
      (setf (article-title new-article) (article-title article)))
    (when (slot-boundp article 'content)
      (setf (article-content new-article) (article-content article)))
    (when (slot-boundp article 'state)
      (setf (article-processing-state new-article) (article-processing-state article)))
    (when (slot-boundp article 'metadata)
      (setf (article-metadata new-article) (copy-list (article-metadata article))))
    
    ;; [0088 κριτής-δημιουργού #3] Overrides ΜΕΣΩ των accessors — τα :after
    ;; invariants (number/label ⇒ επανυπολογισμός identity) ισχύουν ΚΑΙ στον
    ;; κλώνο· το raw slot-value bypass ΠΕΘΑΝΕ για identity-φέροντα slots.
    ;; Override του ΠΑΡΑΓΩΓΟΥ identity-segment απαγορεύεται ρητά (fail-closed):
    ;; η ταυτότητα προκύπτει ΜΟΝΟ από την έδρα, ποτέ από τον καλούντα.
    (loop for (slot value) on override-slots by #'cddr
          do (case slot
               (identity-segment
                (error 'orchestrator.spec:validation-error
                       :message "clone-article: το identity-segment είναι ΠΑΡΑΓΩΓΟ της έδρας — override απαγορεύεται· δώσε number/label"))
               (number (setf (article-number new-article) value))
               (label (setf (article-label new-article) value))
               (title (setf (article-title new-article) value))
               (content (setf (article-content new-article) value))
               (state (setf (article-processing-state new-article) value))
               (metadata (setf (article-metadata new-article) value))
               (t (setf (slot-value new-article slot) value))))

    new-article))
