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
                 ;; [0088 Φ6γ-Δ³] ΜΟΝΟ typed body (η κλάση απορρίπτει strings)·
                 ;; στην παραγωγή: orchestrator.identity:declared-body.
                 :legal-body-id legal-body-id
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
  ;; [Δ³-κριτής A#1/#14] ΕΝΑ βήμα κατασκευής: number+label μπαίνουν ΜΑΖΙ στο
  ;; make-instance — ο lettered κλώνος (70001,«70Α») δεν περνά ΠΟΤΕ από
  ;; ενδιάμεση ασυνεπή κατάσταση (number-χωρίς-label που έσκαγε). Overrides
  ;; ΜΟΝΟ από whitelist initargs· άγνωστο slot ⇒ typed σφάλμα — ΚΑΝΕΝΑ raw
  ;; slot-value κανάλι (ούτε t-branch). Η ταυτότητα είναι ΠΑΡΑΓΩΓΗ: δεν
  ;; αντιγράφεται, δεν γίνεται override.
  (let ((args '()))
    (flet ((put (k v) (setf (getf args k) v)))
      (when (slot-boundp article 'number) (put :number (article-number article)))
      (when (slot-boundp article 'label) (put :label (article-label article)))
      (when (slot-boundp article 'title) (put :title (article-title article)))
      (when (slot-boundp article 'content) (put :content (article-content article)))
      (when (slot-boundp article 'state) (put :state (article-processing-state article)))
      (when (slot-boundp article 'metadata) (put :metadata (copy-list (article-metadata article))))
      (loop for (slot value) on override-slots by #'cddr
            do (case slot
                 (number (put :number value))
                 (label (put :label value))
                 (title (put :title value))
                 (content (put :content value))
                 (state (put :state value))
                 (metadata (put :metadata value))
                 (t (error 'orchestrator.spec:validation-error
                           :message (format nil "clone-article: μη επιτρεπτό override slot ~S — μόνο {number label title content state metadata}· η ταυτότητα είναι ΠΑΡΑΓΩΓΗ της έδρας" slot))))))
    (apply #'make-instance 'article args)))
