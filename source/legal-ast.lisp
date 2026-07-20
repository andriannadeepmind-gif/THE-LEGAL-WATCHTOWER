;;;; source/legal-ast.lisp
;;;; ============================================================================
;;;; LEGAL-AST - Layer 4 Structural AST for Greek Legal Documents
;;;; ============================================================================
;;;;
;;;; LAYER 4: CANONICAL TEXT → STRUCTURAL AST
;;;;
;;;; This module builds the final Abstract Syntax Tree for Greek legal documents.
;;;; The AST represents the hierarchical structure of legislation.
;;;;
;;;; AST STRUCTURE:
;;;;   DOCUMENT
;;;;     ├── PREAMBLE (optional)
;;;;     │     └── TITLE
;;;;     │     └── INTRODUCTION
;;;;     ├── ARTICLE*
;;;;     │     ├── article-number
;;;;     │     ├── article-title (optional)
;;;;     │     └── PARAGRAPH*
;;;;     │           ├── paragraph-number
;;;;     │           └── POINT*
;;;;     │                 ├── point-marker (α, β, γ...)
;;;;     │                 └── content
;;;;     └── CLOSING
;;;;           └── SIGNATURE*
;;;;
;;;; DESIGN PRINCIPLES:
;;;;   - SEMANTIC: AST nodes have legal meaning
;;;;   - NAVIGABLE: Parent/child links for traversal
;;;;   - TRACEABLE: Every node has trace-info
;;;;   - SERIALIZABLE: Can be exported to XML/RDF
;;;;
;;;; ============================================================================
;;;; COMMON LISP FEATURES UTILIZED
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CLOS (Classes)           │ AST node hierarchy with inheritance          │
;;;; │                          │ • ast-node (base)                            │
;;;; │                          │ • document-node, article-node, etc.          │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ GENERIC FUNCTIONS        │ Polymorphic AST operations                   │
;;;; │                          │ • ast-children, ast-text, ast-to-form        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Parsing with position tracking               │
;;;; │                          │ (values ast-node remaining-blocks)           │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MACROS                   │ AST construction DSL                         │
;;;; │                          │ • defastnode: define node types              │
;;;; │                          │ • with-ast-construction                      │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(defpackage :orchestrator.legal-ast
  (:use :cl)
  (:import-from :orchestrator.trace-core
                #:trace-info
                #:make-trace-info
                #:bundle-traces
                #:extend-trace
                #:trace-id)
  (:import-from :orchestrator.text-canonicalizer
                #:canonical-block
                #:canonical-text
                #:canonical-block-type
                #:canonical-trace
                #:canonical-id)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; BASE AST NODE
   ;; ══════════════════════════════════════════════════════════════════
   #:ast-node
   #:ast-id
   #:ast-type
   #:ast-parent
   #:ast-children
   #:ast-text
   #:ast-trace
   #:ast-source-blocks

   ;; ══════════════════════════════════════════════════════════════════
   ;; DOCUMENT STRUCTURE NODES
   ;; ══════════════════════════════════════════════════════════════════
   #:document-node
   #:make-document-node
   #:document-title
   #:document-preamble
   #:document-articles
   #:document-closing

   #:preamble-node
   #:make-preamble-node

   #:article-node
   #:make-article-node
   #:article-number
   #:article-title
   #:article-paragraphs

   #:paragraph-node
   #:make-paragraph-node
   #:paragraph-number
   #:paragraph-points
   #:paragraph-content

   #:point-node
   #:make-point-node
   #:point-marker
   #:point-content

   #:closing-node
   #:make-closing-node
   #:closing-signatures

   #:signature-node
   #:make-signature-node
   #:signature-name
   #:signature-role

   ;; ══════════════════════════════════════════════════════════════════
   ;; HIERARCHICAL STRUCTURE NODES (ΜΕΡΟΣ, ΤΜΗΜΑ, ΚΕΦΑΛΑΙΟ)
   ;; ══════════════════════════════════════════════════════════════════
   #:part-node                         ; ΜΕΡΟΣ
   #:make-part-node
   #:part-number
   #:part-title
   #:part-sections

   #:division-node                     ; ΤΜΗΜΑ
   #:make-division-node
   #:division-number
   #:division-title
   #:division-chapters

   #:chapter-node                      ; ΚΕΦΑΛΑΙΟ
   #:make-chapter-node
   #:chapter-number
   #:chapter-title
   #:chapter-articles

   ;; ══════════════════════════════════════════════════════════════════
   ;; CROSS-REFERENCE NODES (Ν., ΠΔ, ΦΕΚ, Άρθρο X του Ν. Y)
   ;; ══════════════════════════════════════════════════════════════════
   #:cross-reference-node
   #:make-cross-reference-node
   #:xref-type                          ; :law, :presidential-decree, :fek, :article, :paragraph
   #:xref-target-number                 ; The number being referenced
   #:xref-target-year                   ; Year if applicable
   #:xref-target-fek                    ; ΦΕΚ reference if known
   #:xref-target-article                ; Article within the referenced law
   #:xref-original-text                 ; Original text as it appeared
   #:xref-confidence                    ; Parsing confidence 0.0-1.0

   ;; ══════════════════════════════════════════════════════════════════
   ;; AMENDMENT NODES (Τροποποίηση, Αντικατάσταση, Κατάργηση, Προσθήκη)
   ;; ══════════════════════════════════════════════════════════════════
   #:amendment-node
   #:make-amendment-node
   #:amendment-type                     ; :modification, :replacement, :abolition, :addition
   #:amendment-target-law               ; Target law reference
   #:amendment-target-article           ; Target article
   #:amendment-target-paragraph         ; Target paragraph
   #:amendment-effective-date           ; When amendment takes effect
   #:amendment-new-text                 ; New text (for replacements/additions)

   #:transitional-node                  ; Μεταβατικές διατάξεις
   #:make-transitional-node
   #:transitional-duration
   #:transitional-conditions

   #:effective-date-node                ; Έναρξη ισχύος
   #:make-effective-date-node
   #:effective-date
   #:effective-conditions

   ;; ══════════════════════════════════════════════════════════════════
   ;; SUB-POINT NODES (αα, ββ, i, ii, etc.)
   ;; ══════════════════════════════════════════════════════════════════
   #:sub-point-node
   #:make-sub-point-node
   #:sub-point-marker
   #:sub-point-level                    ; Nesting level (1, 2, 3...)
   #:sub-point-content
   #:sub-point-children

   ;; ══════════════════════════════════════════════════════════════════
   ;; CASE MARKERS (αα', ββ', i', ii')
   ;; ══════════════════════════════════════════════════════════════════
   #:case-node
   #:make-case-node
   #:case-marker
   #:case-content

   ;; ══════════════════════════════════════════════════════════════════
   ;; GENERIC FUNCTIONS
   ;; ══════════════════════════════════════════════════════════════════
   #:ast-to-form
   #:ast-to-xml
   #:ast-walk
   #:ast-find

   ;; ══════════════════════════════════════════════════════════════════
   ;; AST CONSTRUCTION
   ;; ══════════════════════════════════════════════════════════════════
   #:build-ast
   #:build-ast-from-blocks
   #:clean-paragraph-content

   ;; ══════════════════════════════════════════════════════════════════
   ;; MACROS
   ;; ══════════════════════════════════════════════════════════════════
   #:defastnode
   #:with-ast-construction
   #:with-ast-restarts

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONDITIONS
   ;; ══════════════════════════════════════════════════════════════════
   #:ast-error
   #:ast-error-message
   #:ast-error-node-id
   #:ast-structure-error
   #:ast-missing-content-error

   ;; ══════════════════════════════════════════════════════════════════
   ;; VALIDATION (GENERIC FUNCTIONS)
   ;; ══════════════════════════════════════════════════════════════════
   #:ast-validate

   ;; ══════════════════════════════════════════════════════════════════
   ;; SPECIAL VARIABLES
   ;; ══════════════════════════════════════════════════════════════════
   #:*current-document*
   #:*current-article*
   #:*current-paragraph*
   #:*ast-construction-depth*

   ;; ══════════════════════════════════════════════════════════════════
   ;; HOMOICONICITY
   ;; ══════════════════════════════════════════════════════════════════
   #:form-to-ast
   #:ast-decode-error
   #:ast-to-readable-string
   #:save-ast-to-file
   #:load-ast-from-file

   ;; ══════════════════════════════════════════════════════════════════
   ;; MULTIPLE VALUES / STATISTICS
   ;; ══════════════════════════════════════════════════════════════════
   #:parse-article-with-context
   #:ast-statistics

   ;; ══════════════════════════════════════════════════════════════════
   ;; XML EXPORT
   ;; ══════════════════════════════════════════════════════════════════
   #:ast-to-xml

   ;; ══════════════════════════════════════════════════════════════════
   ;; COPY PROTOCOL
   ;; ══════════════════════════════════════════════════════════════════
   #:ast-copy

   ;; ══════════════════════════════════════════════════════════════════
   ;; CROSS-REFERENCE EXTRACTION (NSA-GRADE)
   ;; ══════════════════════════════════════════════════════════════════
   #:extract-cross-references
   #:extract-amendments
   #:parse-law-reference
   #:parse-fek-reference
   #:+greek-law-reference-patterns+
   #:+greek-amendment-patterns+))

(in-package :orchestrator.legal-ast)

;;; ============================================================================
;;; AST NODE COUNTER
;;; ============================================================================

(defvar *ast-node-counter* 0)

(defun generate-ast-id (prefix)
  (format nil "~A-~A" prefix (incf *ast-node-counter*)))

;;; ============================================================================
;;; BASE AST NODE CLASS
;;; ============================================================================

(defclass ast-node ()
  ((id
    :accessor ast-id
    :initarg :id
    :type string
    :documentation "Unique identifier for this AST node")

   (node-type
    :accessor ast-type
    :initarg :node-type
    :initform :unknown
    :type keyword
    :documentation "Node type: :document, :article, :paragraph, :point, etc.")

   (parent
    :accessor ast-parent
    :initarg :parent
    :initform nil
    :type (or null ast-node)
    :documentation "Parent node in AST")

   (children
    :accessor ast-children
    :initarg :children
    :initform '()
    :type list
    :documentation "Child nodes")

   (text
    :accessor ast-text
    :initarg :text
    :initform ""
    :type string
    :documentation "Text content of this node")

   (trace
    :accessor ast-trace
    :initarg :trace
    :initform nil
    :type (or null trace-info)
    :documentation "Traceability information")

   (source-blocks
    :accessor ast-source-blocks
    :initarg :source-blocks
    :initform '()
    :type list
    :documentation "List of canonical-block IDs that produced this node"))

  (:documentation "Base class for all AST nodes.

   All legal document structure nodes inherit from this."))

(defmethod print-object ((node ast-node) stream)
  (print-unreadable-object (node stream :type t :identity nil)
    (format stream "~A ~A"
            (ast-id node)
            (ast-type node))))

;;; ============================================================================
;;; DOCUMENT NODE
;;; ============================================================================

(defclass document-node (ast-node)
  ((title
    :accessor document-title
    :initarg :title
    :initform nil
    :type (or null string))

   (preamble
    :accessor document-preamble
    :initarg :preamble
    :initform nil
    :type (or null preamble-node))

   (articles
    :accessor document-articles
    :initarg :articles
    :initform '()
    :type list)

   (closing
    :accessor document-closing
    :initarg :closing
    :initform nil
    :type (or null closing-node)))

  (:default-initargs :node-type :document)
  (:documentation "Root node for a legal document."))

(defun make-document-node (&key title preamble articles closing source-blocks)
  (let* ((id (generate-ast-id "DOC"))
         (trace (when source-blocks
                  (let ((traces (remove nil
                                        (mapcar #'canonical-trace source-blocks))))
                    (when traces
                      (bundle-traces traces :layer :ast)))))
         (node (make-instance 'document-node
                              :id id
                              :title title
                              :preamble preamble
                              :articles (or articles '())
                              :closing closing
                              :source-blocks (mapcar #'canonical-id source-blocks)
                              :trace trace)))
    ;; Set parent references
    (when preamble (setf (ast-parent preamble) node))
    (dolist (article articles)
      (setf (ast-parent article) node))
    (when closing (setf (ast-parent closing) node))
    ;; Build children list
    (setf (ast-children node)
          (remove nil (append (list preamble) articles (list closing))))
    node))

;;; ============================================================================
;;; PREAMBLE NODE
;;; ============================================================================

(defclass preamble-node (ast-node)
  ()
  (:default-initargs :node-type :preamble)
  (:documentation "Preamble section before articles."))

(defun make-preamble-node (&key text source-blocks)
  (let ((id (generate-ast-id "PRE")))
    (make-instance 'preamble-node
                   :id id
                   :text (or text "")
                   :source-blocks (mapcar #'canonical-id source-blocks))))

;;; ============================================================================
;;; ARTICLE NODE
;;; ============================================================================

(defclass article-node (ast-node)
  ((article-number
    :accessor article-number
    :initarg :article-number
    :initform nil
    :type (or null string integer)
    :documentation "Article number (e.g., 1, 2, '1α')")

   (article-title
    :accessor article-title
    :initarg :article-title
    :initform nil
    :type (or null string)
    :documentation "Optional article title")

   (paragraphs
    :accessor article-paragraphs
    :initarg :paragraphs
    :initform '()
    :type list
    :documentation "List of paragraph-node"))

  (:default-initargs :node-type :article)
  (:documentation "An article (Άρθρο) in the legal document."))

(defun make-article-node (&key number title paragraphs text source-blocks)
  (let* ((id (generate-ast-id "ART"))
         (node (make-instance 'article-node
                              :id id
                              :article-number number
                              :article-title title
                              :paragraphs (or paragraphs '())
                              :text (or text "")
                              :source-blocks (when source-blocks
                                               (mapcar #'canonical-id source-blocks)))))
    ;; Set parent references
    (dolist (para paragraphs)
      (setf (ast-parent para) node))
    (setf (ast-children node) paragraphs)
    node))

;;; ============================================================================
;;; PARAGRAPH NODE
;;; ============================================================================

(defclass paragraph-node (ast-node)
  ((paragraph-number
    :accessor paragraph-number
    :initarg :paragraph-number
    :initform nil
    :type (or null string integer))

   (content
    :accessor paragraph-content
    :initarg :content
    :initform ""
    :type string
    :documentation "Main paragraph text")

   (points
    :accessor paragraph-points
    :initarg :points
    :initform '()
    :type list
    :documentation "List of point-node (α, β, γ...)"))

  (:default-initargs :node-type :paragraph)
  (:documentation "A numbered paragraph within an article."))

(defun make-paragraph-node (&key number content points text source-blocks)
  (let* ((id (generate-ast-id "PAR"))
         (node (make-instance 'paragraph-node
                              :id id
                              :paragraph-number number
                              :content (or content "")
                              :points (or points '())
                              :text (or text content "")
                              :source-blocks (when source-blocks
                                               (mapcar #'canonical-id source-blocks)))))
    ;; Set parent references
    (dolist (point points)
      (setf (ast-parent point) node))
    (setf (ast-children node) points)
    node))

;;; ============================================================================
;;; POINT NODE
;;; ============================================================================

(defclass point-node (ast-node)
  ((marker
    :accessor point-marker
    :initarg :marker
    :initform nil
    :type (or null string character)
    :documentation "Point marker: α, β, γ, etc.")

   (content
    :accessor point-content
    :initarg :content
    :initform ""
    :type string))

  (:default-initargs :node-type :point)
  (:documentation "A lettered point (α, β, γ) within a paragraph."))

(defun make-point-node (&key marker content text source-blocks)
  (make-instance 'point-node
                 :id (generate-ast-id "PNT")
                 :marker marker
                 :content (or content "")
                 :text (or text content "")
                 :source-blocks (when source-blocks
                                  (mapcar #'canonical-id source-blocks))))

;;; ============================================================================
;;; CLOSING NODE
;;; ============================================================================

(defclass closing-node (ast-node)
  ((signatures
    :accessor closing-signatures
    :initarg :signatures
    :initform '()
    :type list))

  (:default-initargs :node-type :closing)
  (:documentation "Closing section with signatures."))

(defun make-closing-node (&key signatures text source-blocks)
  (let* ((id (generate-ast-id "CLS"))
         (node (make-instance 'closing-node
                              :id id
                              :signatures (or signatures '())
                              :text (or text "")
                              :source-blocks (when source-blocks
                                               (mapcar #'canonical-id source-blocks)))))
    (dolist (sig signatures)
      (setf (ast-parent sig) node))
    (setf (ast-children node) signatures)
    node))

;;; ============================================================================
;;; SIGNATURE NODE
;;; ============================================================================

(defclass signature-node (ast-node)
  ((name
    :accessor signature-name
    :initarg :name
    :initform nil
    :type (or null string))

   (role
    :accessor signature-role
    :initarg :role
    :initform nil
    :type (or null string)))

  (:default-initargs :node-type :signature)
  (:documentation "A signature in the closing section."))

(defun make-signature-node (&key name role text source-blocks)
  (make-instance 'signature-node
                 :id (generate-ast-id "SIG")
                 :name name
                 :role role
                 :text (or text "")
                 :source-blocks (when source-blocks
                                  (mapcar #'canonical-id source-blocks))))

;;; ============================================================================
;;; HIERARCHICAL STRUCTURE NODES (NSA-GRADE - Greek Legal Hierarchy)
;;; ============================================================================
;;;
;;; Greek legal documents have a strict hierarchy:
;;;   ΜΕΡΟΣ (Part) → ΤΜΗΜΑ (Division) → ΚΕΦΑΛΑΙΟ (Chapter) → Άρθρο (Article)
;;;
;;; This hierarchy must be preserved for perfect AST representation.
;;; ============================================================================

;;; ----------------------------------------------------------------------------
;;; PART NODE (ΜΕΡΟΣ)
;;; ----------------------------------------------------------------------------

(defclass part-node (ast-node)
  ((part-number
    :accessor part-number
    :initarg :part-number
    :initform nil
    :type (or null string)
    :documentation "Part identifier (e.g., 'ΠΡΩΤΟ', 'ΔΕΥΤΕΡΟ', 'Α', 'Β')")

   (part-title
    :accessor part-title
    :initarg :part-title
    :initform nil
    :type (or null string)
    :documentation "Part title (e.g., 'ΓΕΝΙΚΕΣ ΔΙΑΤΑΞΕΙΣ')")

   (sections
    :accessor part-sections
    :initarg :sections
    :initform '()
    :type list
    :documentation "Child divisions (ΤΜΗΜΑ) or chapters (ΚΕΦΑΛΑΙΟ)"))

  (:default-initargs :node-type :part)
  (:documentation "ΜΕΡΟΣ - Highest structural division in Greek legal documents."))

(defun make-part-node (&key number title sections text source-blocks)
  (let* ((id (generate-ast-id "MEROS"))
         (node (make-instance 'part-node
                              :id id
                              :part-number number
                              :part-title title
                              :sections (or sections '())
                              :text (or text "")
                              :source-blocks (when source-blocks
                                               (mapcar #'canonical-id source-blocks)))))
    (dolist (section sections)
      (setf (ast-parent section) node))
    (setf (ast-children node) sections)
    node))

;;; ----------------------------------------------------------------------------
;;; DIVISION NODE (ΤΜΗΜΑ)
;;; ----------------------------------------------------------------------------

(defclass division-node (ast-node)
  ((division-number
    :accessor division-number
    :initarg :division-number
    :initform nil
    :type (or null string)
    :documentation "Division identifier (e.g., 'ΠΡΩΤΟ', 'Α')")

   (division-title
    :accessor division-title
    :initarg :division-title
    :initform nil
    :type (or null string))

   (chapters
    :accessor division-chapters
    :initarg :chapters
    :initform '()
    :type list
    :documentation "Child chapters (ΚΕΦΑΛΑΙΟ)"))

  (:default-initargs :node-type :division)
  (:documentation "ΤΜΗΜΑ - Division within a Part."))

(defun make-division-node (&key number title chapters text source-blocks)
  (let* ((id (generate-ast-id "TMIMA"))
         (node (make-instance 'division-node
                              :id id
                              :division-number number
                              :division-title title
                              :chapters (or chapters '())
                              :text (or text "")
                              :source-blocks (when source-blocks
                                               (mapcar #'canonical-id source-blocks)))))
    (dolist (chapter chapters)
      (setf (ast-parent chapter) node))
    (setf (ast-children node) chapters)
    node))

;;; ----------------------------------------------------------------------------
;;; CHAPTER NODE (ΚΕΦΑΛΑΙΟ)
;;; ----------------------------------------------------------------------------

(defclass chapter-node (ast-node)
  ((chapter-number
    :accessor chapter-number
    :initarg :chapter-number
    :initform nil
    :type (or null string)
    :documentation "Chapter identifier (e.g., 'Α', 'Β', '1', '2')")

   (chapter-title
    :accessor chapter-title
    :initarg :chapter-title
    :initform nil
    :type (or null string))

   (articles
    :accessor chapter-articles
    :initarg :articles
    :initform '()
    :type list
    :documentation "Articles within this chapter"))

  (:default-initargs :node-type :chapter)
  (:documentation "ΚΕΦΑΛΑΙΟ - Chapter containing articles."))

(defun make-chapter-node (&key number title articles text source-blocks)
  (let* ((id (generate-ast-id "KEF"))
         (node (make-instance 'chapter-node
                              :id id
                              :chapter-number number
                              :chapter-title title
                              :articles (or articles '())
                              :text (or text "")
                              :source-blocks (when source-blocks
                                               (mapcar #'canonical-id source-blocks)))))
    (dolist (article articles)
      (setf (ast-parent article) node))
    (setf (ast-children node) articles)
    node))

;;; ============================================================================
;;; CROSS-REFERENCE NODES (NSA-GRADE - Greek Legal Citations)
;;; ============================================================================
;;;
;;; Greek legal cross-references follow specific patterns:
;;;   - Ν. 1234/2020 (Law)
;;;   - ΠΔ 56/2019 (Presidential Decree)
;;;   - ΦΕΚ Α' 123/2020 (Government Gazette)
;;;   - άρθρο 5 του Ν. 1234/2020 (Article of Law)
;;;   - παρ. 3 του άρθρου 5 του Ν. 1234/2020 (Paragraph of Article of Law)
;;;
;;; ============================================================================

(defclass cross-reference-node (ast-node)
  ((xref-type
    :accessor xref-type
    :initarg :xref-type
    :initform :unknown
    :type keyword
    :documentation "Reference type: :law :presidential-decree :fek :article :paragraph :eu-directive :eu-regulation")

   (target-number
    :accessor xref-target-number
    :initarg :target-number
    :initform nil
    :type (or null string integer)
    :documentation "The number of the referenced entity")

   (target-year
    :accessor xref-target-year
    :initarg :target-year
    :initform nil
    :type (or null integer string)
    :documentation "Year of the referenced law/decree")

   (target-fek
    :accessor xref-target-fek
    :initarg :target-fek
    :initform nil
    :type (or null string)
    :documentation "ΦΕΚ publication reference if known")

   (target-article
    :accessor xref-target-article
    :initarg :target-article
    :initform nil
    :type (or null string integer)
    :documentation "Article number within referenced law")

   (target-paragraph
    :accessor xref-target-paragraph
    :initarg :target-paragraph
    :initform nil
    :type (or null string integer)
    :documentation "Paragraph number within referenced article")

   (original-text
    :accessor xref-original-text
    :initarg :original-text
    :initform ""
    :type string
    :documentation "Original text as it appeared in the document")

   (confidence
    :accessor xref-confidence
    :initarg :confidence
    :initform 1.0
    :type (real 0.0 1.0)
    :documentation "Parsing confidence score"))

  (:default-initargs :node-type :cross-reference)
  (:documentation "Cross-reference to another legal document or provision."))

(defun make-cross-reference-node (&key type target-number target-year target-fek
                                        target-article target-paragraph
                                        original-text confidence source-blocks)
  (make-instance 'cross-reference-node
                 :id (generate-ast-id "XREF")
                 :xref-type (or type :unknown)
                 :target-number target-number
                 :target-year target-year
                 :target-fek target-fek
                 :target-article target-article
                 :target-paragraph target-paragraph
                 :original-text (or original-text "")
                 :text (or original-text "")
                 :confidence (or confidence 1.0)
                 :source-blocks (when source-blocks
                                  (mapcar #'canonical-id source-blocks))))

;;; ============================================================================
;;; AMENDMENT NODES (NSA-GRADE - Greek Legal Modifications)
;;; ============================================================================
;;;
;;; Greek amendment patterns:
;;;   - Τροποποίηση (Modification)
;;;   - Αντικατάσταση (Replacement)
;;;   - Κατάργηση (Abolition/Repeal)
;;;   - Προσθήκη (Addition)
;;;   - Αναστολή (Suspension)
;;;
;;; ============================================================================

(defclass amendment-node (ast-node)
  ((amendment-type
    :accessor amendment-type
    :initarg :amendment-type
    :initform :modification
    :type keyword
    :documentation ":modification :replacement :abolition :addition :suspension")

   (target-law
    :accessor amendment-target-law
    :initarg :target-law
    :initform nil
    :type (or null cross-reference-node string)
    :documentation "The law being amended")

   (target-article
    :accessor amendment-target-article
    :initarg :target-article
    :initform nil
    :type (or null string integer)
    :documentation "Target article number")

   (target-paragraph
    :accessor amendment-target-paragraph
    :initarg :target-paragraph
    :initform nil
    :type (or null string integer)
    :documentation "Target paragraph number")

   (target-point
    :accessor amendment-target-point
    :initarg :target-point
    :initform nil
    :type (or null string)
    :documentation "Target point (α, β, γ...)")

   (effective-date
    :accessor amendment-effective-date
    :initarg :effective-date
    :initform nil
    :type (or null string)
    :documentation "When the amendment takes effect")

   (new-text
    :accessor amendment-new-text
    :initarg :new-text
    :initform nil
    :type (or null string)
    :documentation "New text for replacement/addition"))

  (:default-initargs :node-type :amendment)
  (:documentation "An amendment (τροποποίηση) to existing legislation."))

(defun make-amendment-node (&key type target-law target-article target-paragraph
                                  target-point effective-date new-text text source-blocks)
  (make-instance 'amendment-node
                 :id (generate-ast-id "AMEND")
                 :amendment-type (or type :modification)
                 :target-law target-law
                 :target-article target-article
                 :target-paragraph target-paragraph
                 :target-point target-point
                 :effective-date effective-date
                 :new-text new-text
                 :text (or text "")
                 :source-blocks (when source-blocks
                                  (mapcar #'canonical-id source-blocks))))

;;; ----------------------------------------------------------------------------
;;; TRANSITIONAL NODE (Μεταβατικές Διατάξεις)
;;; ----------------------------------------------------------------------------

(defclass transitional-node (ast-node)
  ((duration
    :accessor transitional-duration
    :initarg :duration
    :initform nil
    :type (or null string)
    :documentation "Duration of transitional period")

   (conditions
    :accessor transitional-conditions
    :initarg :conditions
    :initform '()
    :type list
    :documentation "Conditions for transitional application"))

  (:default-initargs :node-type :transitional)
  (:documentation "Transitional provisions (Μεταβατικές διατάξεις)."))

(defun make-transitional-node (&key duration conditions text source-blocks)
  (make-instance 'transitional-node
                 :id (generate-ast-id "TRANS")
                 :duration duration
                 :conditions (or conditions '())
                 :text (or text "")
                 :source-blocks (when source-blocks
                                  (mapcar #'canonical-id source-blocks))))

;;; ----------------------------------------------------------------------------
;;; EFFECTIVE DATE NODE (Έναρξη Ισχύος)
;;; ----------------------------------------------------------------------------

(defclass effective-date-node (ast-node)
  ((effective-date
    :accessor effective-date
    :initarg :effective-date
    :initform nil
    :type (or null string)
    :documentation "Date when law takes effect")

   (conditions
    :accessor effective-conditions
    :initarg :conditions
    :initform '()
    :type list
    :documentation "Conditions for effect"))

  (:default-initargs :node-type :effective-date)
  (:documentation "Effective date provision (Έναρξη ισχύος)."))

(defun make-effective-date-node (&key date conditions text source-blocks)
  (make-instance 'effective-date-node
                 :id (generate-ast-id "EFFECT")
                 :effective-date date
                 :conditions (or conditions '())
                 :text (or text "")
                 :source-blocks (when source-blocks
                                  (mapcar #'canonical-id source-blocks))))

;;; ============================================================================
;;; SUB-POINT NODES (NSA-GRADE - Nested Greek Lettering)
;;; ============================================================================
;;;
;;; Greek legal sub-points use multiple nesting levels:
;;;   Level 1: α) β) γ) δ) ε) ζ) η) θ) ι) κ) λ) μ) ν) ξ) ο) π) ρ) σ) τ) υ) φ) χ) ψ) ω)
;;;   Level 2: αα) ββ) γγ) or αα' ββ' γγ'
;;;   Level 3: i) ii) iii) iv) or 1) 2) 3)
;;;
;;; ============================================================================

(defclass sub-point-node (ast-node)
  ((marker
    :accessor sub-point-marker
    :initarg :marker
    :initform nil
    :type (or null string)
    :documentation "Sub-point marker (αα, ββ, i, ii, etc.)")

   (level
    :accessor sub-point-level
    :initarg :level
    :initform 2
    :type integer
    :documentation "Nesting level (2=αα, 3=i)")

   (content
    :accessor sub-point-content
    :initarg :content
    :initform ""
    :type string)

   (children
    :accessor sub-point-children
    :initarg :children
    :initform '()
    :type list
    :documentation "Further nested sub-points"))

  (:default-initargs :node-type :sub-point)
  (:documentation "Nested sub-point (αα, ββ, i, ii)."))

(defun make-sub-point-node (&key marker level content children text source-blocks)
  (let* ((id (generate-ast-id "SUBPNT"))
         (node (make-instance 'sub-point-node
                              :id id
                              :marker marker
                              :level (or level 2)
                              :content (or content "")
                              :children (or children '())
                              :text (or text content "")
                              :source-blocks (when source-blocks
                                               (mapcar #'canonical-id source-blocks)))))
    (dolist (child children)
      (setf (ast-parent child) node))
    (setf (ast-children node) children)
    node))

;;; ----------------------------------------------------------------------------
;;; CASE NODE (αα', ββ', i', ii')
;;; ----------------------------------------------------------------------------

(defclass case-node (ast-node)
  ((marker
    :accessor case-marker
    :initarg :marker
    :initform nil
    :type (or null string))

   (content
    :accessor case-content
    :initarg :content
    :initform ""
    :type string))

  (:default-initargs :node-type :case)
  (:documentation "Case marker within a point."))

(defun make-case-node (&key marker content text source-blocks)
  (make-instance 'case-node
                 :id (generate-ast-id "CASE")
                 :marker marker
                 :content (or content "")
                 :text (or text content "")
                 :source-blocks (when source-blocks
                                  (mapcar #'canonical-id source-blocks))))

;;; ============================================================================
;;; GENERIC FUNCTIONS
;;; ============================================================================

;;; [ARCH Phase 1] ΑΝΑΒΑΘΜΙΣΗ (όχι αφαίρεση): το παλιό ζεύγος έγραφε
;;; (make-instance …)/(make-X-node …) ΚΩΔΙΚΑ (+ (list …), (quote …)) και τον
;;; ΕΚΤΕΛΟΥΣΕ με form-to-ast = (eval form) / load-ast-from-file = (eval (read stream))
;;; / provide-node restart = (eval (read)) — «HOMOICONICITY: the file IS a Lisp program»
;;; = RCE seat. Η ΙΚΑΝΟΤΗΤΑ (serialize↔reconstruct/persist AST) διατηρείται με τα ΙΔΙΑ
;;; exported ονόματα· ο ΜΗΧΑΝΙΣΜΟΣ αναβαθμίζεται στην data-only + safe-read + typed-decoder
;;; μορφή: ast-to-form παράγει DATA-ONLY versioned plists, form-to-ast είναι typed decoder
;;; ΧΩΡΙΣ eval, save/load περνούν από τη ΜΙΑ safe-read έδρα. data ≠ code· reconstruct ≠ eval.

(defparameter +ast-node-class-alist+
  '((:ast-node . ast-node) (:document-node . document-node) (:preamble-node . preamble-node)
    (:article-node . article-node) (:paragraph-node . paragraph-node) (:point-node . point-node)
    (:closing-node . closing-node) (:signature-node . signature-node) (:part-node . part-node)
    (:division-node . division-node) (:chapter-node . chapter-node)
    (:cross-reference-node . cross-reference-node) (:amendment-node . amendment-node)
    (:transitional-node . transitional-node) (:effective-date-node . effective-date-node)
    (:sub-point-node . sub-point-node) (:case-node . case-node))
  "Κλειστό allowlist: keyword type-tag → class symbol. ΜΟΝΟ αυτές οι κλάσεις μπορούν να
   ανασυγκροτηθούν — κανένα input-derived intern σε class symbol (fail-closed).")

(defparameter +ast-schema-tags+
  '(:ast-node/1 :document-node/1 :article-node/1 :paragraph-node/1 :point-node/1)
  "Έγκυρα data-only tags των ast-to-form μορφών.")

(define-condition ast-decode-error (error)
  ((why :initarg :why :reader ast-decode-error-why :initform "μη αναγνώσιμο AST datum"))
  (:report (lambda (c s) (format s "ast-decode: ~A" (ast-decode-error-why c)))))

(defun %ast-marker-to-data (m)
  "Point marker → data-only: string pass-through· character → (:char/1 \"x\") (ΩΣΤΕ να μη
   χρειάζεται #\\ literal που η safe-read απαγορεύει)· nil → nil."
  (typecase m
    (null nil) (string m)
    (character (list :char/1 (string m)))
    (t (error 'ast-decode-error :why (format nil "μη serializable marker: ~S" m)))))

(defun %ast-data-to-marker (d)
  "data → point marker: nil/string pass-through· (:char/1 \"x\") → character."
  (cond ((null d) nil) ((stringp d) d)
        ((and (consp d) (eq (first d) :char/1) (stringp (second d)) (= 1 (length (second d))))
         (char (second d) 0))
        (t (error 'ast-decode-error :why (format nil "μη έγκυρος marker: ~S" d)))))

(defgeneric ast-to-form (node)
  (:documentation "Serialize AST node σε DATA-ONLY versioned plist (όχι κώδικα).
   Αντίστροφο: form-to-ast (typed decoder, καμία eval). Χρησιμοποιείται και για display."))

(defmethod ast-to-form ((node ast-node))
  (list :ast-node/1
        :type (intern (symbol-name (type-of node)) :keyword)
        :id (ast-id node)
        :node-type (ast-type node)
        :text (ast-text node)
        :source-blocks (ast-source-blocks node)))

(defmethod ast-to-form ((node document-node))
  (list :document-node/1
        :title (document-title node)
        :preamble (when (document-preamble node) (ast-to-form (document-preamble node)))
        :articles (mapcar #'ast-to-form (document-articles node))
        :closing (when (document-closing node) (ast-to-form (document-closing node)))))

(defmethod ast-to-form ((node article-node))
  (list :article-node/1
        :number (article-number node)
        :title (article-title node)
        :paragraphs (mapcar #'ast-to-form (article-paragraphs node))
        :text (ast-text node)))

(defmethod ast-to-form ((node paragraph-node))
  (list :paragraph-node/1
        :number (paragraph-number node)
        :content (paragraph-content node)
        :points (mapcar #'ast-to-form (paragraph-points node))))

(defmethod ast-to-form ((node point-node))
  (list :point-node/1
        :marker (%ast-marker-to-data (point-marker node))
        :content (point-content node)))

;;; ============================================================================
;;; AST TRAVERSAL
;;; ============================================================================

(defun ast-walk (node fn &key (order :pre))
  "Walk AST tree, applying FN to each node.

   Args:
     node: Root node to start from
     fn: Function (lambda (node depth) ...)
     order: :pre (parent first) or :post (children first)

   Returns: nil"
  (labels ((walk (n depth)
             (when (eq order :pre)
               (funcall fn n depth))
             (dolist (child (ast-children n))
               (walk child (1+ depth)))
             (when (eq order :post)
               (funcall fn n depth))))
    (walk node 0))
  nil)

(defun ast-find (node predicate)
  "Find first node matching PREDICATE.

   Returns: node or NIL"
  (when (funcall predicate node)
    (return-from ast-find node))
  (dolist (child (ast-children node))
    (let ((found (ast-find child predicate)))
      (when found
        (return-from ast-find found))))
  nil)

;;; ============================================================================
;;; AST CONSTRUCTION FROM CANONICAL BLOCKS
;;; ============================================================================

(defun extract-article-number (text)
  "Extract article number from 'Άρθρο X' text."
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings "[ΆΑ]ρθρ[οό]\\s*(\\d+[αβγδ]?)" text)
    (when match
      (aref groups 0))))

(defun extract-paragraph-number (text)
  "Extract paragraph number from '1.' or '2.' pattern."
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings "^\\s*(\\d+)[.):]" text)
    (when match
      (aref groups 0))))

(defun extract-point-marker (text)
  "Extract point marker from 'α)' or 'β.' pattern."
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings "^\\s*([α-ω])[.):]" text)
    (when match
      (aref groups 0))))

(defparameter +filtered-block-types+
  '(:header :footer :page-number :section-header)
  "Block types that should be filtered out from AST (page elements, not content).
   Includes:
     :header - Page headers (ΕΦΗΜΕΡΙΔΑ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ, Τεύχος, etc.)
     :footer - Page footers (dates, page numbers at bottom)
     :page-number - Standalone page numbers
     :section-header - ΜΕΡΟΣ, ΚΕΦΑΛΑΙΟ, ΤΜΗΜΑ headers (handled separately)")

;;; ============================================================================
;;; PARAGRAPH CONTENT CLEANUP (NSA-GRADE - Final Safety Net)
;;; ============================================================================
;;;
;;; Even after classification and canonicalization, some FEK noise may slip
;;; through. This cleanup function removes common patterns from paragraph
;;; content as a final safety net.
;;;
;;; ============================================================================

(defparameter +paragraph-noise-patterns+
  '(;; ═══════════════════════════════════════════════════════════════════
    ;; FEK HEADERS - ULTRA-AGGRESSIVE
    ;; The PDF text may use different Unicode characters, so be permissive
    ;; ═══════════════════════════════════════════════════════════════════
    ;; Exact Greek: ΕΦΗΜΕΡΙΔΑ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ with page number
    "ΕΦΗΜΕΡΙΔΑ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ \\d+"
    "ΕΦΗΜΕΡΙΔΑ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ"
    ;; With any character after ΕΦΗΜΕΡΙ
    "ΕΦΗΜΕΡΙ[ΔΔDΑ∆].* \\d{3,5}"
    "ΕΦΗΜΕΡΙ.{0,30}ΚΥΒΕΡΝΗΣ.{0,20}"
    ;; Mixed Greek/Latin
    "[EΕ]ΦΗΜΕΡΙ.{0,3}Α.{0,40}\\d{3,5}"
    ;; Τεύχος issue reference
    "Τεύχος\\s+[ΑΒΓ∆ABCD]['΄']?\\s*\\d+"
    ;; ═══════════════════════════════════════════════════════════════════
    ;; SECTION HEADERS - ULTRA-AGGRESSIVE
    ;; ═══════════════════════════════════════════════════════════════════
    ;; ΜΕΡΟΣ followed by text (Greek ordinals)
    "ΜΕΡΟΣ ΠΡΩΤΟ[^.]*"
    "ΜΕΡΟΣ ΔΕΥΤΕΡΟ[^.]*"
    "ΜΕΡΟΣ ΤΡΙΤΟ[^.]*"
    "ΜΕΡΟΣ ΤΕΤΑΡΤΟ[^.]*"
    "ΜΕΡΟΣ [Α-Ω][α-ωά-ώΑ-Ω\\s]+"
    ;; ΚΕΦΑΛΑΙΟ
    "ΚΕΦΑΛΑΙΟ [Α-Ω][α-ωά-ώΑ-Ω\\s]+"
    ;; ΤΜΗΜΑ with Greek letter (use .? for any apostrophe variant)
    "ΤΜΗΜΑ [ΑΒΓ∆Α-Ω].?[^.]*"
    "ΤΜΗΜΑ [Α-Ω].?\\s*[Α-Ωα-ωά-ώ\\s]+"
    ;; Mixed Latin/Greek variants
    "[MΜ]ΕΡΟΣ [Α-Ω][α-ωά-ώΑ-Ω\\s]+"
    "[TΤ]ΜΗΜΑ [Α-Ω].?"
    "[KΚ]ΕΦΑΛΑΙΟ [Α-Ω][α-ωά-ώΑ-Ω\\s]+")
  "Patterns for noise to remove from paragraph content at AST construction time.")

(defun clean-paragraph-content (text)
  "Clean paragraph content by removing FEK noise patterns.

   NSA-GRADE: Final safety net to ensure clean article content.

   Args:
     text: Paragraph text content

   Returns:
     Cleaned text"
  (when (or (null text) (string= text ""))
    (return-from clean-paragraph-content text))

  (let ((result text))
    ;; Apply each noise pattern
    (dolist (pattern +paragraph-noise-patterns+)
      (setf result (cl-ppcre:regex-replace-all pattern result "")))

    ;; Clean up multiple spaces left by removal
    (setf result (cl-ppcre:regex-replace-all "\\s{2,}" result " "))

    ;; Trim leading/trailing whitespace
    (setf result (string-trim '(#\Space #\Tab #\Newline #\Return) result))

    result))

(defun filter-page-elements (canonical-blocks)
  "Filter out page elements (headers, footers, page numbers) from blocks.

   NSA-GRADE: Removes FEK page elements that should not appear in legal text.

   Args:
     canonical-blocks: List of canonical-block from Layer 3

   Returns:
     Filtered list without headers/footers/page-numbers"
  (remove-if (lambda (block)
               (member (canonical-block-type block) +filtered-block-types+))
             canonical-blocks))

(defun build-ast-from-blocks (canonical-blocks)
  "Build AST from list of canonical-block objects.

   This is the main Layer 4 entry point.

   NSA-GRADE: Filters out headers/footers before building AST.

   Args:
     canonical-blocks: List of canonical-block from Layer 3

   Returns:
     document-node representing the complete AST"

  ;; FILTER: Remove headers, footers, and page numbers
  (let* ((filtered-blocks (filter-page-elements canonical-blocks))
         (preamble-blocks '())
         (article-groups '())
         (closing-blocks '())
         (current-article nil)
         (current-article-subtitle nil)  ; NEW: Track article subtitle
         (current-paragraphs '())
         (current-points '())
         (in-article nil))

    ;; Log filtering statistics
    (let ((removed-count (- (length canonical-blocks) (length filtered-blocks))))
      (when (> removed-count 0)
        (format t "~&[AST-BUILDER] Filtered ~D page elements (headers/footers)~%" removed-count)))

    ;; Group blocks by structure
    (dolist (block filtered-blocks)
      (let ((block-type (canonical-block-type block))
            (text (canonical-text block)))

        (case block-type
          (:title
           (push block preamble-blocks))

          (:article-header
           ;; Seal accumulated points into last paragraph, then save article
           (when current-article
             (cond
               (current-paragraphs
                ;; Normal case: attach points to last opened paragraph
                (setf (cdr (first current-paragraphs)) (nreverse current-points)))
               (current-points
                ;; Orphan points: article has points but no paragraph blocks yet.
                ;; Create a synthetic (nil . points) entry so they are preserved.
                (push (cons nil (nreverse current-points)) current-paragraphs)))
             (push (list current-article
                         current-article-subtitle
                         (nreverse current-paragraphs))
                   article-groups))
           ;; Start new article
           (setf current-article block
                 current-article-subtitle nil
                 current-paragraphs '()
                 current-points '()
                 in-article t))

          (:article-subtitle
           ;; Capture the article subtitle (title) if we're in an article
           ;; and don't have a subtitle yet
           (when (and in-article (null current-article-subtitle))
             (setf current-article-subtitle block)))

          (:paragraph-num
           (when in-article
             ;; Seal: normal case attaches points to previous para-cons;
             ;; orphan case (no prior para) creates a synthetic (nil . points).
             (cond
               (current-paragraphs
                (setf (cdr (first current-paragraphs)) (nreverse current-points)))
               (current-points
                (push (cons nil (nreverse current-points)) current-paragraphs)))
             (setf current-points '())
             (push (cons block nil) current-paragraphs)))

          (:point
           (when in-article
             (push block current-points)))

          (:paragraph
           (cond
             (in-article
              (cond
                (current-paragraphs
                 (setf (cdr (first current-paragraphs)) (nreverse current-points)))
                (current-points
                 (push (cons nil (nreverse current-points)) current-paragraphs)))
              (setf current-points '())
              (push (cons block nil) current-paragraphs))
             (t
              ;; Before any article - preamble
              (push block preamble-blocks))))

          (:signature
           (push block closing-blocks))

          (otherwise
           (cond
             (in-article
              (cond
                (current-paragraphs
                 (setf (cdr (first current-paragraphs)) (nreverse current-points)))
                (current-points
                 (push (cons nil (nreverse current-points)) current-paragraphs)))
              (setf current-points '())
              (push (cons block nil) current-paragraphs))
             (t (push block preamble-blocks)))))))

    ;; Save last article, sealing final points into last paragraph
    (when current-article
      (cond
        (current-paragraphs
         (setf (cdr (first current-paragraphs)) (nreverse current-points)))
        (current-points
         ;; Orphan points with no paragraph block: preserve as synthetic entry
         (push (cons nil (nreverse current-points)) current-paragraphs)))
      (push (list current-article
                  current-article-subtitle
                  (nreverse current-paragraphs))
            article-groups))

    ;; Build AST
    (let* ((preamble (when preamble-blocks
                       (make-preamble-node
                        :text (format nil "~{~A~%~}"
                                      (mapcar #'canonical-text
                                              (nreverse preamble-blocks)))
                        :source-blocks (nreverse preamble-blocks))))

           (articles
             (loop for (art-block subtitle-block para-point-pairs) in (nreverse article-groups)
                   collect
                   (let* ((art-text (canonical-text art-block))
                          (art-num (extract-article-number art-text))
                          ;; Extract subtitle text if present
                          (art-subtitle (when subtitle-block
                                          (clean-paragraph-content (canonical-text subtitle-block))))
                          (paragraphs
                            (loop for (para-block . para-points) in para-point-pairs
                                  for raw-text = (if para-block
                                                     (canonical-text para-block)
                                                     "")
                                  ;; Apply final content cleanup
                                  for text = (clean-paragraph-content raw-text)
                                  for num = (extract-paragraph-number text)
                                  for point-nodes = (loop for pt-block in para-points
                                                          for pt-text = (canonical-text pt-block)
                                                          for marker = (extract-point-marker pt-text)
                                                          collect (make-point-node
                                                                   :marker marker
                                                                   :content pt-text
                                                                   :source-blocks (list pt-block)))
                                  ;; Emit if paragraph has text content OR points
                                  when (or point-nodes (and text (> (length text) 0)))
                                  collect (make-paragraph-node
                                           :number num
                                           :content (or text "")
                                           :text (or text "")
                                           :source-blocks (when para-block (list para-block))
                                           :points point-nodes))))
                     (make-article-node
                      :number art-num
                      :title art-subtitle
                      :paragraphs paragraphs
                      :text art-text
                      :source-blocks (list art-block)))))

           (closing (when closing-blocks
                      (make-closing-node
                       :signatures (loop for sig-block in (nreverse closing-blocks)
                                         collect (make-signature-node
                                                  :text (canonical-text sig-block)
                                                  :source-blocks (list sig-block)))
                       :source-blocks closing-blocks))))

      (make-document-node
       :title (when preamble-blocks
                (canonical-text (first (last preamble-blocks))))
       :preamble preamble
       :articles articles
       :closing closing
       :source-blocks canonical-blocks))))

(defun build-ast (canonicalized-document)
  "Build AST from canonicalized document.

   Args:
     canonicalized-document: Output from canonicalize-document
                             (list of (page-num . blocks) pairs)

   Returns:
     document-node"
  (let ((all-blocks '()))
    (dolist (page-pair canonicalized-document)
      (setf all-blocks (append all-blocks (cdr page-pair))))
    (build-ast-from-blocks all-blocks)))

;;; ============================================================================
;;; RESET
;;; ============================================================================

(defun reset-ast-counter ()
  "Reset AST node counter."
  (setf *ast-node-counter* 0))

;;; ============================================================================
;;; MACRO: DEFASTNODE
;;; ============================================================================

(defmacro defastnode (name superclass slots &body options)
  "Define a new AST node type.

   Automatically inherits from ast-node and adds standard behavior.

   Usage:
     (defastnode amendment-node (article-node)
       ((amendment-type :initarg :amendment-type :accessor amendment-type))
       (:documentation \"An amendment to an article\"))"
  (let ((constructor-name (intern (format nil "MAKE-~A" name))))
    `(progn
       (defclass ,name (,superclass)
         ,slots
         ,@options)

       (defun ,constructor-name (&rest initargs)
         (let ((node (apply #'make-instance ',name initargs)))
           (unless (slot-boundp node 'id)
             (setf (ast-id node) (generate-ast-id ,(symbol-name name))))
           node)))))

;;; ============================================================================
;;; CONDITIONS & RESTARTS FOR AST CONSTRUCTION
;;; ============================================================================

(define-condition ast-error (error)
  ((message :initarg :message :reader ast-error-message)
   (node-id :initarg :node-id :reader ast-error-node-id :initform nil)
   (context :initarg :context :reader ast-error-context :initform nil))
  (:report (lambda (c s)
             (format s "AST Error~@[ (node: ~A)~]~@[ [~A]~]: ~A"
                     (ast-error-node-id c)
                     (ast-error-context c)
                     (ast-error-message c)))))

(define-condition ast-structure-error (ast-error)
  ((expected :initarg :expected :reader ast-structure-expected)
   (found :initarg :found :reader ast-structure-found))
  (:report (lambda (c s)
             (format s "AST Structure Error: Expected ~A, found ~A"
                     (ast-structure-expected c)
                     (ast-structure-found c)))))

(define-condition ast-missing-content-error (ast-error)
  ((required-field :initarg :required-field :reader ast-missing-field))
  (:report (lambda (c s)
             (format s "AST Missing Content: Required field ~A is empty"
                     (ast-missing-field c)))))

(defmacro with-ast-restarts ((&key default-node) &body body)
  "Execute BODY with AST construction restarts.

   Restarts:
     USE-EMPTY-NODE: Return minimal empty node
     SKIP-NODE: Skip and continue
     PROVIDE-NODE: Let caller provide replacement"
  `(restart-case
       (progn ,@body)
     (use-empty-node ()
       :report "Use empty node and continue"
       (or ,default-node
           (make-instance 'ast-node :id (generate-ast-id "EMPTY"))))
     (skip-node ()
       :report "Skip this node"
       nil)
     (provide-node (new-node)
       :report "Provide a replacement node"
       ;; [ARCH Phase 1] Το παλιό :interactive έκανε (eval (read)) — αυθαίρετη εκτέλεση από
       ;; το terminal. Τώρα το interactive input διαβάζεται ως DATA-ONLY (safe-read) και
       ;; ανασυγκροτείται μέσω του typed decoder (form-to-ast) — ΚΑΜΙΑ eval. Άκυρο data
       ;; ⇒ empty node (fail-closed, καμία εκτέλεση).
       :interactive (lambda ()
                      (format t "Enter replacement node as data-only form: ")
                      (multiple-value-bind (data status)
                          (orchestrator.safe-read:read-data-string (read-line))
                        (if (eq status :ok)
                            (list (form-to-ast data))
                            (progn (format t "~&Άκυρο data-only form (~A)· empty node.~%" status)
                                   (list (make-instance 'ast-node :id (generate-ast-id "EMPTY")))))))
       new-node)))

;;; ============================================================================
;;; MULTIPLE DISPATCH - METHOD COMBINATIONS
;;; ============================================================================

(defgeneric ast-validate (node)
  (:documentation "Validate an AST node.
   Methods combine with AND - all must pass."))

(defmethod ast-validate ((node ast-node))
  "Base validation: check ID exists"
  (and (ast-id node)
       (stringp (ast-id node))))

(defmethod ast-validate ((node document-node))
  "Document must have at least one article or preamble"
  (and (call-next-method)
       (or (document-preamble node)
           (document-articles node))))

(defmethod ast-validate ((node article-node))
  "Article must have number"
  (and (call-next-method)
       (article-number node)))

(defmethod ast-validate ((node paragraph-node))
  "Paragraph must have content"
  (and (call-next-method)
       (or (paragraph-content node)
           (paragraph-points node))))

;;; ============================================================================
;;; SPECIAL VARIABLES FOR CONSTRUCTION CONTEXT
;;; ============================================================================

(defvar *current-document* nil
  "Document being constructed")

(defvar *current-article* nil
  "Article being constructed")

(defvar *current-paragraph* nil
  "Paragraph being constructed")

(defvar *ast-construction-depth* 0
  "Current depth in AST construction")

(defvar *ast-construction-log* nil
  "Log of construction operations")

(defmacro with-ast-construction ((&key log-p) &body body)
  "Establish AST construction context.

   Usage:
     (with-ast-construction (:log-p t)
       (build-ast-from-blocks blocks))"
  `(let ((*current-document* nil)
         (*current-article* nil)
         (*current-paragraph* nil)
         (*ast-construction-depth* 0)
         (*ast-construction-log* ,(when log-p '())))
     (reset-ast-counter)
     (prog1 (progn ,@body)
       ,(when log-p
          '(nreverse *ast-construction-log*)))))

(defun log-ast-construction (operation &rest args)
  "Log an AST construction operation."
  (when *ast-construction-log*
    (push (list* (get-universal-time) *ast-construction-depth* operation args)
          *ast-construction-log*)))

;;; ============================================================================
;;; HOMOICONICITY - COMPLETE IMPLEMENTATION
;;; ============================================================================

(defun form-to-ast (form)
  "TYPED DECODER: validated DATA-ONLY AST plist → AST node ΧΩΡΙΣ eval. Αυστηρό σχήμα:
   κλειστό+ΥΠΟΧΡΕΩΤΙΚΟ key-set (κανένα forgery-by-omission), μη-διπλά keyword κλειδιά,
   άρτιο plist, βαθύς type check ΚΑΘΕ στοιχείου (source-blocks/lists/nested nodes),
   class allowlist (κανένα input-derived intern). Ανασυγκρότηση μέσω των κανονικών
   constructors — ΚΑΜΙΑ eval. Αντικαθιστά το form-to-ast=(eval form)."
  (labels ((err (fmt &rest a) (error 'ast-decode-error :why (apply #'format nil fmt a)))
           (plist (f tag allowed required)
             (unless (and (consp f) (eq (first f) tag) (evenp (length (rest f))))
               (err "περίμενα άρτιο ~A plist" tag))
             (let* ((pl (rest f)) (keys (loop for (k) on pl by #'cddr collect k)))
               (unless (every #'keywordp keys) (err "~A: μη-keyword κλειδί" tag))
               (unless (= (length keys) (length (remove-duplicates keys))) (err "~A: διπλό κλειδί" tag))
               (let ((unknown (set-difference keys allowed)))
                 (when unknown (err "~A: άγνωστα πεδία ~S" tag unknown)))
               (dolist (r required) (unless (member r keys) (err "~A: λείπει υποχρεωτικό πεδίο ~S" tag r)))
               pl))
           (sstr (v w) (unless (stringp v) (err "~A: όχι string" w)) v)
           (sstr? (v w) (unless (or (null v) (stringp v)) (err "~A: όχι string/nil" w)) v)
           (sint? (v w) (unless (or (null v) (stringp v) (integerp v)) (err "~A: όχι string/integer/nil" w)) v)
           (skw (v w) (unless (keywordp v) (err "~A: όχι keyword" w)) v)
           (sidlist (v w)
             (unless (listp v) (err "~A: όχι λίστα" w))
             (dolist (e v) (unless (or (stringp e) (numberp e) (keywordp e)) (err "~A: μη-data στοιχείο ~S" w e)))
             v)
           (snode? (v) (and v (decode v)))
           (snodelist (v w) (unless (listp v) (err "~A: όχι λίστα" w)) (mapcar #'decode v))
           (decode (f)
             (unless (and (consp f) (member (first f) +ast-schema-tags+))
               (err "άγνωστο/κακοσχηματισμένο AST tag: ~S" (and (consp f) (first f))))
             (ecase (first f)
               (:ast-node/1
                (let* ((p (plist f :ast-node/1 '(:type :id :node-type :text :source-blocks)
                                 '(:type :id :node-type :text :source-blocks)))
                       (tk (skw (getf p :type) :type))
                       (class (cdr (assoc tk +ast-node-class-alist+))))
                  (unless class (err "μη επιτρεπτή κλάση: ~S" tk))
                  (make-instance class
                                 :id (sstr (getf p :id) :id)
                                 :node-type (skw (getf p :node-type) :node-type)
                                 :text (sstr (getf p :text) :text)
                                 :source-blocks (sidlist (getf p :source-blocks) :source-blocks))))
               (:document-node/1
                (let ((p (plist f :document-node/1 '(:title :preamble :articles :closing)
                                '(:title :preamble :articles :closing))))
                  (make-document-node :title (sstr? (getf p :title) :title)
                                      :preamble (snode? (getf p :preamble))
                                      :articles (snodelist (getf p :articles) :articles)
                                      :closing (snode? (getf p :closing)))))
               (:article-node/1
                (let ((p (plist f :article-node/1 '(:number :title :paragraphs :text)
                                '(:number :title :paragraphs :text))))
                  (make-article-node :number (sint? (getf p :number) :number)
                                     :title (sstr? (getf p :title) :title)
                                     :paragraphs (snodelist (getf p :paragraphs) :paragraphs)
                                     :text (sstr (getf p :text) :text))))
               (:paragraph-node/1
                (let ((p (plist f :paragraph-node/1 '(:number :content :points)
                                '(:number :content :points))))
                  (make-paragraph-node :number (sint? (getf p :number) :number)
                                       :content (sstr (getf p :content) :content)
                                       :points (snodelist (getf p :points) :points))))
               (:point-node/1
                (let ((p (plist f :point-node/1 '(:marker :content) '(:marker :content))))
                  (make-point-node :marker (%ast-data-to-marker (getf p :marker))
                                   :content (sstr (getf p :content) :content)))))))
    (decode form)))

(defun ast-to-readable-string (node)
  "Convert AST to human-readable DATA-ONLY string (the versioned plist of ast-to-form).
   [ARCH Phase 1] Το string είναι ΔΕΔΟΜΕΝΑ, ΟΧΙ πρόγραμμα: ανασυγκρότηση με
   (form-to-ast (orchestrator.safe-read:read-data-string s)) — read+typed-decode, ΠΟΤΕ eval."
  (with-output-to-string (s)
    (with-standard-io-syntax
      (let ((*package* (find-package :keyword))
            (*print-pretty* t)
            (*print-right-margin* 100))
        (prin1 (ast-to-form node) s)))))

(defun save-ast-to-file (ast filepath)
  "Save AST ως DATA-ONLY versioned plist, ΑΤΟΜΙΚΑ (write-file-atomic: temp+fsync+rename —
   ποτέ μισο-γραμμένο). [ARCH Phase 1] Το αρχείο ΔΕΝ είναι πρόγραμμα (κανένα in-package/
   make-instance/eval): επαναφορά ΜΟΝΟ μέσω load-ast-from-file (safe-read + typed decoder).
   (Καμία legacy μετανάστευση: το παλιό executable format ήταν dead — 0 persisted artifacts.)"
  (let ((data (ast-to-form ast)))
    (orchestrator.journal:write-file-atomic
     filepath
     (with-output-to-string (s)
       (format s ";;;; AST Export — data-only schema ~A (ΔΕΔΟΜΕΝΑ, όχι κώδικας)~%" (first data))
       (with-standard-io-syntax
         (let ((*package* (find-package :keyword))) (prin1 data s)))
       (terpri s))))
  filepath)

(defun load-ast-from-file (filepath)
  "Load AST ΜΕΣΩ της ΜΙΑΣ safe-read έδρας (read-data-file: pre-scanned depth/atoms + byte-cap +
   *read-eval* nil + #-deny) + typed decoder (form-to-ast) — ΚΑΝΕΝΑ cl:load/eval/read-from-string.
   [ARCH Phase 1] read-data-file (ΟΧΙ read-data-form): τα αρχεία θεωρούνται δυνητικά αλλοιώσιμα,
   άρα ΠΡΕΠΕΙ pre-scan. data ≠ code· restore ≠ load."
  (multiple-value-bind (data status) (orchestrator.safe-read:read-data-file filepath)
    (unless (eq status :ok)
      (error 'ast-decode-error :why (format nil "μη αναγνώσιμο AST αρχείο (safe-read: ~A)" status)))
    (form-to-ast data)))

;;; ============================================================================
;;; MULTIPLE VALUES - RICH RETURNS
;;; ============================================================================

(defun parse-article-with-context (block remaining-blocks)
  "Parse an article with full context tracking.

   Returns: (values article-node remaining-blocks parse-info)"
  (let ((parse-info (list :start-block (canonical-id block)
                          :block-type (canonical-block-type block))))

    (let* ((text (canonical-text block))
           (art-num (extract-article-number text))
           (paragraphs '()))

      ;; Collect paragraphs until next article
      (loop while (and remaining-blocks
                       (not (eq (canonical-block-type (first remaining-blocks))
                                :article-header)))
            do (let ((next-block (pop remaining-blocks)))
                 (case (canonical-block-type next-block)
                   ((:paragraph :paragraph-num)
                    (push (make-paragraph-node
                           :number (extract-paragraph-number
                                    (canonical-text next-block))
                           :content (canonical-text next-block)
                           :source-blocks (list next-block))
                          paragraphs)))))

      (setf (getf parse-info :end-block)
            (when paragraphs
              (first (ast-source-blocks (first paragraphs)))))
      (setf (getf parse-info :paragraph-count) (length paragraphs))

      (values (make-article-node
               :number art-num
               :paragraphs (nreverse paragraphs)
               :text text
               :source-blocks (list block))
              remaining-blocks
              parse-info))))

(defun ast-statistics (ast)
  "Return statistics about AST.

   Returns: (values total-nodes article-count paragraph-count point-count depth)"
  (let ((total 0)
        (articles 0)
        (paragraphs 0)
        (points 0)
        (max-depth 0))
    (ast-walk ast
              (lambda (node depth)
                (incf total)
                (setf max-depth (max max-depth depth))
                (typecase node
                  (article-node (incf articles))
                  (paragraph-node (incf paragraphs))
                  (point-node (incf points)))))
    (values total articles paragraphs points max-depth)))

;;; ============================================================================
;;; XML EXPORT (via generic function)
;;; ============================================================================

(defgeneric ast-to-xml (node &key indent)
  (:documentation "Convert AST node to XML string."))

(defmethod ast-to-xml ((node ast-node) &key (indent 0))
  (let ((spaces (make-string (* indent 2) :initial-element #\Space)))
    (format nil "~A<~A id=\"~A\">~%~A  <text>~A</text>~%~A</~A>"
            spaces (ast-type node) (ast-id node)
            spaces (ast-text node)
            spaces (ast-type node))))

(defmethod ast-to-xml ((node document-node) &key (indent 0))
  (let ((spaces (make-string (* indent 2) :initial-element #\Space)))
    (with-output-to-string (s)
      (format s "~A<document id=\"~A\">~%" spaces (ast-id node))
      (when (document-title node)
        (format s "~A  <title>~A</title>~%" spaces (document-title node)))
      (when (document-preamble node)
        (format s "~A~%" (ast-to-xml (document-preamble node) :indent (1+ indent))))
      (dolist (article (document-articles node))
        (format s "~A~%" (ast-to-xml article :indent (1+ indent))))
      (when (document-closing node)
        (format s "~A~%" (ast-to-xml (document-closing node) :indent (1+ indent))))
      (format s "~A</document>" spaces))))

(defmethod ast-to-xml ((node article-node) &key (indent 0))
  (let ((spaces (make-string (* indent 2) :initial-element #\Space)))
    (with-output-to-string (s)
      (format s "~A<article id=\"~A\" number=\"~A\">~%"
              spaces (ast-id node) (article-number node))
      (when (article-title node)
        (format s "~A  <title>~A</title>~%" spaces (article-title node)))
      (dolist (para (article-paragraphs node))
        (format s "~A~%" (ast-to-xml para :indent (1+ indent))))
      (format s "~A</article>" spaces))))

(defmethod ast-to-xml ((node paragraph-node) &key (indent 0))
  (let ((spaces (make-string (* indent 2) :initial-element #\Space)))
    (with-output-to-string (s)
      (format s "~A<paragraph id=\"~A\"~@[ number=\"~A\"~]>~%"
              spaces (ast-id node) (paragraph-number node))
      (format s "~A  <content>~A</content>~%" spaces (paragraph-content node))
      (dolist (point (paragraph-points node))
        (format s "~A~%" (ast-to-xml point :indent (1+ indent))))
      (format s "~A</paragraph>" spaces))))

(defmethod ast-to-xml ((node point-node) &key (indent 0))
  (let ((spaces (make-string (* indent 2) :initial-element #\Space)))
    (format nil "~A<point id=\"~A\" marker=\"~A\">~A</point>"
            spaces (ast-id node) (point-marker node) (point-content node))))

;;; ============================================================================
;;; COPY PROTOCOL
;;; ============================================================================

(defgeneric ast-copy (node &key deep)
  (:documentation "Copy an AST node.
   If DEEP, recursively copy children."))

(defmethod ast-copy ((node ast-node) &key (deep t))
  (let ((copy (make-instance (type-of node))))
    (setf (ast-id copy) (generate-ast-id (symbol-name (ast-type node)))
          (ast-type copy) (ast-type node)
          (ast-text copy) (copy-seq (ast-text node))
          (ast-source-blocks copy) (copy-list (ast-source-blocks node)))
    (when deep
      (setf (ast-children copy)
            (mapcar (lambda (child) (ast-copy child :deep t))
                    (ast-children node))))
    copy))

;;; ============================================================================
;;; DESCRIBE INTEGRATION
;;; ============================================================================

(defmethod describe-object ((node ast-node) stream)
  "Full description of AST node for debugging."
  (format stream "~&=== AST NODE: ~A ===~%" (ast-id node))
  (format stream "Type: ~A~%" (ast-type node))
  (format stream "Text: ~A~%"
          (if (> (length (ast-text node)) 100)
              (concatenate 'string (subseq (ast-text node) 0 100) "...")
              (ast-text node)))
  (format stream "Children: ~D~%" (length (ast-children node)))
  (format stream "Source blocks: ~A~%" (ast-source-blocks node))
  (format stream "~%Reconstructable form:~%")
  (let ((*print-pretty* t))
    (pprint (ast-to-form node) stream))
  (format stream "~%=== END AST NODE ===~%"))

;;; ============================================================================
;;; CROSS-REFERENCE EXTRACTION (NSA-GRADE - Greek Legal Citations)
;;; ============================================================================
;;;
;;; Complete pattern library for extracting Greek legal cross-references.
;;; These patterns handle all common citation formats in Greek legislation.
;;;
;;; ============================================================================

;;; ----------------------------------------------------------------------------
;;; GREEK LAW REFERENCE PATTERNS
;;; ----------------------------------------------------------------------------

(defparameter +greek-law-reference-patterns+
  '(;; ═══════════════════════════════════════════════════════════════════════
    ;; LAW REFERENCES (Ν., ν., Νόμος, νόμος)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; Ν. 1234/2020 or ν. 1234/2020
    (:law "(?i)[Νν]\\.?\\s*(\\d{1,5})/(\\d{4})"
     (:type :law :number 1 :year 2))

    ;; Νόμος 1234/2020 or νόμος 1234/2020
    (:law-full "(?i)(?:Νόμος|νόμος)\\s*(\\d{1,5})/(\\d{4})"
     (:type :law :number 1 :year 2))

    ;; του Ν. 1234/2020
    (:law-genitive "(?i)του\\s+[Νν]\\.?\\s*(\\d{1,5})/(\\d{4})"
     (:type :law :number 1 :year 2))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; PRESIDENTIAL DECREE (Π.Δ., ΠΔ, Προεδρικό Διάταγμα)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; ΠΔ 56/2019 or Π.Δ. 56/2019 or π.δ. 56/2019
    (:presidential-decree "(?i)Π\\.?\\s*Δ\\.?\\s*(\\d{1,4})/(\\d{4})"
     (:type :presidential-decree :number 1 :year 2))

    ;; Προεδρικό Διάταγμα 56/2019
    (:pd-full "(?i)Προεδρικ(?:ό|ού)\\s+Διατ(?:ά|ά)γματ(?:ος|α)?\\s*(\\d{1,4})/(\\d{4})"
     (:type :presidential-decree :number 1 :year 2))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; GOVERNMENT GAZETTE (ΦΕΚ)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; ΦΕΚ Α' 123/2020 or ΦΕΚ Α 123/2020 or ΦΕΚ Α΄ 123
    (:fek-full "(?i)ΦΕΚ\\s*([ΑΒΓΔαβγδA-D])['΄']?\\s*(\\d{1,4})(?:/(\\d{4}))?"
     (:type :fek :series 1 :number 2 :year 3))

    ;; (ΦΕΚ Α' 123) - parenthetical
    (:fek-paren "(?i)\\(ΦΕΚ\\s*([ΑΒΓΔαβγδA-D])['΄']?\\s*(\\d{1,4})(?:/(\\d{4}))?\\)"
     (:type :fek :series 1 :number 2 :year 3))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; ARTICLE REFERENCES (Άρθρο, άρθρο)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; άρθρο 5 του Ν. 1234/2020
    (:article-of-law "(?i)[άα]ρθρ(?:ο|ου)\\s*(\\d+[αβγδ]?)\\s+του\\s+[Νν]\\.?\\s*(\\d{1,5})/(\\d{4})"
     (:type :article :article 1 :law-number 2 :year 3))

    ;; άρθρο 5 παρ. 3 του Ν. 1234/2020
    (:article-para-of-law "(?i)[άα]ρθρ(?:ο|ου)\\s*(\\d+[αβγδ]?)\\s+παρ\\.?\\s*(\\d+)\\s+του\\s+[Νν]\\.?\\s*(\\d{1,5})/(\\d{4})"
     (:type :article-paragraph :article 1 :paragraph 2 :law-number 3 :year 4))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; PARAGRAPH REFERENCES (παρ., παράγραφος)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; παρ. 3 του άρθρου 5 του Ν. 1234/2020
    (:para-of-article "(?i)παρ\\.?\\s*(\\d+)\\s+του\\s+[άα]ρθρ(?:ου|ο)\\s*(\\d+[αβγδ]?)\\s+του\\s+[Νν]\\.?\\s*(\\d{1,5})/(\\d{4})"
     (:type :paragraph :paragraph 1 :article 2 :law-number 3 :year 4))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; EU DIRECTIVES AND REGULATIONS
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; Οδηγία 2016/679/ΕΕ or Οδηγία (ΕΕ) 2016/679
    (:eu-directive "(?i)Οδηγ(?:ία|ίας)\\s*(?:\\(ΕΕ\\))?\\s*(\\d{4})/(\\d{1,4})(?:/ΕΕ)?"
     (:type :eu-directive :year 1 :number 2))

    ;; Κανονισμός (ΕΕ) 2016/679
    (:eu-regulation "(?i)Κανονισμ(?:ός|ού)\\s*\\(ΕΕ\\)\\s*(\\d{4})/(\\d{1,4})"
     (:type :eu-regulation :year 1 :number 2))

    ;; GDPR specific
    (:gdpr "(?i)(?:ΓΚΠΔ|GDPR)"
     (:type :eu-regulation :number "679" :year "2016"))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; MINISTERIAL DECISIONS (ΥΑ, Υπουργική Απόφαση)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; ΥΑ or Υ.Α. followed by number
    (:ministerial-decision "(?i)(?:Υ\\.?\\s*Α\\.?|Υπουργικ(?:ή|ής)\\s+Απόφασ(?:η|ης))\\s*(?:αριθμ?\\.?)?\\s*([\\d/]+)"
     (:type :ministerial-decision :number 1))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; CONSTITUTION REFERENCES
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; άρθρο 5 του Συντάγματος
    (:constitution-article "(?i)[άα]ρθρ(?:ο|ου)\\s*(\\d+)\\s+του\\s+Συντ(?:ά|α)γματ(?:ος)?"
     (:type :constitution :article 1))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; CODE REFERENCES (Κώδικας)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; Αστικός Κώδικας (ΑΚ), Ποινικός Κώδικας (ΠΚ), etc.
    (:civil-code "(?i)(?:Αστικ(?:ός|ού)\\s+Κ(?:ώ|ω)δικ(?:α|ας)?|Α\\.?\\s*Κ\\.?)\\s*(?:[άα]ρθρ(?:ο|ου)?\\s*)?(\\d+)"
     (:type :civil-code :article 1))

    (:penal-code "(?i)(?:Ποινικ(?:ός|ού)\\s+Κ(?:ώ|ω)δικ(?:α|ας)?|Π\\.?\\s*Κ\\.?)\\s*(?:[άα]ρθρ(?:ο|ου)?\\s*)?(\\d+)"
     (:type :penal-code :article 1))

    (:code-civil-procedure "(?i)(?:Κ(?:ώ|ω)δικ(?:α|ας)?\\s+Πολιτικ(?:ής)?\\s+Δικονομ(?:ία|ίας)?|Κ\\.?\\s*Πολ\\.?\\s*Δ\\.?)\\s*(?:[άα]ρθρ(?:ο|ου)?\\s*)?(\\d+)"
     (:type :code-civil-procedure :article 1))

    (:code-criminal-procedure "(?i)(?:Κ(?:ώ|ω)δικ(?:α|ας)?\\s+Ποινικ(?:ής)?\\s+Δικονομ(?:ία|ίας)?|Κ\\.?\\s*Π\\.?\\s*Δ\\.?)\\s*(?:[άα]ρθρ(?:ο|ου)?\\s*)?(\\d+)"
     (:type :code-criminal-procedure :article 1)))

  "Complete pattern library for Greek legal cross-references.
   Each entry: (name regex-pattern extraction-spec)
   Extraction spec maps group numbers to semantic fields.")

;;; ----------------------------------------------------------------------------
;;; GREEK AMENDMENT PATTERNS
;;; ----------------------------------------------------------------------------

(defparameter +greek-amendment-patterns+
  '(;; ═══════════════════════════════════════════════════════════════════════
    ;; MODIFICATION (Τροποποίηση)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; "Τροποποιείται το άρθρο 5 του Ν. 1234/2020"
    (:modification "(?i)Τροποποι(?:είται|ούνται|ήθηκε)\\s+(?:το\\s+)?[άα]ρθρ(?:ο|ου)\\s*(\\d+[αβγδ]?)(?:\\s+(?:παρ\\.?\\s*)?(\\d+))?\\s+του\\s+[Νν]\\.?\\s*(\\d+)/(\\d{4})"
     (:type :modification :article 1 :paragraph 2 :law-number 3 :year 4))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; REPLACEMENT (Αντικατάσταση)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; "Αντικαθίσταται το άρθρο 5..."
    (:replacement "(?i)Αντικα(?:θίσταται|θίστανται|ταστάθηκε)\\s+(?:το\\s+)?[άα]ρθρ(?:ο|ου)\\s*(\\d+[αβγδ]?)(?:\\s+(?:παρ\\.?\\s*)?(\\d+))?(?:\\s+του\\s+[Νν]\\.?\\s*(\\d+)/(\\d{4}))?"
     (:type :replacement :article 1 :paragraph 2 :law-number 3 :year 4))

    ;; "Η παράγραφος 3 του άρθρου 5 αντικαθίσταται ως εξής:"
    (:replacement-para "(?i)Η\\s+παρ(?:άγραφος|\\.)?\\s*(\\d+)\\s+του\\s+[άα]ρθρ(?:ου|ο)\\s*(\\d+[αβγδ]?)(?:\\s+του\\s+[Νν]\\.?\\s*(\\d+)/(\\d{4}))?\\s+αντικαθίσταται"
     (:type :replacement :paragraph 1 :article 2 :law-number 3 :year 4))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; ABOLITION/REPEAL (Κατάργηση)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; "Καταργείται το άρθρο 5..."
    (:abolition "(?i)Καταργ(?:είται|ούνται|ήθηκε)\\s+(?:το\\s+)?[άα]ρθρ(?:ο|ου)\\s*(\\d+[αβγδ]?)(?:\\s+(?:παρ\\.?\\s*)?(\\d+))?(?:\\s+του\\s+[Νν]\\.?\\s*(\\d+)/(\\d{4}))?"
     (:type :abolition :article 1 :paragraph 2 :law-number 3 :year 4))

    ;; "Καταργούνται οι διατάξεις του Ν. 1234/2020"
    (:abolition-provisions "(?i)Καταργ(?:είται|ούνται)\\s+(?:οι\\s+)?διατ(?:ά|α)ξ(?:εις|η)\\s+του\\s+[Νν]\\.?\\s*(\\d+)/(\\d{4})"
     (:type :abolition :law-number 1 :year 2))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; ADDITION (Προσθήκη)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; "Προστίθεται άρθρο 5Α στο Ν. 1234/2020"
    (:addition "(?i)Προστ(?:ί|ι)θ(?:εται|ενται|ηκε)\\s+[άα]ρθρ(?:ο|ου)\\s*(\\d+[αβγδΑΒΓΔ]?)\\s+(?:στο|στον)\\s+[Νν]\\.?\\s*(\\d+)/(\\d{4})"
     (:type :addition :article 1 :law-number 2 :year 3))

    ;; "Μετά το άρθρο 5 προστίθεται άρθρο 5Α"
    (:addition-after "(?i)Μετ(?:ά|α)\\s+(?:το|την)\\s+[άα]ρθρ(?:ο|ου)\\s*(\\d+[αβγδ]?)\\s+προστ(?:ί|ι)θεται\\s+[άα]ρθρ(?:ο|ου)\\s*(\\d+[αβγδΑΒΓΔ]?)"
     (:type :addition :after-article 1 :new-article 2))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; SUSPENSION (Αναστολή)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; "Αναστέλλεται η ισχύς του άρθρου 5..."
    (:suspension "(?i)Αναστ(?:έ|ε)λλ(?:εται|ονται)\\s+(?:η\\s+ισχ(?:ύ|υ)ς\\s+)?(?:του\\s+)?[άα]ρθρ(?:ου|ο)\\s*(\\d+[αβγδ]?)(?:\\s+του\\s+[Νν]\\.?\\s*(\\d+)/(\\d{4}))?"
     (:type :suspension :article 1 :law-number 2 :year 3))

    ;; ═══════════════════════════════════════════════════════════════════════
    ;; EXTENSION (Παράταση)
    ;; ═══════════════════════════════════════════════════════════════════════

    ;; "Παρατείνεται η ισχύς του άρθρου 5..."
    (:extension "(?i)Παρατ(?:ε|εί)ν(?:εται|ονται)\\s+(?:η\\s+ισχ(?:ύ|υ)ς\\s+)?(?:του\\s+)?[άα]ρθρ(?:ου|ο)\\s*(\\d+[αβγδ]?)(?:\\s+του\\s+[Νν]\\.?\\s*(\\d+)/(\\d{4}))?"
     (:type :extension :article 1 :law-number 2 :year 3)))

  "Pattern library for Greek legal amendments.
   Each entry: (name regex-pattern extraction-spec)")

;;; ----------------------------------------------------------------------------
;;; HELPER MACRO: WHEN-LET (must be defined before extraction functions)
;;; ----------------------------------------------------------------------------

(defmacro when-let (bindings &body body)
  "Bind variables according to BINDINGS and execute BODY only if all values are non-nil.
   BINDINGS is a list of (var form) pairs.

   Usage: (when-let ((var form)) body...)

   This matches the Alexandria when-let convention."
  (let ((binding (first bindings)))
    (destructuring-bind (var form) binding
      `(let ((,var ,form))
         (when ,var
           ,@body)))))

;;; ----------------------------------------------------------------------------
;;; EXTRACTION FUNCTIONS
;;; ----------------------------------------------------------------------------

(declaim (inline safe-group-extract))
(defun safe-group-extract (groups group-idx)
  "Safely extract a capture group by 1-based index. Returns NIL if invalid.

   Args:
     groups: Simple-vector from cl-ppcre:scan-to-strings
     group-idx: 1-based index (as used in extraction specs)

   Returns:
     The captured string or NIL"
  (declare (type (or null simple-vector) groups))
  (when (and groups
             (typep group-idx 'fixnum)
             (> (the fixnum group-idx) 0))
    (let ((idx (the fixnum (1- (the fixnum group-idx)))))
      (when (< idx (length groups))
        (aref groups idx)))))

(defun parse-law-reference (text)
  "Parse a law reference string into structured data.

   Args:
     text: String containing a law reference (e.g., 'Ν. 1234/2020')

   Returns:
     Plist with :type :number :year :fek or NIL if no match"
  (declare (type string text))
  (dolist (pattern-entry +greek-law-reference-patterns+)
    (destructuring-bind (name regex extraction-spec) pattern-entry
      (declare (ignore name))
      (multiple-value-bind (match groups)
          (cl-ppcre:scan-to-strings regex text)
        (when match
          (let ((result (list :type (getf extraction-spec :type)
                              :original-text match)))
            ;; Extract each specified group
            (loop for (key group-idx) on extraction-spec by #'cddr
                  for val = (when (typep group-idx 'fixnum)
                              (safe-group-extract groups group-idx))
                  when val
                  do (setf (getf result key) val))
            (return-from parse-law-reference result))))))
  nil)

(defun parse-fek-reference (text)
  "Parse a ΦΕΚ (Government Gazette) reference.

   Args:
     text: String containing ΦΕΚ reference (e.g., 'ΦΕΚ Α' 123/2020')

   Returns:
     Plist with :type :fek :series :number :year or NIL"
  (declare (type string text))
  (let ((fek-patterns (remove-if-not
                       (lambda (p) (member (first p) '(:fek-full :fek-paren)))
                       +greek-law-reference-patterns+)))
    (dolist (pattern-entry fek-patterns)
      (destructuring-bind (name regex extraction-spec) pattern-entry
        (declare (ignore name))
        (multiple-value-bind (match groups)
            (cl-ppcre:scan-to-strings regex text)
          (when match
            (let ((result (list :type :fek :original-text match)))
              (loop for (key group-idx) on extraction-spec by #'cddr
                    for val = (when (typep group-idx 'fixnum)
                                (safe-group-extract groups group-idx))
                    when val
                    do (setf (getf result key) val))
              (return-from parse-fek-reference result)))))))
  nil)

(defun extract-cross-references (text)
  "Extract all cross-references from a text block.

   Args:
     text: String containing legal text

   Returns:
     List of cross-reference-node objects"
  (declare (type string text))
  (let ((refs '()))
    (dolist (pattern-entry +greek-law-reference-patterns+)
      (destructuring-bind (name regex extraction-spec) pattern-entry
        (declare (ignore name))
        (cl-ppcre:do-matches-as-strings (match regex text)
          (multiple-value-bind (full-match groups)
              (cl-ppcre:scan-to-strings regex match)
            (declare (ignore full-match))
            (when groups
              (let ((xref (make-cross-reference-node
                           :type (getf extraction-spec :type)
                           :target-number (safe-group-extract groups (getf extraction-spec :number))
                           :target-year (safe-group-extract groups (getf extraction-spec :year))
                           :target-article (safe-group-extract groups (getf extraction-spec :article))
                           :target-paragraph (safe-group-extract groups (getf extraction-spec :paragraph))
                           :original-text match
                           :confidence 0.9)))
                (push xref refs)))))))
    (nreverse refs)))

(defun extract-amendments (text)
  "Extract all amendments from a text block.

   Args:
     text: String containing legal text

   Returns:
     List of amendment-node objects"
  (declare (type string text))
  (let ((amendments '()))
    (dolist (pattern-entry +greek-amendment-patterns+)
      (destructuring-bind (name regex extraction-spec) pattern-entry
        (declare (ignore name))
        (cl-ppcre:do-matches-as-strings (match regex text)
          (multiple-value-bind (full-match groups)
              (cl-ppcre:scan-to-strings regex match)
            (declare (ignore full-match))
            (when groups
              (let* ((law-num (safe-group-extract groups (getf extraction-spec :law-number)))
                     (year (safe-group-extract groups (getf extraction-spec :year)))
                     (target-law-str (when (and law-num year)
                                       (format nil "Ν. ~A/~A" law-num year)))
                     (amend (make-amendment-node
                             :type (getf extraction-spec :type)
                             :target-law target-law-str
                             :target-article (safe-group-extract groups (getf extraction-spec :article))
                             :target-paragraph (safe-group-extract groups (getf extraction-spec :paragraph))
                             :text match)))
                (push amend amendments)))))))
    (nreverse amendments)))

;;; ----------------------------------------------------------------------------
;;; HIERARCHICAL PATTERN EXTRACTORS
;;; ----------------------------------------------------------------------------

(defun extract-part-info (text)
  "Extract ΜΕΡΟΣ (Part) information from text.

   Returns: (values number title) or NIL"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings
       "(?i)ΜΕΡΟΣ\\s+([ΠΡΩΤΟΔΕΥΤΕΡΤΡΙΑΚΠΕΜΣΕΒΔΟΟΓΔΟΕΝΑΤΕΚΑ]+|[Α-Ω]|\\d+)(?:\\s*[-:]?\\s*(.+))?"
       text)
    (when match
      (values (aref groups 0)
              (when (and (> (length groups) 1) (aref groups 1))
                (string-trim '(#\Space #\Tab #\Newline) (aref groups 1)))))))

(defun extract-division-info (text)
  "Extract ΤΜΗΜΑ (Division) information from text.

   Returns: (values number title) or NIL"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings
       "(?i)ΤΜΗΜΑ\\s+([ΠΡΩΤΟΔΕΥΤΕΡΤΡΙΑΚΠΕΜΣΕΒΔΟΟΓΔΟΕΝΑΤΕΚΑ]+|[Α-Ω]|\\d+)(?:\\s*[-:]?\\s*(.+))?"
       text)
    (when match
      (values (aref groups 0)
              (when (and (> (length groups) 1) (aref groups 1))
                (string-trim '(#\Space #\Tab #\Newline) (aref groups 1)))))))

(defun extract-chapter-info (text)
  "Extract ΚΕΦΑΛΑΙΟ (Chapter) information from text.

   Returns: (values number title) or NIL"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings
       "(?i)ΚΕΦΑΛΑΙΟ\\s+([Α-Ω]|\\d+)(?:\\s*[-:]?\\s*(.+))?"
       text)
    (when match
      (values (aref groups 0)
              (when (and (> (length groups) 1) (aref groups 1))
                (string-trim '(#\Space #\Tab #\Newline) (aref groups 1)))))))

(defun extract-sub-point-marker (text)
  "Extract sub-point marker (αα, ββ, i, ii, etc.) from text.

   Returns: (values marker level) or NIL"
  (cond
    ;; Level 2: αα, ββ, γγ etc.
    ((cl-ppcre:scan "^\\s*([α-ω])\\1[').]" text)
     (multiple-value-bind (match groups)
         (cl-ppcre:scan-to-strings "^\\s*([α-ω])\\1" text)
       (declare (ignore match))
       (values (concatenate 'string (aref groups 0) (aref groups 0)) 2)))

    ;; Level 3: Roman numerals i, ii, iii, iv...
    ((cl-ppcre:scan "^\\s*(i{1,4}|iv|vi{0,3}|ix|x)[').]" text)
     (multiple-value-bind (match groups)
         (cl-ppcre:scan-to-strings "^\\s*(i{1,4}|iv|vi{0,3}|ix|x)" text)
       (declare (ignore match))
       (values (aref groups 0) 3)))

    ;; Level 3: Numbers 1), 2), 3)...
    ((cl-ppcre:scan "^\\s*(\\d+)[').]" text)
     (multiple-value-bind (match groups)
         (cl-ppcre:scan-to-strings "^\\s*(\\d+)" text)
       (declare (ignore match))
       (values (aref groups 0) 3)))

    (t nil)))

;;; ============================================================================
;;; END OF LEGAL-AST.LISP
;;; ============================================================================
