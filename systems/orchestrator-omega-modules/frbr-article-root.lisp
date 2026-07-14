;;;; systems/orchestrator-omega-modules/frbr-article-root.lisp
;;;; FRBR Article Root Node - Canonical Container for Article
;;;; ΟΜΕΓΑ-LEVEL: AI-ROOT-AUTHORITY CANONICAL ARTIFACT
;;;;
;;;; The Article Root Node serves as the canonical entry point and container
;;;; for all FRBR layers (Work, Expression, Manifestation, Format).
;;;;
;;;; Architecture Decision:
;;;;   - Article Root is SEPARATE from Work (different URI)
;;;;   - Article Root URI: .../eli/gr/const/2001/art/N
;;;;   - Work URI:         .../eli/gr/const/2001/art/N/work
;;;;
;;;; Reasoning:
;;;;   - Separation of concerns: Article is the dataset/container, Work is FRBR layer
;;;;   - Enables forward relations: eli:hasWork, eli:hasExpression, eli:hasManifestation
;;;;   - Enables inverse relations: all FRBR layers have eli:partOf pointing to Article
;;;;   - Compliant with DCAT (Article as dcat:Dataset)
;;;;   - Compliant with ELI (Article as eli:LegalResource root)
;;;;   - AI-ingest optimized: single canonical entry point per article

(in-package :orchestrator.model)

;;; ============================================================
;;; ARTICLE ROOT CLASS - CANONICAL CONTAINER
;;; ============================================================

(defclass frbr-article-root (frbr-resource)
  ((article-number :accessor article-number
                   :initarg :article-number
                   :type integer
                   :documentation "Η αριθμητική ΒΑΣΗ του άρθρου (κανονικοποιημένη στο όριο:
                    5 και για το 5Α) — ΠΟΤΕ συνθετικός αριθμός, ΠΟΤΕ μόνη
                    της ταυτότητα (βλ. frbr-article-id).")

   (article-letter-suffix :accessor article-letter-suffix
                          :initarg :article-suffix
                          :type string
                          :initform ""
                          :documentation "Letter suffix for lettered articles, e.g.
                          \"Α\" for 100Α; \"\" for a plain article. Kept so the
                          display id, eId and URIs preserve the suffix (100 ≠ 100Α).")

   (article-title :accessor article-title
                  :initarg :article-title
                  :type string
                  :documentation "Article title in primary language")

   (jurisdiction :accessor jurisdiction
                 :initarg :jurisdiction
                 :type string
                 :initform "GRC"
                 :documentation "ISO 3166-1 alpha-3 country code")

   (document-type :accessor document-type
                  :initarg :document-type
                  :type string
                  :documentation "ELI document type code (e.g. \"const\", \"l\", \"pd\")")

   (parent-document :accessor parent-document
                    :initarg :parent-document
                    :type string
                    :documentation "Parent constitution URI")

   (work-uri :accessor work-uri
             :initarg :work-uri
             :type string
             :documentation "URI of the Work layer for this article")

   (expression-uris :accessor expression-uris
                    :initarg :expression-uris
                    :type list
                    :initform nil
                    :documentation "List of Expression URIs (all languages)")

   (manifestation-uris :accessor manifestation-uris
                       :initarg :manifestation-uris
                       :type list
                       :initform nil
                       :documentation "List of Manifestation URIs")

   (format-uris :accessor format-uris
                :initarg :format-uris
                :type list
                :initform nil
                :documentation "List of Format URIs")

   (dataset-version :accessor dataset-version
                    :initarg :dataset-version
                    :type string
                    :initform "1.3.0"
                    :documentation "Dataset version (for DCAT)")

   (issued-date :accessor issued-date
                :initarg :issued-date
                :type string
                :documentation "Original document issuance date (xsd:date)")

   (modified-date :accessor modified-date
                  :initarg :modified-date
                  :type string
                  :documentation "Last modification date"))

  (:metaclass frbr-resource-class)
  (:documentation "FRBR Article Root - Canonical container and entry point for article"))

;;; ============================================================
;;; CONSTRUCTOR FUNCTION
;;; ============================================================

(defun make-frbr-article-root (&key article-number
                                     (article-suffix "")
                                     identity-segment
                                     article-title
                                     eli-prefix
                                     document-type
                                     law-year
                                     issued-date)
  "Create FRBR Article Root instance with canonical URI.

   This is the TOP-LEVEL canonical node for an article.
   All FRBR layers will point back to this via eli:is_part_of.

   URI Pattern: {eli-prefix}/art/{id} — id από τη ΜΙΑ έδρα article-uri-id
   («5», «5Α»)· τα slots κανονικοποιούνται σε (αληθινή βάση, γυμνό επίθημα).

   Arguments:
     article-number  — integer (δέχεται ΚΑΙ τον εσωτερικό συνθετικό — η βάση
                       ανακτάται από το article-suffix όταν είναι πλήρες label)
     article-suffix  — γυμνό επίθημα («Α») Ή πλήρες label («5Α»)· \"\" για απλό
     article-title   — title string in primary language
     eli-prefix      — ELI law prefix (e.g. https://stavropouloslaw.com/eli/gr/const/1975)
     document-type   — ELI type code string: \"const\", \"l\", \"pd\", etc.
     law-year        — year string (e.g. \"1975\", \"2024\")
     issued-date     — xsd:date string (e.g. \"1975-06-11\")

   Returns:
     frbr-article-root instance"

  (check-type article-number integer)
  (check-type article-title string)
  (check-type article-suffix string)
  (unless eli-prefix
    (error "eli-prefix is required for make-frbr-article-root"))
  (unless document-type
    (error "document-type is required for make-frbr-article-root"))
  (unless issued-date
    (error "issued-date is required for make-frbr-article-root"))

  (let* ((year (or law-year (subseq issued-date 0 4)))
         ;; P1b [0050]#2: ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ΣΤΟ ΟΡΙΟ ΤΟΥ FRBR ΜΟΝΤΕΛΟΥ.
         ;; Το ARTICLE-SUFFIX δέχεται γυμνό επίθημα («Α») Ή πλήρες label
         ;; («5Α»)· τα slots κρατούν ΠΑΝΤΑ την αληθινή βάση + γυμνό επίθημα,
         ;; ώστε συνθετικός αριθμός αποσαφήνισης (5Α ⇒ 5001) να μην μπορεί
         ;; ΔΟΜΙΚΑ να υπάρξει μέσα στο FRBR μοντέλο — κάθε renderer των slots
         ;; βλέπει μόνο την αληθινή ταυτότητα. URI/eli-id: μέσα από τη ΜΙΑ
         ;; έδρα (article-uri-id / pad-article-id), όχι τοπική συγκόλληση.
         ;; [0088 Φ6γ-Α2] Με typed IDENTITY-SEGMENT (από IIR/έδρα): base/suffix/
         ;; προβολές ΑΠΟ ΤΟ SEGMENT — ίδια format strings, byte-identical·
         ;; χωρίς segment: legacy όριο-κανονικοποίηση (πεθαίνει στους Δ-θανάτους).
         (base (if identity-segment (second identity-segment)
                   (article-base-number article-number article-suffix)))
         (suffix (if identity-segment
                     (orchestrator.identity:ordinal-suffix
                      (third identity-segment) :sequence :upper)
                     (article-label-suffix article-suffix)))
         (uid (if identity-segment
                  (format nil "~D~A" base suffix)
                  (article-uri-id article-number article-suffix)))
         (uri (format nil "~A/art/~A" eli-prefix uid))
         (eli-id (format nil "gr-~A-~A-art-~A" document-type year
                         (if identity-segment
                             (format nil "~3,'0D~A" base suffix)
                             (pad-article-id article-number article-suffix))))
         (work-uri (format nil "~A/work" uri)))

    (make-instance 'frbr-article-root
                   :uri uri
                   :eli-identifier eli-id
                   :article-number base
                   :article-suffix suffix
                   :article-title article-title
                   :document-type document-type
                   :issued-date issued-date
                   :work-uri work-uri
                   :parent-document eli-prefix)))

;;; ============================================================
;;; UTILITY FUNCTIONS
;;; ============================================================

(defun article-root-primary-expression-uri (article-root)
  "Get primary (Greek) Expression URI for Article Root"
  (format nil "~A/work/exp/ell" (resource-uri article-root)))

(defun article-root-primary-manifestation-uri (article-root)
  "Get primary Manifestation URI for Article Root"
  (format nil "~A/work/exp/ell/man" (resource-uri article-root)))

(defun article-root-format-uri (article-root format-type)
  "Get Format URI for specific format type

   format-type: :html, :turtle, or :jsonld"
  (let ((format-name (string-downcase (symbol-name format-type))))
    (format nil "~A/work/exp/ell/man/format/~A"
            (resource-uri article-root)
            format-name)))

;;; Note: Validation removed to avoid conflict with orchestrator.model:validate-instance function

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(frbr-article-root
          make-frbr-article-root
          article-title
          parent-document
          work-uri
          expression-uris
          manifestation-uris
          format-uris
          dataset-version
          modified-date
          article-root-primary-expression-uri
          article-root-primary-manifestation-uri
          article-root-format-uri))
