;;;; systems/orchestrator-model/frbr-classes.lisp
;;;; FRBR CLOS Model - Full Object-Oriented FRBR Implementation
;;;; ΟΜΕΓΑ-LEVEL: DARPA-class architecture with MOP

(in-package :orchestrator.model)

;;; ============================================================
;;; METACLASS - FRBR RESOURCE METACLASS
;;; ============================================================

(defclass frbr-resource-class (standard-class)
  ()
  (:documentation "Metaclass for all FRBR resources - ensures URI canonicalization"))

(defmethod closer-mop:validate-superclass 
    ((class frbr-resource-class) (superclass standard-class))
  "Allow FRBR metaclass to have standard-class as superclass"
  t)

;;; ============================================================
;;; BASE CLASS - ABSTRACT FRBR RESOURCE
;;; ============================================================

(defclass frbr-resource ()
  ((uri :accessor resource-uri
        :initarg :uri
        :type string
        :documentation "Canonical URI for this FRBR resource")
   
   (eli-identifier :accessor eli-identifier
                   :initarg :eli-identifier
                   :type string
                   :documentation "ELI identifier (local part)")

   (provenance :accessor resource-provenance
               :initarg :provenance
               :type list
               :initform nil
               :documentation "PROV-O provenance chain"))
  
  (:metaclass frbr-resource-class)
  (:documentation "Abstract base class for all FRBR resources"))

;;; ============================================================
;;; WORK CLASS - ABSTRACT LEGAL CONCEPT
;;; ============================================================

(defclass frbr-work (frbr-resource)
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
                          \"Α\" for 100Α; \"\" for a plain article. Stored (not just
                          used at construction) so every downstream id derived from
                          the Work preserves the suffix (100 ≠ 100Α everywhere).")

   (article-root-uri :accessor article-root-uri
                     :initarg :article-root-uri
                     :type string
                     :documentation "URI of parent Article Root (for eli:partOf)")

   (jurisdiction :accessor jurisdiction
                 :initarg :jurisdiction
                 :type string
                 :initform "GRC"
                 :documentation "ISO 3166-1 alpha-3 country code")

   (document-type :accessor document-type
                  :initarg :document-type
                  :type string
                  :documentation "ELI document type code (e.g. \"const\", \"l\", \"pd\")")

   (law-year :accessor law-year
             :initarg :law-year
             :type string
             :documentation "Year component of ELI URI (e.g. \"1975\", \"2024\")")

   (issued-date :accessor issued-date
                :initarg :issued-date
                :type string
                :documentation "Original issuance date (xsd:date, e.g. \"1975-06-11\")")

   (part-of :accessor part-of
            :initarg :part-of
            :type string
            :documentation "Parent legal act URI (ELI prefix)")

   (dataset-uri :accessor dataset-uri
                :initarg :dataset-uri
                :type string
                :documentation "VoID dataset URI for void:inDataset membership")

   (realizations :accessor realizations
                 :initarg :realizations
                 :type list
                 :initform nil
                 :documentation "List of Expression URIs that realize this Work")

   (saturation-level :accessor saturation-level
                     :initarg :saturation-level
                     :type float
                     :initform 0.85
                     :documentation "AI optimization saturation metric (0.0-1.0)"))

  (:metaclass frbr-resource-class)
  (:documentation "FRBR Work - Abstract legal resource (language-independent)"))

;;; ============================================================
;;; EXPRESSION CLASS - LINGUISTIC REALIZATION
;;; ============================================================

(defclass frbr-expression (frbr-resource)
  ((work :accessor expression-work
         :initarg :work
         :type frbr-work
         :documentation "The Work this Expression realizes")

   (article-root-uri :accessor article-root-uri
                     :initarg :article-root-uri
                     :type string
                     :documentation "URI of parent Article Root (for eli:partOf)")

   (language :accessor expression-language
             :initarg :language
             :type string
             :initform "el"
             :documentation "ISO 639-1 language code")

   (title :accessor expression-title
          :initarg :title
          :type string
          :documentation "Title in specified language")

   (content :accessor expression-content
            :initarg :content
            :type string
            :documentation "Full text content in specified language")

   (embodiments :accessor embodiments
                :initarg :embodiments
                :type list
                :initform nil
                :documentation "List of Manifestation URIs that embody this Expression")

   (paragraphs :accessor paragraphs
               :initarg :paragraphs
               :type list
               :initform nil
               :documentation "List of paragraph plists (:number N :text TEXT) for atomic subdivisions"))

  (:metaclass frbr-resource-class)
  (:documentation "FRBR Expression - Language-specific realization of Work"))

;;; ============================================================
;;; MANIFESTATION CLASS - DIGITAL EMBODIMENT
;;; ============================================================

(defclass frbr-manifestation (frbr-resource)
  ((expression :accessor manifestation-expression
               :initarg :expression
               :type frbr-expression
               :documentation "The Expression this Manifestation embodies")

   (article-root-uri :accessor article-root-uri
                     :initarg :article-root-uri
                     :type string
                     :documentation "URI of parent Article Root (for eli:partOf)")

   (access-url :accessor access-url
               :initarg :access-url
               :type string
               :documentation "URL for accessing this manifestation")

   (download-url :accessor download-url
                 :initarg :download-url
                 :type string
                 :documentation "Direct download URL")

   (license :accessor license
            :initarg :license
            :type string
            :initform "http://creativecommons.org/publicdomain/mark/1.0/"
            :documentation "License URI")

   (formats :accessor formats
            :initarg :formats
            :type list
            :initform nil
            :documentation "List of Format instances for this Manifestation"))

  (:metaclass frbr-resource-class)
  (:documentation "FRBR Manifestation - Digital embodiment of Expression"))

;;; ============================================================
;;; FORMAT CLASS - ENCODING SPECIFICATION
;;; ============================================================

(defclass frbr-format (frbr-resource)
  ((manifestation :accessor format-manifestation
                  :initarg :manifestation
                  :type frbr-manifestation
                  :documentation "The Manifestation this Format represents")

   (article-root-uri :accessor article-root-uri
                     :initarg :article-root-uri
                     :type string
                     :documentation "URI of parent Article Root (for eli:partOf)")

   (format-type :accessor format-type
                :initarg :format-type
                :type (member :html :turtle :jsonld)
                :documentation "Format type identifier")

   (media-type :accessor media-type
               :initarg :media-type
               :type string
               :documentation "IANA media type (e.g., text/turtle)")

   (dct-format :accessor dct-format
               :initarg :dct-format
               :type string
               :documentation "DCT format URI")

   (file-extension :accessor file-extension
                   :initarg :file-extension
                   :type string
                   :documentation "File extension (.ttl, .jsonld, .html)")

   (byte-size :accessor format-byte-size
              :initarg :byte-size
              :type integer
              :initform 0
              :documentation "File size in bytes"))

  (:metaclass frbr-resource-class)
  (:documentation "FRBR Format - Specific encoding of Manifestation"))

;;; ============================================================
;;; CONSTRUCTOR FUNCTIONS
;;; ============================================================

(defun make-frbr-work (&key article-number
                             (article-suffix "")
                             identity-segment
                             article-root-uri
                             eli-prefix
                             document-type
                             law-year
                             issued-date
                             dataset-uri)
  "Create FRBR Work instance with canonical URI.

   All law-type parameters are required — no Constitution-specific defaults.
   Callers must supply the ELI context explicitly to support any Greek law type.

   Arguments:
     article-number  — integer (δέχεται ΚΑΙ τον εσωτερικό συνθετικό — η βάση
                       ανακτάται από το article-suffix όταν είναι πλήρες label)
     article-suffix  — γυμνό επίθημα («Α») Ή πλήρες label («5Α»)· κενό για απλό
     article-root-uri — pre-computed article root URI (optional; derived from eli-prefix if absent)
     eli-prefix      — ELI law prefix, e.g. https://stavropouloslaw.com/eli/gr/const/1975
                       (use orchestrator.uris:get-eli-const-prefix for Constitution,
                        or build-eli-law-prefix for any other law type)
     document-type   — ELI type code string: \"const\", \"l\", \"pd\", \"md\", etc.
     law-year        — year string: \"1975\", \"2024\", etc.
     issued-date     — xsd:date string: \"1975-06-11\", \"2019-09-27\", etc.
     dataset-uri     — VoID dataset URI for this corpus

   URI Pattern: {eli-prefix}/art/{id}/work — id από τη ΜΙΑ έδρα article-uri-id («5», «5Α»)"

  (check-type article-number integer)
  (unless eli-prefix
    (error "eli-prefix is required for make-frbr-work — pass orchestrator.uris:get-eli-const-prefix for Constitution or build-eli-law-prefix for any other law type"))
  (unless document-type
    (error "document-type is required for make-frbr-work (e.g. \"const\", \"l\", \"pd\")"))
  (unless issued-date
    (error "issued-date is required for make-frbr-work (xsd:date string, e.g. \"1975-06-11\")"))

  ;; P1b [0050]#2: ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ΣΤΟ ΟΡΙΟ ΤΟΥ FRBR ΜΟΝΤΕΛΟΥ (βλ.
  ;; make-frbr-article-root): slots = αληθινή βάση + γυμνό επίθημα, URI/eli-id
  ;; μέσα από τη ΜΙΑ έδρα — συνθετικός αριθμός δεν υπάρχει μέσα στο μοντέλο.
  ;; [0088 Φ6γ-Δ] ΤΟ SEGMENT ΕΙΝΑΙ ΥΠΟΧΡΕΩΤΙΚΟ (βλ. make-frbr-article-root):
  ;; όταν δεν δοθεί, παράγεται στο όριο από τη ΜΙΑ έδρα — καμία raw
  ;; παράλληλη παραγωγή δεν υπάρχει πλέον.
  (let* ((seg (or identity-segment
                  (article-identity-segment article-number article-suffix
                                            :context "make-frbr-work")))
         (base (second seg))
         (suffix (orchestrator.identity:ordinal-suffix (third seg) :sequence :upper))
         (article-root (or article-root-uri
                           (eli-art-uri eli-prefix (segment-uri-id seg))))
         (uri (format nil "~A/work" article-root))
         (year (or law-year (subseq issued-date 0 4)))
         (eli-id (format nil "gr-~A-~A-art-~A-work" document-type year (segment-file-id seg))))
    (make-instance 'frbr-work
                   :uri uri
                   :eli-identifier eli-id
                   :article-number base
                   :article-suffix suffix
                   :article-root-uri article-root
                   :part-of eli-prefix
                   :document-type document-type
                   :law-year year
                   :issued-date issued-date
                   :dataset-uri dataset-uri)))

(defun frbr-article-id (resource)
  "Η ΚΑΝΟΝΙΚΗ ταυτότητα άρθρου («5», «5Α») ενός FRBR resource που φέρει τα
   κανονικοποιημένα slots (article-root, work) — από τη ΜΙΑ έδρα
   article-uri-id. Κάθε renderer που τυπώνει «ποιο άρθρο είναι αυτό»
   (banners, legislationIdentifier, cross-references) περνά ΑΠΟΚΛΕΙΣΤΙΚΑ
   από εδώ: το γυμνό article-number slot είναι αριθμητική ΒΑΣΗ, ΟΧΙ
   μορφοποιήσιμη ταυτότητα (5 και 5Α μοιράζονται βάση 5)."
  (article-uri-id (article-number resource) (article-letter-suffix resource)))

(export 'frbr-article-id)

(defun make-frbr-expression (work &key title content paragraphs)
  "Create FRBR Expression instance for given Work

   NEW URI PATTERN: .../art/N/work/exp/ell"

  (let* ((article-num (article-number work))
         (article-root (article-root-uri work))
         (uri (format nil "~A/exp/ell" (resource-uri work)))
         (eli-id (format nil "~A-exp-ell" (eli-identifier work))))
    (make-instance 'frbr-expression
                   :uri uri
                   :eli-identifier eli-id
                   :work work
                   :article-root-uri article-root
                   :title title
                   :content content
                   :paragraphs paragraphs)))

(defun make-frbr-manifestation (expression)
  "Create FRBR Manifestation instance for given Expression

   NEW URI PATTERN: .../art/N/work/exp/ell/man"

  (let* ((work (expression-work expression))
         (article-num (article-number work))
         (article-root (article-root-uri expression))
         (uri (format nil "~A/man" (resource-uri expression)))
         (eli-id (format nil "~A-man" (eli-identifier expression))))
    (make-instance 'frbr-manifestation
                   :uri uri
                   :eli-identifier eli-id
                   :expression expression
                   :article-root-uri article-root
                   :access-url (orchestrator.uris:get-eli-const-prefix)
                   ;; Inherit the article-root URI (already carries any letter
                   ;; suffix) instead of rebuilding it from the bare number.
                   :download-url article-root)))

(defun make-frbr-format (manifestation format-type)
  "Create FRBR Format instance for given Manifestation and format type

   NEW URI PATTERN: .../art/N/work/exp/ell/man/format/{type}"

  (let* ((expression (manifestation-expression manifestation))
         (work (expression-work expression))
         (article-num (article-number work))
         (article-root (article-root-uri manifestation))
         (format-name (string-downcase (symbol-name format-type)))
         (uri (format nil "~A/format/~A" (resource-uri manifestation) format-name))
         (eli-id (format nil "~A-format-~A" (eli-identifier manifestation) format-name)))
    (make-instance 'frbr-format
                   :uri uri
                   :eli-identifier eli-id
                   :manifestation manifestation
                   :article-root-uri article-root
                   :format-type format-type
                   :media-type (get-media-type format-type)
                   :dct-format (get-dct-format format-type)
                   :file-extension (get-file-extension format-type))))

;;; ============================================================
;;; HELPER FUNCTIONS
;;; ============================================================

(defun get-media-type (format-type)
  "Get IANA media type for format"
  (ecase format-type
    (:html "text/html; charset=utf-8")
    (:turtle "text/turtle; charset=utf-8")
    (:jsonld "application/ld+json; charset=utf-8")))

(defun get-dct-format (format-type)
  "Get DCT format URI for format type"
  (ecase format-type
    (:html "<http://publications.europa.eu/resource/authority/file-type/HTML>")
    (:turtle "<http://publications.europa.eu/resource/authority/file-type/RDF_TURTLE>")
    (:jsonld "<http://publications.europa.eu/resource/authority/file-type/JSON_LD>")))

(defun get-file-extension (format-type)
  "Get file extension for format type"
  (ecase format-type
    (:html ".html")
    (:turtle ".ttl")
    (:jsonld ".jsonld")))
