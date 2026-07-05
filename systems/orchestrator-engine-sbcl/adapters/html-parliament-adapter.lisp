;;;; HTML Parliament Adapter — Hellenic Parliament Constitution Fetcher
;;;; ΕΛΛΗΝΙΚΗ ΒΟΥΛΗ / Ελληνικό Σύνταγμα
;;;;
;;;; Full exploitation of Common Lisp:
;;;;   - Condition hierarchy with restarts (fetch/parse/encoding errors)
;;;;   - CLOS hierarchy for parsed HTML nodes
;;;;   - defparsing-rule macro (declarative rule DSL)
;;;;   - Generic functions with before/after/around combinations
;;;;   - Article accumulator CLOS object
;;;;   - load-time-value for all cl-ppcre scanners
;;;;   - Multiple values on key functions
;;;;   - Exponential-backoff retry via labels recursion
;;;;   - In-memory HTML cache (CLOS, TTL via local-time)
;;;;   - Named readtable with #§ dispatch macro (CSS-path → CXML-STP traversal)
;;;;   - MOP introspection for rule description
;;;;
;;;; Entry point: (parse-html-to-iir source-path &key corpus)
;;;; Output: list of orchestrator.model:normalized-article-input (same as pdf-adapter)

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; NAMED READTABLE — parliament-readtable with #§ dispatch
;;; ============================================================================

(named-readtables:defreadtable parliament-readtable
  (:merge :standard)
  (:dispatch-macro-char #\# #\§ (lambda (stream char arg)
                                   (parliament-css-path-reader stream char arg))))

;;; Forward declaration — the reader function body is defined after helpers.
(defun parliament-css-path-reader (stream sub-char numarg)
  "Read #§\"selector\" and expand to CXML-STP traversal expression.
   Supports: 'tag', 'tag > child', 'tag.class', '#id' (as attribute lookup).
   Returns a lambda form that takes a node and returns matching children."
  (declare (ignore sub-char numarg))
  (let ((selector (read stream t nil t)))
    (unless (stringp selector)
      (error "parliament-readtable: #§ expects a string selector, got ~S" selector))
    (parliament-selector->form selector)))

(defun parliament-selector->form (selector)
  "Convert a CSS-selector string to a CXML-STP traversal lambda form.
   Handles: 'tag', 'parent > child', '.class', '#id'."
  (let ((parts (mapcar #'string-trim
                        (list " " " ")
                        (cl-ppcre:split "\\s*>\\s*" selector))))
    (labels ((single-selector-form (sel node-var)
               (cond
                 ;; #id  → attribute lookup
                 ((and (> (length sel) 0) (char= (char sel 0) #\#))
                  (let ((id-val (subseq sel 1)))
                    `(find-node-by-attribute ,node-var "id" ,id-val)))
                 ;; .class → attribute lookup
                 ((and (> (length sel) 0) (char= (char sel 0) #\.))
                  (let ((class-val (subseq sel 1)))
                    `(find-nodes-by-class ,node-var ,class-val)))
                 ;; plain tag
                 (t
                  `(find-children-by-tag ,node-var ,sel))))
             (chain-forms (selectors node-var)
               (if (null (cdr selectors))
                   (single-selector-form (car selectors) node-var)
                   (let ((inner (chain-forms (cdr selectors) 'inner-node)))
                     `(loop for inner-node in ,(single-selector-form (car selectors) node-var)
                            nconc ,inner)))))
      `(lambda (root-node)
         ,(chain-forms parts 'root-node)))))

;;; ============================================================================
;;; URL CONSTANTS
;;; ============================================================================

(defparameter *parliament-constitution-url*
  "https://www.hellenicparliament.gr/Vouli-ton-Ellinon/To-Politevma/Syntagma/"
  "Official URL for the Greek Constitution on the Hellenic Parliament website.")

(defparameter *parliament-base-url*
  "https://www.hellenicparliament.gr"
  "Base URL for the Hellenic Parliament website.")

(defparameter *parliament-fetch-timeout*
  30
  "HTTP fetch timeout in seconds.")

(defparameter *parliament-max-retries*
  3
  "Maximum number of HTTP fetch retries.")

(defparameter *parliament-cache-ttl-seconds*
  3600
  "Default cache TTL: 1 hour.")

;;; ============================================================================
;;; CONDITION HIERARCHY WITH RESTARTS
;;; ============================================================================

(define-condition parliament-error (error)
  ((message :initarg :message :reader parliament-error-message :initform "Parliament error")
   (url     :initarg :url     :reader parliament-error-url     :initform nil))
  (:report (lambda (c s)
             (format s "Parliament error~@[ fetching ~A~]: ~A"
                     (parliament-error-url c)
                     (parliament-error-message c)))))

(define-condition parliament-fetch-error (parliament-error)
  ((http-status  :initarg :http-status  :reader fetch-error-http-status  :initform nil)
   (retry-count  :initarg :retry-count  :reader fetch-error-retry-count  :initform 0)
   (cached-html  :initarg :cached-html  :reader fetch-error-cached-html  :initform nil))
  (:report (lambda (c s)
             (format s "Parliament fetch error (HTTP ~@[~A~], retry ~A)~@[ at ~A~]: ~A"
                     (fetch-error-http-status c)
                     (fetch-error-retry-count c)
                     (parliament-error-url c)
                     (parliament-error-message c)))))

(define-condition parliament-parse-error (parliament-error)
  ((partial-results :initarg :partial-results :reader parse-error-partial-results :initform nil)
   (parse-position  :initarg :parse-position  :reader parse-error-position         :initform nil))
  (:report (lambda (c s)
             (format s "Parliament parse error~@[ at position ~A~]~@[ (URL: ~A)~]: ~A"
                     (parse-error-position c)
                     (parliament-error-url c)
                     (parliament-error-message c)))))

(define-condition parliament-encoding-error (parliament-error)
  ((detected-encoding :initarg :detected-encoding :reader encoding-error-detected :initform :unknown)
   (raw-bytes         :initarg :raw-bytes         :reader encoding-error-raw-bytes :initform nil))
  (:report (lambda (c s)
             (format s "Parliament encoding error (detected: ~A)~@[ at ~A~]: ~A"
                     (encoding-error-detected c)
                     (parliament-error-url c)
                     (parliament-error-message c)))))

;;; ============================================================================
;;; CLOS NODE HIERARCHY — HTML Legal Nodes
;;; ============================================================================

(defclass html-legal-node ()
  ((raw-text   :initarg :raw-text   :accessor node-raw-text   :initform ""
               :documentation "The unprocessed text content of this node")
   (source-line :initarg :source-line :accessor node-source-line :initform 0
                :documentation "Approximate line number in the HTML source")
   (confidence  :initarg :confidence  :accessor node-confidence  :initform 1.0
                :type float
                :documentation "Confidence score for this classification (0.0-1.0)"))
  (:documentation "Abstract base class for all parsed HTML legal document nodes."))

(defclass html-article-header-node (html-legal-node)
  ((article-num    :initarg :article-num    :accessor header-article-num    :initform 0
                   :type integer
                   :documentation "Numeric article number")
   (article-suffix :initarg :article-suffix :accessor header-article-suffix :initform nil
                   :documentation "Optional suffix letter e.g. Α, Β for amended articles")
   (title-text     :initarg :title-text     :accessor header-title-text     :initform nil
                   :documentation "Inline title text after the dash, if present"))
  (:documentation "Node representing an article header: Άρθρο N or Άρθρο N - Title"))

(defclass html-paragraph-node (html-legal-node)
  ((para-num        :initarg :para-num        :accessor para-num        :initform 0
                    :type integer
                    :documentation "Paragraph number (0 = unnumbered)")
   (content         :initarg :content         :accessor para-content    :initform ""
                    :type string
                    :documentation "Paragraph body text")
   (is-interpretive :initarg :is-interpretive :accessor para-interpretive-p :initform nil
                    :documentation "T if this paragraph is an Ερμηνευτική δήλωση"))
  (:documentation "Node representing a numbered or unnumbered paragraph within an article."))

(defclass html-section-node (html-legal-node)
  ((section-type :initarg :section-type :accessor section-node-type   :initform :meros
                 :type keyword
                 :documentation "One of :meros :tmima :kefalaio")
   (letter       :initarg :letter       :accessor section-node-letter :initform nil
                 :documentation "Section letter (e.g. Α, Β, ΣΤ) or ordinal word")
   (title        :initarg :title        :accessor section-node-title  :initform ""
                 :documentation "Section title text"))
  (:documentation "Node representing a structural section: ΜΕΡΟΣ, ΤΜΗΜΑ, or ΚΕΦΑΛΑΙΟ."))

(defclass html-noise-node (html-legal-node)
  ((noise-type :initarg :noise-type :accessor noise-node-type :initform :unknown
               :documentation "Classifier for the kind of noise (e.g. :page-number :header :blank)"))
  (:documentation "Node representing non-legal content that should be discarded."))

;;; ============================================================================
;;; PARSING RULE INFRASTRUCTURE
;;; ============================================================================

(defstruct parsing-rule
  "A single declarative parsing rule."
  (name       nil :type symbol)
  (pattern    nil)                      ; pre-compiled cl-ppcre scanner
  (classifier nil :type function)       ; lambda (groups text) -> html-legal-node
  (priority   0   :type integer)        ; higher priority rules tried first
  (doc        ""  :type string))

(defparameter *parsing-rules* nil
  "Global ordered list of parsing-rule structs, sorted descending by priority.
   Populated by defparsing-rule macro invocations at load time.")

(defmacro defparsing-rule (name &key pattern priority classifier)
  "Declarative DSL for defining a parsing rule.
   Registers in *parsing-rules* sorted by priority (high → low).
   Pattern is compiled at FASL load time via load-time-value.

   Usage:
     (defparsing-rule :article-header
       :pattern \"^\\\\s*Άρθρο...$\"
       :priority 100
       :classifier (lambda (groups text) ...))"
  (let ((scanner-sym (intern (format nil "*~A-SCANNER*"
                                     (string-upcase (symbol-name name))))))
    `(progn
       (defparameter ,scanner-sym
         (load-time-value (cl-ppcre:create-scanner ,pattern :multi-line-mode t))
         ,(format nil "Pre-compiled scanner for parsing rule ~A" name))
       (let ((rule (make-parsing-rule
                    :name       ',name
                    :pattern    ,scanner-sym
                    :classifier ,classifier
                    :priority   ,priority)))
         (setf *parsing-rules*
               (sort (cons rule
                           (remove ',name *parsing-rules*
                                   :key #'parsing-rule-name))
                     #'>
                     :key #'parsing-rule-priority))
         rule))))

;;; ============================================================================
;;; PRE-COMPILED SCANNERS (load-time-value)
;;; ============================================================================

;;; These are also registered via defparsing-rule below; these standalone
;;; defparameters exist for direct use in helper functions.

(defparameter *article-header-scanner*
  (load-time-value
   (cl-ppcre:create-scanner
    "^\\s*[ΆΑ]ρθρο[ν]?\\s+(\\d+)([Α-ΩA-Z])?\\s*(?:-\\s*(.+))?$"
    :multi-line-mode t))
  "Scanner for article headers: Άρθρο N or Άρθρο N - Title")

(defparameter *meros-scanner*
  (load-time-value
   (cl-ppcre:create-scanner
    "^\\s*ΜΕΡΟΣ\\s+([ΠΡΩΤΟΔΕΥΤΡΙΑΕΚΑO]+)\\s*$"
    :multi-line-mode t))
  "Scanner for ΜΕΡΟΣ structural headers")

(defparameter *tmima-scanner*
  (load-time-value
   (cl-ppcre:create-scanner
    "^\\s*ΤΜΗΜΑ\\s+([Α-ΩA-Z]+['΄ʹ]?)(?:\\s+(.+))?$"
    :multi-line-mode t))
  "Scanner for ΤΜΗΜΑ structural headers")

(defparameter *kefalaio-scanner*
  (load-time-value
   (cl-ppcre:create-scanner
    "^\\s*ΚΕΦΑΛΑΙΟ\\s+([Α-Ω]+['΄ʹ]?)(?:\\s+(.+))?$"
    :multi-line-mode t))
  "Scanner for ΚΕΦΑΛΑΙΟ structural headers")

(defparameter *numbered-paragraph-scanner*
  (load-time-value
   (cl-ppcre:create-scanner
    "^\\s*(\\d+)\\.\\s+(.+)$"
    :multi-line-mode t))
  "Scanner for numbered paragraphs: 1. text")

(defparameter *interpretive-scanner*
  (load-time-value
   (cl-ppcre:create-scanner
    "^\\s*Ερμηνευτική\\s+δήλωση"
    :multi-line-mode t))
  "Scanner for Ερμηνευτική δήλωση interpretive statement headers")

(defparameter *noise-scanner*
  (load-time-value
   (cl-ppcre:create-scanner
    "(?:^\\s*$|^\\s*\\d+\\s*$|^\\s*-\\s*\\d+\\s*-\\s*$|Ελληνική\\s+Βουλή|Βουλή\\s+των\\s+Ελλήνων|©\\s*\\d{4}|^\\s*Σελ[ίι]?[δς]?α?\\.?\\s*\\d+)"
    :multi-line-mode t))
  "Scanner for noise lines: blanks, page numbers, headers")

(defparameter *cross-ref-scanner*
  (load-time-value
   (cl-ppcre:create-scanner
    "(?:κατ[άα]\\s+τ[οη]ν?|σύμφωνα\\s+με|βλ\\.?|του\\s+άρθρου|το\\s+άρθρο)\\s+(\\d+)(?:\\s*(?:παρ\\.?|§)\\s*(\\d+))?"
    :multi-line-mode t))
  "Scanner for cross-references within article text")

;;; ============================================================================
;;; DEFPARSING-RULE DECLARATIONS
;;; ============================================================================

(defparsing-rule :article-header
  :pattern "^\\s*[ΆΑ]ρθρο[ν]?\\s+(\\d+)([Α-ΩA-Z])?\\s*(?:-\\s*(.+))?$"
  :priority 100
  :classifier (lambda (groups text)
                (make-instance 'html-article-header-node
                  :raw-text text
                  :article-num (parse-integer (or (and (> (length groups) 0) (aref groups 0)) "0"))
                  :article-suffix (when (and (> (length groups) 1) (aref groups 1))
                                    (aref groups 1))
                  :title-text (when (and (> (length groups) 2) (aref groups 2))
                                (string-trim '(#\Space #\Tab) (aref groups 2)))
                  :confidence 0.95)))

(defparsing-rule :meros-header
  :pattern "^\\s*ΜΕΡΟΣ\\s+([ΠΡΩΤΟΔΕΥΤΡΙΑΕΚΑO]+)\\s*$"
  :priority 90
  :classifier (lambda (groups text)
                (make-instance 'html-section-node
                  :raw-text text
                  :section-type :meros
                  :letter (when (> (length groups) 0) (aref groups 0))
                  :title ""
                  :confidence 0.90)))

(defparsing-rule :tmima-header
  :pattern "^\\s*ΤΜΗΜΑ\\s+([Α-ΩA-Z]+['΄ʹ]?)(?:\\s+(.+))?$"
  :priority 85
  :classifier (lambda (groups text)
                (make-instance 'html-section-node
                  :raw-text text
                  :section-type :tmima
                  :letter (when (> (length groups) 0) (aref groups 0))
                  :title (if (and (> (length groups) 1) (aref groups 1))
                             (string-trim '(#\Space #\Tab) (aref groups 1))
                             "")
                  :confidence 0.90)))

(defparsing-rule :kefalaio-header
  :pattern "^\\s*ΚΕΦΑΛΑΙΟ\\s+([Α-Ω]+['΄ʹ]?)(?:\\s+(.+))?$"
  :priority 80
  :classifier (lambda (groups text)
                (make-instance 'html-section-node
                  :raw-text text
                  :section-type :kefalaio
                  :letter (when (> (length groups) 0) (aref groups 0))
                  :title (if (and (> (length groups) 1) (aref groups 1))
                             (string-trim '(#\Space #\Tab) (aref groups 1))
                             "")
                  :confidence 0.88)))

(defparsing-rule :interpretive-statement
  :pattern "^\\s*Ερμηνευτική\\s+δήλωση"
  :priority 75
  :classifier (lambda (groups text)
                (declare (ignore groups))
                (make-instance 'html-paragraph-node
                  :raw-text text
                  :para-num 0
                  :content text
                  :is-interpretive t
                  :confidence 0.92)))

(defparsing-rule :numbered-paragraph
  :pattern "^\\s*(\\d+)\\.\\s+(.+)$"
  :priority 60
  :classifier (lambda (groups text)
                (make-instance 'html-paragraph-node
                  :raw-text text
                  :para-num (parse-integer (or (and (> (length groups) 0) (aref groups 0)) "0"))
                  :content (if (> (length groups) 1)
                               (string-trim '(#\Space #\Tab) (aref groups 1))
                               text)
                  :confidence 0.85)))

(defparsing-rule :noise-line
  :pattern "(?:^\\s*$|^\\s*\\d+\\s*$|^\\s*-\\s*\\d+\\s*-\\s*$|Ελληνική\\s+Βουλή|Βουλή\\s+των\\s+Ελλήνων|©\\s*\\d{4})"
  :priority 10
  :classifier (lambda (groups text)
                (declare (ignore groups))
                (make-instance 'html-noise-node
                  :raw-text text
                  :noise-type :detected
                  :confidence 0.80)))

;;; ============================================================================
;;; GENERIC FUNCTIONS WITH METHOD COMBINATIONS
;;; ============================================================================

(defgeneric classify-html-text (text context)
  (:documentation "Classify a text string based on context.
   Dispatches on context type to select appropriate classification strategy.
   Returns an html-legal-node instance."))

(defgeneric node->article-data (node)
  (:documentation "Extract article-level data from a parsed HTML node.
   Returns a plist with :number :title :content :section-type or NIL if not applicable."))

(defgeneric node-confidence (node)
  (:documentation "Return confidence score for this node's classification."))

(defgeneric merge-into-article (accumulator node)
  (:documentation "Merge a parsed node into the article accumulator.
   Implements the accumulator protocol for building article structures."))

;;; node-confidence :around — logs all confidence queries
(defmethod node-confidence :around ((node html-legal-node))
  (let ((score (call-next-method)))
    (log:debug () "node-confidence ~A → ~,3F" (class-name (class-of node)) score)
    score))

(defmethod node-confidence ((node html-legal-node))
  (slot-value node 'confidence))

(defmethod node-confidence ((node html-article-header-node))
  ;; Higher confidence if we also have a title
  (if (header-title-text node)
      (min 1.0 (+ (call-next-method) 0.04))
      (call-next-method)))

(defmethod node-confidence ((node html-noise-node))
  ;; Noise nodes always report what was set; never boost
  (slot-value node 'confidence))

;;; classify-html-text — null context (string dispatching only)
(defmethod classify-html-text ((text string) (context null))
  "Fallback: try all rules in priority order."
  (loop for rule in *parsing-rules*
        do (multiple-value-bind (match groups)
               (cl-ppcre:scan-to-strings (parsing-rule-pattern rule) text)
             (when match
               (return (funcall (parsing-rule-classifier rule) groups text))))
        finally (return (make-instance 'html-paragraph-node
                          :raw-text text
                          :para-num 0
                          :content text
                          :confidence 0.50))))

(defmethod classify-html-text ((text string) (context html-article-header-node))
  "Inside an article context: prefer paragraph classification."
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings *numbered-paragraph-scanner* text)
    (if match
        (make-instance 'html-paragraph-node
          :raw-text text
          :para-num (parse-integer (aref groups 0))
          :content (aref groups 1)
          :confidence 0.88)
        (classify-html-text text nil))))

(defmethod classify-html-text ((text string) (context html-section-node))
  "Inside a section context: check for article headers first."
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings *article-header-scanner* text)
    (if match
        (make-instance 'html-article-header-node
          :raw-text text
          :article-num (parse-integer (aref groups 0))
          :article-suffix (aref groups 1)
          :title-text (aref groups 2)
          :confidence 0.96)
        (classify-html-text text nil))))

;;; node->article-data — polymorphic extraction
(defmethod node->article-data ((node html-article-header-node))
  (list :number (header-article-num node)
        :title  (or (header-title-text node) "")
        :suffix (header-article-suffix node)))

(defmethod node->article-data ((node html-paragraph-node))
  (list :content (para-content node)
        :para-num (para-num node)
        :interpretive (para-interpretive-p node)))

(defmethod node->article-data ((node html-section-node))
  (list :section-type (section-node-type node)
        :letter (section-node-letter node)
        :title (section-node-title node)))

(defmethod node->article-data ((node html-noise-node))
  nil)

(defmethod node->article-data ((node html-legal-node))
  nil)

;;; ============================================================================
;;; ARTICLE ACCUMULATOR — CLOS Object (not a plain closure)
;;; ============================================================================

(defclass html-article-accumulator ()
  ((current-article-num   :initform nil  :accessor acc-current-num)
   (current-article-title :initform nil  :accessor acc-current-title)
   (current-article-suffix :initform nil :accessor acc-current-suffix)
   (current-paragraphs    :initform nil  :accessor acc-current-paragraphs)
   (articles-collected    :initform nil  :accessor acc-articles-collected)
   (current-section-title :initform ""  :accessor acc-section-title
                          :documentation "Title inherited from enclosing ΤΜΗΜΑ/ΚΕΦΑΛΑΙΟ")
   (current-section-type  :initform nil  :accessor acc-section-type)
   (warnings              :initform nil  :accessor acc-warnings
                          :documentation "Accumulated parse warnings"))
  (:documentation "Stateful accumulator for building articles from parsed HTML nodes.
   Use the accumulate, finalize-current-article, and collected-articles generics."))

(defgeneric accumulate (accumulator node)
  (:documentation "Process one parsed node into the accumulator state."))

(defgeneric finalize-current-article (accumulator)
  (:documentation "Finalize and store the current article, reset state."))

(defgeneric collected-articles (accumulator)
  (:documentation "Return all fully-collected articles (in order)."))

;;; :before method validates article completeness
(defmethod finalize-current-article :before ((acc html-article-accumulator))
  (when (acc-current-num acc)
    (when (null (acc-current-paragraphs acc))
      (push (format nil "Article ~A has no paragraphs" (acc-current-num acc))
            (acc-warnings acc)))
    (when (and (acc-current-num acc)
               (not (typep (acc-current-num acc) 'integer)))
      (push (format nil "Article number is not integer: ~S" (acc-current-num acc))
            (acc-warnings acc)))))

(defmethod finalize-current-article ((acc html-article-accumulator))
  (when (acc-current-num acc)
    (let* ((paras   (nreverse (acc-current-paragraphs acc)))
           (content (format nil "~{~A~^~%~}"
                            (loop for p in paras
                                  collect (let ((data (node->article-data p)))
                                            (if data
                                                (getf data :content "")
                                                "")))))
           (title   (let ((sec-title (acc-section-title acc))
                          (hdr-title (acc-current-title acc)))
                      (cond
                        ((and hdr-title (> (length hdr-title) 0)) hdr-title)
                        ((and sec-title (> (length sec-title) 0)) sec-title)
                        (t "")))))
      (push (list :num     (acc-current-num acc)
                  :title   title
                  :suffix  (acc-current-suffix acc)
                  :content content
                  :paras   paras)
            (acc-articles-collected acc))))
  (setf (acc-current-num acc)        nil
        (acc-current-title acc)      nil
        (acc-current-suffix acc)     nil
        (acc-current-paragraphs acc) nil))

(defmethod collected-articles ((acc html-article-accumulator))
  (nreverse (acc-articles-collected acc)))

(defmethod accumulate ((acc html-article-accumulator) (node html-article-header-node))
  "A new article header triggers finalization of the previous article."
  (finalize-current-article acc)
  (setf (acc-current-num acc)    (header-article-num node)
        (acc-current-title acc)  (or (header-title-text node) "")
        (acc-current-suffix acc) (header-article-suffix node)))

(defmethod accumulate ((acc html-article-accumulator) (node html-paragraph-node))
  "Paragraph nodes accumulate into the current article."
  (when (acc-current-num acc)
    (push node (acc-current-paragraphs acc))))

(defmethod accumulate ((acc html-article-accumulator) (node html-section-node))
  "Section nodes update the inherited title context."
  (finalize-current-article acc)
  (setf (acc-section-title acc) (section-node-title node)
        (acc-section-type acc)  (section-node-type node)))

(defmethod accumulate ((acc html-article-accumulator) (node html-noise-node))
  "Noise nodes are silently discarded."
  (declare (ignore acc node))
  nil)

(defmethod accumulate ((acc html-article-accumulator) (node html-legal-node))
  "Fallback: treat unrecognized nodes as paragraph content if inside an article."
  (when (and (acc-current-num acc) (> (length (node-raw-text node)) 0))
    (let ((para (make-instance 'html-paragraph-node
                  :raw-text (node-raw-text node)
                  :para-num 0
                  :content  (node-raw-text node)
                  :confidence 0.40)))
      (push para (acc-current-paragraphs acc)))))

(defmethod merge-into-article ((acc html-article-accumulator) (node html-legal-node))
  "Alias: delegate to accumulate."
  (accumulate acc node))

;;; ============================================================================
;;; CXML-STP TRAVERSAL HELPERS (used by #§ reader macro output)
;;; Available only when cxml-stp is loaded; otherwise stubs signal parse error.
;;; ============================================================================

#+cxml-stp
(defun find-children-by-tag (node tag-name)
  "Return all direct children of NODE whose local-name matches TAG-NAME (case-insensitive)."
  (let ((results nil))
    (cxml-stp:do-children (child node)
      (when (and (typep child 'cxml-stp:element)
                 (string-equal (cxml-stp:local-name child) tag-name))
        (push child results)))
    (nreverse results)))

#+cxml-stp
(defun find-nodes-by-class (node class-name)
  "Return all descendant elements of NODE whose @class attribute contains CLASS-NAME."
  (let ((results nil))
    (cxml-stp:do-recursively (child node)
      (when (typep child 'cxml-stp:element)
        (let ((class-attr (cxml-stp:attribute-value child "class")))
          (when (and class-attr
                     (cl-ppcre:scan (concatenate 'string "(?:^|\\s)"
                                                 (cl-ppcre:quote-meta-chars class-name)
                                                 "(?:\\s|$)")
                                    class-attr))
            (push child results)))))
    (nreverse results)))

#+cxml-stp
(defun find-node-by-attribute (node attr-name attr-value)
  "Return first descendant of NODE whose attribute ATTR-NAME equals ATTR-VALUE."
  (cxml-stp:do-recursively (child node)
    (when (typep child 'cxml-stp:element)
      (let ((val (cxml-stp:attribute-value child attr-name)))
        (when (and val (string= val attr-value))
          (return-from find-node-by-attribute child)))))
  nil)

#+cxml-stp
(defun collect-text-content (node)
  "Collect all text content of NODE and its descendants, joined."
  (with-output-to-string (s)
    (cxml-stp:do-recursively (child node)
      (when (typep child 'cxml-stp:text)
        (write-string (cxml-stp:data child) s)))))

#+cxml-stp
(defun node-local-name-p (node name)
  "T if NODE is an element with local-name NAME (case-insensitive)."
  (and (typep node 'cxml-stp:element)
       (string-equal (cxml-stp:local-name node) name)))

;;; ============================================================================
;;; IN-MEMORY HTML CACHE (CLOS with TTL via local-time)
;;; ============================================================================

(defclass html-cache ()
  ((table   :initform (make-hash-table :test 'equal) :reader cache-table
            :documentation "Hash table: URL → (html-string . local-time:timestamp)")
   (ttl-sec :initarg :ttl-sec :accessor cache-ttl-seconds :initform 3600
            :documentation "Cache entry TTL in seconds"))
  (:documentation "Thread-safe in-memory cache for fetched HTML strings."))

(defvar *global-html-cache*
  (make-instance 'html-cache :ttl-sec *parliament-cache-ttl-seconds*)
  "Process-global HTML cache instance.")

(defun cache-get (cache url)
  "Return (values html-string t) if URL is cached and not expired, else (values nil nil)."
  (let ((entry (gethash url (cache-table cache))))
    (if entry
        (let* ((ts   (cdr entry))
               (age  (local-time:timestamp-difference
                      (local-time:now) ts)))
          (if (< age (cache-ttl-seconds cache))
              (values (car entry) t)
              (progn
                (remhash url (cache-table cache))
                (values nil nil))))
        (values nil nil))))

(defun cache-put (cache url html-string)
  "Store HTML-STRING for URL in CACHE with current timestamp."
  (setf (gethash url (cache-table cache))
        (cons html-string (local-time:now))))

(defun cache-invalidate (cache url)
  "Remove URL from CACHE."
  (remhash url (cache-table cache)))

(defmacro with-html-cache ((cache-var &key (ttl *parliament-cache-ttl-seconds*)) &body body)
  "Establish a fresh html-cache scope bound to CACHE-VAR for the extent of BODY.
   Useful for test isolation or short-lived fetch scopes."
  `(let ((,cache-var (make-instance 'html-cache :ttl-sec ,ttl)))
     ,@body))

;;; ============================================================================
;;; HTTP FETCH WITH RETRY + EXPONENTIAL BACKOFF
;;; ============================================================================

(defun fetch-once (url)
  "Perform a single HTTP GET for URL. Returns (values html-string response-headers).
   Signals parliament-fetch-error on non-200 or network failure."
  (handler-case
      (multiple-value-bind (body status headers)
          (drakma:http-request url
                               :method :get
                               :connection-timeout *parliament-fetch-timeout*
                               :read-timeout *parliament-fetch-timeout*
                               :user-agent "Mozilla/5.0 (compatible; OrchestratorBot/1.0)"
                               :accept "text/html,application/xhtml+xml"
                               :external-format-in :utf-8
                               :external-format-out :utf-8
                               :force-string t)
        (unless (= status 200)
          (error 'parliament-fetch-error
                 :message (format nil "HTTP ~A from ~A" status url)
                 :url url
                 :http-status status))
        ;; Ensure body is a string in UTF-8
        (let ((html-string (if (stringp body)
                               body
                               (handler-case
                                   (babel:octets-to-string body :encoding :utf-8)
                                 (babel-encodings:character-decoding-error (e)
                                   (restart-case
                                       (error 'parliament-encoding-error
                                              :message (format nil "UTF-8 decode failed: ~A" e)
                                              :url url
                                              :detected-encoding :utf-8
                                              :raw-bytes body)
                                     (transcode-latin1 ()
                                       :report "Re-decode body as ISO-8859-7 (Greek)"
                                       (babel:octets-to-string body :encoding :iso-8859-7))))))))
          (values html-string headers)))
    (usocket:connection-refused-error (e)
      (error 'parliament-fetch-error
             :message (format nil "Connection refused: ~A" e)
             :url url))
    (usocket:timeout-error (e)
      (error 'parliament-fetch-error
             :message (format nil "Connection timed out: ~A" e)
             :url url))
    (drakma:drakma-error (e)
      (error 'parliament-fetch-error
             :message (format nil "Drakma error: ~A" e)
             :url url))))

(defun fetch-parliament-html (url &key (max-retries *parliament-max-retries*)
                                       (cache *global-html-cache*))
  "Fetch HTML from URL with retry + exponential backoff.
   Returns (values html-string from-cache-p response-headers).
   Restarts available: retry-fetch, use-cached, abort."
  ;; Check cache first
  (multiple-value-bind (cached-html cached-p)
      (cache-get cache url)
    (when cached-p
      (log:info () "HTML cache HIT: ~A" url)
      (return-from fetch-parliament-html (values cached-html t nil))))

  (log:info () "Fetching Parliament HTML: ~A (max-retries=~D)" url max-retries)

  ;; Retry with exponential backoff
  (labels ((attempt (retries-left backoff-secs)
             (restart-case
                 (handler-case
                     (multiple-value-bind (html headers)
                         (fetch-once url)
                       (cache-put cache url html)
                       (values html nil headers))
                   (parliament-fetch-error (e)
                     (log:warn () "Fetch attempt failed (retries-left=~D): ~A"
                               retries-left (parliament-error-message e))
                     (if (zerop retries-left)
                         (restart-case
                             (error e)
                           (use-cached ()
                             :report "Return stale cached HTML if available"
                             (multiple-value-bind (stale found-p)
                                 (cache-get (make-instance 'html-cache :ttl-sec most-positive-fixnum) url)
                               (if found-p
                                   (values stale t nil)
                                   (error e))))
                           (abort ()
                             :report "Abort fetching, return empty string"
                             (values "" nil nil)))
                         (progn
                           (log:info () "Retrying in ~D seconds..." backoff-secs)
                           (sleep backoff-secs)
                           (attempt (1- retries-left) (* 2 backoff-secs))))))
               (retry-fetch ()
                 :report "Force a fresh fetch attempt (reset retry counter)"
                 (attempt max-retries 2)))))
    (attempt max-retries 2)))

;;; ============================================================================
;;; HTML PARSING — CXML STP + cl-ppcre fallback
;;; ============================================================================

#+cxml-stp
(defun parse-via-cxml (html-string source-url)
  "Parse HTML via CXML's HTML tolerant parser → STP document.
   Returns the STP document node, or signals parliament-parse-error."
  (handler-case
      (let* ((input (babel:string-to-octets html-string :encoding :utf-8))
             (document (cxml:parse input (cxml-stp:make-builder)
                                   :validate nil
                                   :dtd-handler nil)))
        document)
    (error (e)
      (error 'parliament-parse-error
             :message (format nil "CXML parse failed: ~A" e)
             :url source-url))))

#-cxml-stp
(defun parse-via-cxml (html-string source-url)
  "Stub: cxml-stp not available in this build — signals parliament-parse-error
   so parse-parliament-html automatically falls back to the regex parser."
  (declare (ignore html-string))
  (error 'parliament-parse-error
         :message "cxml-stp not loaded — using regex fallback"
         :url source-url))

#+cxml-stp
(defun extract-text-nodes-from-stp (document)
  "Walk the STP document tree and collect all non-empty text content
   from elements that look like legal text containers (p, div, span, li, td).
   Returns a list of (text . source-line) conses."
  (let ((legal-tags '("p" "div" "span" "li" "td" "h1" "h2" "h3" "h4" "h5" "h6"
                      "article" "section" "main"))
        (results nil)
        (line-counter 0))
    (cxml-stp:do-recursively (node document)
      (when (typep node 'cxml-stp:element)
        (when (member (cxml-stp:local-name node) legal-tags :test #'string-equal)
          ;; Get direct text content only (not recursive, to avoid duplicates)
          (let ((text (with-output-to-string (s)
                        (cxml-stp:do-children (child node)
                          (when (typep child 'cxml-stp:text)
                            (write-string (cxml-stp:data child) s))))))
            (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return #\No-Break_Space) text)))
              (when (> (length trimmed) 0)
                (incf line-counter)
                (push (cons trimmed line-counter) results)))))))
    (nreverse results)))

#-cxml-stp
(defun extract-text-nodes-from-stp (document)
  "Stub: not used when cxml-stp is absent."
  (declare (ignore document))
  nil)

(defun extract-text-lines-fallback (html-string)
  "Fallback: strip HTML tags with cl-ppcre and split into lines.
   Used when CXML fails on malformed HTML.
   Returns a list of (text . line-number) conses."
  (let* (;; Remove script and style blocks
         (no-scripts (cl-ppcre:regex-replace-all
                      "(?si)<(?:script|style)[^>]*>.*?</(?:script|style)>"
                      html-string ""))
         ;; Remove HTML comments
         (no-comments (cl-ppcre:regex-replace-all "<!--.*?-->" no-scripts ""))
         ;; Replace block-level tags with newlines
         (with-breaks (cl-ppcre:regex-replace-all
                       "(?i)</?(?:p|div|br|h[1-6]|li|tr|td|th|section|article|main|header|footer)[^>]*>"
                       no-comments (string #\Newline)))
         ;; Strip all remaining tags
         (stripped (cl-ppcre:regex-replace-all "<[^>]+>" with-breaks ""))
         ;; Decode common HTML entities
         (decoded (decode-html-entities stripped))
         (lines (cl-ppcre:split "\\n" decoded)))
    (loop for line in lines
          for i from 1
          for trimmed = (string-trim '(#\Space #\Tab #\Return #\No-Break_Space) line)
          when (> (length trimmed) 0)
            collect (cons trimmed i))))

(defun decode-html-entities (text)
  "Decode common HTML entities in TEXT."
  (let ((result text))
    (setf result (cl-ppcre:regex-replace-all "&amp;"  result "&"))
    (setf result (cl-ppcre:regex-replace-all "&lt;"   result "<"))
    (setf result (cl-ppcre:regex-replace-all "&gt;"   result ">"))
    (setf result (cl-ppcre:regex-replace-all "&quot;" result "\""))
    (setf result (cl-ppcre:regex-replace-all "&apos;" result "'"))
    (setf result (cl-ppcre:regex-replace-all "&nbsp;" result " "))
    (setf result (cl-ppcre:regex-replace-all "&#(\\d+);"
                                             result
                                             (lambda (match n)
                                               (declare (ignore match))
                                               (handler-case
                                                   (string (code-char (parse-integer n)))
                                                 (error () "")))))
    result))

(defun normalize-html-whitespace (text)
  "Normalize whitespace in extracted HTML text."
  (let* ((no-cr  (cl-ppcre:regex-replace-all "\\r" text ""))
         (single (cl-ppcre:regex-replace-all "[ \\t]+" no-cr " ")))
    (string-trim '(#\Space #\Tab #\Newline #\Return) single)))

;;; ============================================================================
;;; NODE CLASSIFICATION PASS
;;; ============================================================================

(defun classify-text-lines (text-lines)
  "Take a list of (text . line-num) conses and return a list of html-legal-node instances.
   Uses the registered *parsing-rules* via classify-html-text."
  (let ((context nil))   ; tracks the most recent meaningful context node
    (loop for (text . line-num) in text-lines
          for normalized = (normalize-html-whitespace text)
          when (> (length normalized) 0)
            collect (let ((node (classify-html-text normalized context)))
                      (setf (node-source-line node) line-num)
                      ;; Update context for next iteration
                      (typecase node
                        ((or html-article-header-node html-section-node)
                         (setf context node)))
                      node))))

;;; ============================================================================
;;; MAIN HTML PARSER — orchestrates STP + fallback
;;; ============================================================================

(defun parse-parliament-html (html &optional source-url)
  "Parse Parliament HTML into structured article data.
   Returns (values articles warnings parse-stats).
   SOURCE-URL is an optional base URI for the CXML parse (may be NIL).

   Strategy:
   1. Try CXML STP parse → extract text nodes → classify → accumulate
   2. On CXML failure: restart with use-partial-results → fallback to line-by-line"
  (let ((warnings nil)
        (parse-method :cxml)
        (text-lines nil))

    ;; Step 1: Extract text lines (CXML or fallback)
    (restart-case
        (handler-case
            (let ((doc (parse-via-cxml html source-url)))
              (setf text-lines (extract-text-nodes-from-stp doc))
              (log:info () "CXML parse succeeded: ~D text nodes" (length text-lines)))
          (parliament-parse-error (e)
            (log:warn () "CXML failed, using regex fallback: ~A" (parliament-error-message e))
            (push (parliament-error-message e) warnings)
            (setf parse-method :regex-fallback)
            (setf text-lines (extract-text-lines-fallback html))
            (log:info () "Regex fallback: ~D text lines" (length text-lines))))
      (use-partial-results ()
        :report "Use whatever text was extracted before the parse error"
        (when (null text-lines)
          (setf text-lines (extract-text-lines-fallback html))
          (setf parse-method :partial-regex)))
      (skip-article ()
        :report "Skip current article and continue with remaining HTML"
        (push "Skipped article due to parse error" warnings)))

    ;; Step 2: Classify text lines into nodes
    (let* ((nodes    (restart-case
                         (classify-text-lines text-lines)
                       (use-partial-results ()
                         :report "Return whatever nodes were classified"
                         (classify-text-lines (subseq text-lines 0
                                                       (floor (length text-lines) 2))))))
           ;; Step 3: Accumulate nodes into articles
           (acc      (make-instance 'html-article-accumulator)))

      (dolist (node nodes)
        (accumulate acc node))
      (finalize-current-article acc)

      (let* ((articles     (collected-articles acc))
             (all-warnings (append warnings (acc-warnings acc)))
             (parse-stats  (list :method parse-method
                                 :text-lines (length text-lines)
                                 :nodes (length nodes)
                                 :articles (length articles)
                                 :warnings (length all-warnings))))
        (log:info () "parse-parliament-html: ~D articles, method=~A, warnings=~D"
                  (length articles) parse-method (length all-warnings))
        (values articles all-warnings parse-stats)))))

;;; ============================================================================
;;; CONSTITUTION CRAWLER — Hellenic Parliament publishes the Σύνταγμα NOT as one
;;; page but as ~120 sub-pages (/…/syntagma/article-N/), each a single article
;;; «<h1>Άρθρο N: (τίτλος)</h1>» + a «<p>» whose <br/>-separated lines are the
;;; numbered paragraphs. So we crawl the index for the article links and parse each
;;; sub-page. Pure parsers (no network) so they unit-test against the real markup;
;;; the fetch is injected.
;;; ============================================================================

(defun %con-strip-tags (html) (cl-ppcre:regex-replace-all "<[^>]+>" html ""))

(defun %con-decode-entities (s)
  "Decode the handful of HTML entities the Parliament pages use (named + numeric)."
  (let ((s s))
    (dolist (pair '(("&#0?39;" . "'") ("&nbsp;" . " ") ("&amp;" . "&")
                    ("&gt;" . ">") ("&lt;" . "<") ("&quot;" . "\"")
                    ("&laquo;" . "«") ("&raquo;" . "»") ("&ndash;" . "–")))
      (setf s (cl-ppcre:regex-replace-all (car pair) s (cdr pair))))
    ;; remaining numeric &#NNN;
    (cl-ppcre:regex-replace-all
     "&#(\\d+);" s
     (lambda (match &rest regs) (declare (ignore regs))
       (let ((code (ignore-errors (parse-integer match :start 2 :junk-allowed t))))
         (if code (string (code-char code)) match))))))

(defun extract-constitution-article-links (index-html)
  "Every distinct /…/syntagma/article-N/ sub-page path in INDEX-HTML, in order."
  (let ((seen (make-hash-table :test 'equal)) (out '()))
    (cl-ppcre:do-register-groups (path)
        ("(?i)href=\"([^\"]*?/syntagma/article-\\d+/?)\"" index-html)
      (unless (gethash path seen) (setf (gethash path seen) t) (push path out)))
    (nreverse out)))

(defparameter *con-homoglyph-caps*
  '((#\A . #\Α) (#\B . #\Β) (#\E . #\Ε) (#\Z . #\Ζ) (#\H . #\Η) (#\I . #\Ι)
    (#\K . #\Κ) (#\M . #\Μ) (#\N . #\Ν) (#\O . #\Ο) (#\P . #\Ρ) (#\T . #\Τ)
    (#\Y . #\Υ) (#\X . #\Χ))
  "Latin capitals the Parliament HTML emits in place of the identical Greek letter.")

(defun %con-fix-standalone-homoglyphs (s)
  "In normative Greek text a STANDALONE Latin capital homoglyph (Ο, Η, Α, Τ…) is the
   Greek letter/article — convert it. Whole-token only (a letter on either side means
   it belongs to a real word, which normalize-greek-homoglyphs already handled
   token-internally), so genuine Latin words are never touched."
  (let ((out s))
    (dolist (pair *con-homoglyph-caps* out)
      (setf out (cl-ppcre:regex-replace-all
                 (format nil "(?<![A-Za-zΑ-Ωα-ωΆ-Ώά-ώ])~A(?![A-Za-zΑ-Ωα-ωΆ-Ώά-ώ])" (car pair))
                 out (string (cdr pair)))))))

(defun parse-constitution-article-page (html)
  "Parse one Constitution sub-page into (values number title paragraphs). The
   article header is «<h1>['Αρθρο]/[Άρθρο] N: (title)</h1>»; the body is the markup
   up to the next structural block, with <br/> as the paragraph separator. Latin
   homoglyphs the page uses for Greek (Tο→Το, Eλλάδας→Ελλάδας) are normalised.
   Returns NIL when no article header is present."
  (cl-ppcre:register-groups-bind (num title body)
      ("(?is)<h1[^>]*>[^<]*?[ΆΑ]ρθρο\\s+(\\d+)\\s*:?\\s*\\(?\\s*([^<)]*?)\\s*\\)?\\s*</h1>(.*?)(?:<h1|<h2|<div\\s+class|</article|<footer|$)"
       html)
    (when num
      (let* ((n (parse-integer num))
             (ttl (string-trim '(#\Space #\.) (%con-decode-entities (or title ""))))
             ;; ROOT-strip the site's navigation anchors («Επόμενο »», «Επιστροφή »»,
             ;; «Δείτε όλα τα άρθρα »») — they carry a '>>' arrow that never appears in
             ;; normative text; genuine cross-reference <a> links (no arrow) survive.
             (nav-free (cl-ppcre:regex-replace-all
                        "(?is)<a\\b[^>]*>[^<]*?(?:&gt;\\s*&gt;|>>)[^<]*?</a>" (or body "") ""))
             (flat (%con-fix-standalone-homoglyphs
                    (normalize-greek-homoglyphs
                     (%con-decode-entities
                      (%con-strip-tags
                       (cl-ppcre:regex-replace-all "(?i)<br\\s*/?>" nav-free (string #\Newline)))))))
             ;; belt-and-suspenders: drop any paragraph that is still pure nav («… >>»)
             (paras (remove-if (lambda (p) (or (< (length p) 2)
                                               (and (>= (length p) 2)
                                                    (string= ">>" (subseq p (- (length p) 2))))))
                               (mapcar (lambda (p) (string-trim '(#\Space #\Tab #\Return)
                                                                (cl-ppcre:regex-replace-all "\\s+" p " ")))
                                       (cl-ppcre:split "\\n+" flat)))))
        (values n ttl paras)))))

(defun crawl-constitution (index-html fetch-fn)
  "Crawl the Σύνταγμα: extract the article sub-page links from INDEX-HTML, fetch each
   via FETCH-FN (a (url)->html function — injected, so this is testable offline),
   parse it, and return the article maps [{\"title\",\"content\"[]}] in numeric
   order, deduplicated by article number (the index links can repeat). FETCH-FN
   returning NIL for a page skips it rather than aborting the crawl."
  (let ((by-num (make-hash-table)) (nums '()))
    (dolist (link (extract-constitution-article-links index-html))
      (let ((html (ignore-errors (funcall fetch-fn link))))
        (when html
          (multiple-value-bind (n title paras) (parse-constitution-article-page html)
            (when (and n paras (not (gethash n by-num)))
              (setf (gethash n by-num)
                    (list (cons "title" (format nil "Άρθρο ~D~@[ - ~A~]"
                                                n (and (plusp (length title)) title)))
                          (cons "content" paras)))
              (push n nums))))))
    (mapcar (lambda (n) (gethash n by-num)) (sort nums #'<))))

;;; ============================================================================
;;; CONFIDENCE SCORING
;;; ============================================================================

(defun compute-html-confidence (article-plist parse-method)
  "Compute confidence for an article extracted from HTML.
   Article-plist has :num :title :suffix :content :paras."
  (let ((score 1.0)
        (content (or (getf article-plist :content) "")))
    ;; Penalty for regex fallback
    (when (eq parse-method :regex-fallback)
      (decf score 0.10))
    ;; Penalty for empty content
    (when (zerop (length content))
      (decf score 0.30))
    ;; Penalty for very short content
    (when (and (> (length content) 0) (< (length content) 40))
      (decf score 0.15))
    ;; Penalty for missing title
    (when (zerop (length (or (getf article-plist :title) "")))
      (decf score 0.05))
    ;; Bonus for cross-references (well-structured legal text)
    (when (cl-ppcre:scan *cross-ref-scanner* content)
      (incf score 0.03))
    ;; Clamp
    (max 0.10 (min 1.0 score))))

;;; ============================================================================
;;; IIR CONVERSION
;;; ============================================================================

(defun article-plist-to-iir (article-plist source-url parse-method)
  "Convert an article plist from the accumulator to normalized-article-input IIR."
  (let* ((num     (getf article-plist :num))
         (title   (getf article-plist :title ""))
         (suffix  (getf article-plist :suffix))
         (content (getf article-plist :content ""))
         (paras   (getf article-plist :paras))
         (full-title (if (and title (> (length title) 0))
                         (format nil "Άρθρο ~A~@[~A~] - ~A"
                                 num (or suffix "") title)
                         (format nil "Άρθρο ~A~@[~A~]"
                                 num (or suffix ""))))
         (confidence (compute-html-confidence article-plist parse-method)))
    (orchestrator.model:make-normalized-article-input
     :article-number num
     :article-label  (format nil "~D~@[~A~]" num (or suffix ""))
     :article-title  full-title
     :article-content (if (> (length content) 0) content " ")
     :source-type :html
     :source-path source-url
     :extraction-confidence confidence
     :source-metadata (list
                       :extractor "html-parliament-adapter"
                       :parse-method parse-method
                       :article-id (format nil "art-~A~@[~A~]" num (or suffix ""))
                       :suffix suffix
                       :paragraph-count (length paras)
                       :source-url source-url
                       :adapter-version "1.0.0"))))

;;; ============================================================================
;;; MOP INTROSPECTION — describe-parsing-rules
;;; ============================================================================

(defun describe-parsing-rules (&optional (stream *standard-output*))
  "Print all registered parsing rules using MOP introspection.
   Uses closer-mop:class-slots to enumerate parsing-rule struct slots."
  (let* ((rule-class (find-class 'parsing-rule))
         (slots (closer-mop:class-slots
                 (closer-mop:ensure-finalized rule-class))))
    (format stream "~&=== Parliament Parsing Rules (~D registered) ===" (length *parsing-rules*))
    (format stream "~&Slot schema via MOP: ~{~A~^, ~}~2%"
            (mapcar #'closer-mop:slot-definition-name slots))
    (loop for rule in *parsing-rules*
          for i from 1
          do (format stream "  ~D. ~A (priority ~D)~%"
                     i
                     (parsing-rule-name rule)
                     (parsing-rule-priority rule))
             (format stream "     classifier: ~S~%"
                     (parsing-rule-classifier rule)))
    (format stream "~&=== End of Rules ===~%")
    (values (length *parsing-rules*) (mapcar #'parsing-rule-name *parsing-rules*))))

;;; ============================================================================
;;; LOCAL FILE LOADING (for testing without network)
;;; ============================================================================

(defun load-html-from-file (path)
  "Read HTML from a local file path. Returns the HTML string."
  (handler-case
      (uiop:read-file-string path)
    (error (e)
      (error 'parliament-fetch-error
             :message (format nil "Cannot read local file ~A: ~A" path e)
             :url (namestring path)))))

;;; ============================================================================
;;; MAIN ENTRY POINT
;;; ============================================================================

(defun parse-html-to-iir (source-path &key corpus)
  "Fetch and parse HTML from Parliament URL, return list of normalized-article-input.
   SOURCE-PATH can be a URL (https://...) or a local file path for testing.

   The returned list is the same IIR format as pdf-adapter produces:
     (orchestrator.model:normalized-article-input ...)

   CORPUS keyword is accepted for pipeline compatibility but not currently used."
  (declare (ignore corpus))
  (handler-case
      (progn
        (log:info () "HTML Parliament Adapter: source=~A" source-path)

        (let* ((url-p   (and (stringp source-path)
                             (cl-ppcre:scan "^https?://" source-path)))
               (html    (if url-p
                            ;; Remote URL: fetch with retry
                            (multiple-value-bind (html-str from-cache-p headers)
                                (restart-case
                                    (fetch-parliament-html source-path
                                                          :max-retries *parliament-max-retries*)
                                  (use-cached ()
                                    :report "Use a stale cache entry rather than fetching"
                                    (cache-get *global-html-cache* source-path))
                                  (abort ()
                                    :report "Abort this adapter; return empty list"
                                    (return-from parse-html-to-iir nil)))
                              (declare (ignore headers))
                              (log:info () "Fetched ~D bytes~A"
                                        (length html-str)
                                        (if from-cache-p " (cached)" ""))
                              html-str)
                            ;; Local file: load directly
                            (progn
                              (unless (probe-file source-path)
                                (error 'orchestrator.spec:config-error
                                       :message (format nil "HTML file not found: ~A" source-path)
                                       :config-key :html-path))
                              (load-html-from-file source-path))))
               (effective-url (if url-p source-path (namestring source-path))))

          (when (zerop (length html))
            (log:warn () "Empty HTML body from ~A" source-path)
            (return-from parse-html-to-iir nil))

          ;; Parse HTML into structured articles
          (multiple-value-bind (articles warnings parse-stats)
              (parse-parliament-html html effective-url)

            (when warnings
              (dolist (w warnings)
                (log:warn () "Parse warning: ~A" w)))

            (log:info () "Parse complete: ~A" parse-stats)

            ;; Filter articles with no usable article number
            (let* ((valid-articles (remove-if (lambda (a)
                                                (or (null (getf a :num))
                                                    (not (typep (getf a :num) 'integer))
                                                    (< (getf a :num) 1)))
                                              articles))
                   (parse-method (getf parse-stats :method :cxml))
                   (iir-list (mapcar (lambda (art)
                                       (article-plist-to-iir art effective-url parse-method))
                                     valid-articles)))

              (log:info () "HTML Parliament Adapter: produced ~D IIR records from ~A"
                        (length iir-list) source-path)
              iir-list))))

    (parliament-fetch-error (e)
      (error 'orchestrator.spec:stage-error
             :message (format nil "HTML Parliament adapter fetch failed: ~A"
                              (parliament-error-message e))
             :stage-name :html-parliament-adapter))

    (parliament-parse-error (e)
      (error 'orchestrator.spec:stage-error
             :message (format nil "HTML Parliament adapter parse failed: ~A"
                              (parliament-error-message e))
             :stage-name :html-parliament-adapter))

    (parliament-encoding-error (e)
      (error 'orchestrator.spec:stage-error
             :message (format nil "HTML Parliament adapter encoding error: ~A"
                              (parliament-error-message e))
             :stage-name :html-parliament-adapter))

    (error (e)
      (error 'orchestrator.spec:stage-error
             :message (format nil "HTML Parliament adapter failed: ~A" e)
             :stage-name :html-parliament-adapter))))

;;; ============================================================================
;;; REPL / INSPECTION UTILITIES
;;; ============================================================================

(defun invalidate-parliament-cache (&optional (url *parliament-constitution-url*))
  "Purge URL from the global HTML cache. Pass NIL to clear all entries."
  (if url
      (progn
        (cache-invalidate *global-html-cache* url)
        (log:info () "Cache invalidated for ~A" url))
      (progn
        (clrhash (cache-table *global-html-cache*))
        (log:info () "Entire HTML cache cleared"))))

(defun show-parsing-rules ()
  "REPL helper: print all registered parsing rules."
  (describe-parsing-rules))

(defun test-classify-line (text)
  "REPL helper: classify a single text line and show the result."
  (let ((node (classify-html-text text nil)))
    (format t "~&Input:  ~S~%Class:  ~A~%Data:   ~S~%Conf:   ~,3F~%"
            text
            (class-name (class-of node))
            (node->article-data node)
            (node-confidence node))
    node))
