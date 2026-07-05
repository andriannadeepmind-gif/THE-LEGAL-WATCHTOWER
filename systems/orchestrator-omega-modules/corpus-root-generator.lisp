;;;; systems/orchestrator-omega-modules/corpus-root-generator.lisp
;;;; Corpus Root Generator - DARPA-LEVEL MANIFEST GENERATION
;;;;
;;;; Generates complete corpus-level manifest for Greek Constitution
;;;; Compliant with DCAT, ELI, PROV-O

(in-package :orchestrator.spec)

;;; ============================================================
;;; CORPUS ROOT CLASS
;;; ============================================================

(defclass corpus-root ()
  ((corpus-id :accessor corpus-id
              :initarg :corpus-id
              :type keyword
              :documentation "Corpus identifier (e.g., :syntagma)")

   (corpus-name :accessor corpus-name
                :initarg :corpus-name
                :type string
                :documentation "Human-readable corpus name")

   (corpus-uri :accessor corpus-uri
               :initarg :corpus-uri
               :type string
               :documentation "Base URI for corpus")

   (issued-date :accessor issued-date
                :initarg :issued-date
                :type string
                :documentation "ISO-8601 date of original issuance")

   (modified-date :accessor modified-date
                  :initarg :modified-date
                  :type string
                  :documentation "ISO-8601 date of last modification")

   (article-uris :accessor article-uris
                 :initarg :article-uris
                 :initform nil
                 :type list
                 :documentation "List of article URIs in corpus")

   (publisher :accessor publisher
              :initarg :publisher
              :type string
              :documentation "Publisher URI")

   (contributor :accessor contributor
                :initarg :contributor
                :type string
                :documentation "Contributor URI"))
  (:documentation "Root node for entire legal corpus (e.g., Greek Constitution)"))

;;; ============================================================
;;; CONSTRUCTOR
;;; ============================================================

(defun make-corpus-root (&key
                         corpus-id
                         corpus-name
                         corpus-uri
                         issued-date
                         modified-date
                         article-uris
                         (publisher (org-webid))
                         (contributor (person-webid)))
  "Create Corpus Root instance

   Arguments:
     corpus-id:      Keyword identifier (e.g., :syntagma)
     corpus-name:    Display name (e.g., 'Σύνταγμα της Ελλάδας')
     corpus-uri:     Base URI for corpus
     issued-date:    ISO-8601 date string
     modified-date:  ISO-8601 date string
     article-uris:   List of article URIs
     publisher:      Publisher URI (Stavropoulos Law® - data publisher)
     contributor:    Contributor URI (Spyridon Stavropoulos - curator)

   Returns:
     corpus-root instance"

  (make-instance 'corpus-root
                 :corpus-id corpus-id
                 :corpus-name corpus-name
                 :corpus-uri corpus-uri
                 :issued-date issued-date
                 :modified-date modified-date
                 :article-uris article-uris
                 :publisher publisher
                 :contributor contributor))

;;; ============================================================
;;; RDF GENERATION
;;; ============================================================

(defun generate-corpus-manifest-ttl (corpus-root)
  "Generate complete Turtle manifest for corpus

   Arguments:
     corpus-root: corpus-root instance

   Returns:
     String containing Turtle RDF manifest"

  (with-output-to-string (stream)
    ;; Prefixes - USE ΩMEGA CANONICAL ORDERING
    (emit-canonical-prefixes stream)

    ;; Header comment
    (format stream "# ============================================================~%")
    (format stream "# CORPUS ROOT - ~A~%" (corpus-name corpus-root))
    (format stream "# ============================================================~%")
    (terpri stream)

    ;; Main resource
    (format stream "<~A>~%" (corpus-uri corpus-root))
    (format stream "    a eli:LegalResource, dcat:Dataset ;~%")
    (format stream "    dct:title \"~A\"@el ;~%" (corpus-name corpus-root))
    (format stream "    dct:title \"~A\"@en ;~%"
            (or (orchestrator.spec:config-get "corpus.english_name")
                (corpus-name corpus-root)))
    (format stream "~%")
    (format stream "    # PROVENANCE & ATTRIBUTION~%")
    (format stream "    dct:issued ~S^^xsd:date ;~%" (issued-date corpus-root))
    (format stream "    dct:modified ~S^^xsd:date ;~%" (modified-date corpus-root))
    (format stream "    dct:publisher <~A> ;~%" (publisher corpus-root))
    (format stream "    dct:contributor <~A> ;~%" (contributor corpus-root))
    (format stream "    prov:wasAttributedTo <~A> ;~%"
            (orchestrator.spec:config-get "provenance.authority_uri"
                                          "http://data.stavropouloslaw.com/agent/greek-parliament"))
    (format stream "~%")
    (format stream "    # JURISDICTION~%")
    (format stream "    eli:jurisdiction <http://publications.europa.eu/resource/authority/country/GRC> ;~%")
    (terpri stream)

    ;; Articles (CRITICAL FIX: Remove duplicates before emitting)
    (format stream "    # Articles~%")
    (let ((unique-articles (remove-duplicates (article-uris corpus-root) :test #'string=)))
      (loop for article-uri in unique-articles
            for last-p = nil then (null (cdr remaining))
            for remaining on unique-articles
            do (format stream "    eli:has_part <~A>~A~%"
                       article-uri
                       (if last-p " ;" " ;"))))
    (terpri stream)

    ;; Dataset distribution
    (let* ((short-name (or (orchestrator.spec:config-get "corpus.short_name") "corpus"))
           (ttl-filename (format nil "~A-full.ttl" short-name)))
      (format stream "    # Dataset distribution~%")
      (format stream "    dcat:distribution [~%")
      (format stream "        a dcat:Distribution ;~%")
      (format stream "        dcat:downloadURL <~A/downloads/~A> ;~%"
              (corpus-uri corpus-root) ttl-filename)
      (format stream "        dct:format <http://publications.europa.eu/resource/authority/file-type/RDF_TURTLE>~%")
      (format stream "    ] .~%"))))

;; NOTE: emit-canonical-prefixes is imported from rdf-canonicalization.lisp
;; No custom prefix emitter needed - use Ωmega canonical ordering

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(corpus-root
          make-corpus-root
          generate-corpus-manifest-ttl
          corpus-id
          corpus-name
          corpus-uri
          issued-date
          modified-date
          article-uris
          publisher
          contributor))
