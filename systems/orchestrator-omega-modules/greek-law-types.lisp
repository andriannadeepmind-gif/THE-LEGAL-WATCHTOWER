;;;; systems/orchestrator-omega-modules/greek-law-types.lisp
;;;; Greek Law Type Registry - ELI-Compliant Schema for All Greek Legal Acts
;;;;
;;;; This file defines the authoritative registry of all Greek legal act types,
;;;; encoding the ELI v1.4 standard as Greece should have implemented it
;;;; following Council Conclusions 2012/C 325/02.
;;;;
;;;; Each law type carries:
;;;;   - ELI type code (URI path segment)
;;;;   - EU Publications Office resource type URI
;;;;   - Schema.org legislation type string
;;;;   - Official Greek designation
;;;;   - ΦΕΚ issue type (where applicable)
;;;;
;;;; URI pattern enforced: https://{domain}/eli/gr/{type-code}/{year}/{number}
;;;;
;;;; References:
;;;;   ELI Ontology: http://data.europa.eu/eli/ontology
;;;;   EU Authority Table: http://publications.europa.eu/resource/authority/resource-type/
;;;;   ELI Council Conclusions: OJ C 325, 26.10.2012

(in-package :orchestrator.model)

;;; ============================================================
;;; AUTHORITATIVE REGISTRY
;;; ============================================================

(defparameter +greek-law-type-registry+
  '((:const
     :eli-code          "const"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/CONST"
     :schema-type       "Constitution"
     :greek-name        "Σύνταγμα"
     :fek-issue         "Α"
     :numbering         :none)

    (:l
     :eli-code          "l"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/LAW_NATIONAL"
     :schema-type       "Statute"
     :greek-name        "Νόμος"
     :fek-issue         "Α"
     :numbering         :sequential-annual)

    (:pd
     :eli-code          "pd"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/DECREE"
     :schema-type       "PresidentialDecree"
     :greek-name        "Προεδρικό Διάταγμα"
     :fek-issue         "Α"
     :numbering         :sequential-annual)

    (:md
     :eli-code          "md"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/DECISION_MIN"
     :schema-type       "MinisterialDecision"
     :greek-name        "Υπουργική Απόφαση"
     :fek-issue         "Β"
     :numbering         :fek-number)

    (:jmd
     :eli-code          "jmd"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/DECISION_JNT"
     :schema-type       "JointMinisterialDecision"
     :greek-name        "Κοινή Υπουργική Απόφαση"
     :fek-issue         "Β"
     :numbering         :fek-number)

    (:cma
     :eli-code          "cma"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/DECISION_GOV"
     :schema-type       "CouncilOfMinistersAct"
     :greek-name        "Πράξη Υπουργικού Συμβουλίου"
     :fek-issue         "Α"
     :numbering         :sequential-annual)

    (:cc
     :eli-code          "cc"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/CODE"
     :schema-type       "Code"
     :greek-name        "Αστικός Κώδικας"
     :fek-issue         nil
     :numbering         :none)

    (:pc
     :eli-code          "pc"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/CODE"
     :schema-type       "Code"
     :greek-name        "Ποινικός Κώδικας"
     :fek-issue         nil
     :numbering         :none)

    (:ccp
     :eli-code          "ccp"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/CODE"
     :schema-type       "Code"
     :greek-name        "Κώδικας Ποινικής Δικονομίας"
     :fek-issue         nil
     :numbering         :none)

    (:cciv
     :eli-code          "cciv"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/CODE"
     :schema-type       "Code"
     :greek-name        "Κώδικας Πολιτικής Δικονομίας"
     :fek-issue         nil
     :numbering         :none)

    (:ld
     :eli-code          "ld"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/DECISION_LEG"
     :schema-type       "LegislativeDecree"
     :greek-name        "Νομοθετικό Διάταγμα"
     :fek-issue         "Α"
     :numbering         :sequential-annual)

    (:rpd
     :eli-code          "rpd"
     :eu-resource-uri   "http://publications.europa.eu/resource/authority/resource-type/REG"
     :schema-type       "RegulatoryDecision"
     :greek-name        "Κανονιστική Πράξη"
     :fek-issue         "Β"
     :numbering         :fek-number))

  "Authoritative registry of all Greek legal act types with ELI v1.4 metadata.
   Each entry is a plist keyed by law type keyword.
   Source: ELI Council Conclusions 2012/C 325/02, EU Publications Office Authority Tables.")

;;; ============================================================
;;; REGISTRY LOOKUP API
;;; ============================================================

(defun find-law-type-entry (type-designator)
  "Find law type registry entry by keyword or ELI code string.

   type-designator: keyword (e.g. :const, :l, :pd) or
                    string ELI code (e.g. \"const\", \"l\", \"pd\")

   Returns: plist entry or NIL if not found."
  (etypecase type-designator
    (keyword
     (cdr (assoc type-designator +greek-law-type-registry+)))
    (string
     (cdr (find type-designator +greek-law-type-registry+
                :key (lambda (entry) (getf (cdr entry) :eli-code))
                :test #'string=)))))

(defun law-type-eu-resource-uri (type-designator)
  "Get EU Publications Office resource type URI for a Greek law type.

   type-designator: keyword or ELI code string
   Returns: URI string for eli:type_document and dct:type

   Example: (law-type-eu-resource-uri :const)
            => \"http://publications.europa.eu/resource/authority/resource-type/CONST\""
  (let ((entry (find-law-type-entry type-designator)))
    (unless entry
      (error "Unknown Greek law type: ~S. Known types: ~{~A~^, ~}"
             type-designator
             (mapcar #'car +greek-law-type-registry+)))
    (getf entry :eu-resource-uri)))

(defun law-type-schema-legislation-type (type-designator)
  "Get Schema.org legislationType string for a Greek law type.

   type-designator: keyword or ELI code string
   Returns: string for schema:legislationType

   Example: (law-type-schema-legislation-type :const) => \"Constitution\""
  (let ((entry (find-law-type-entry type-designator)))
    (unless entry
      (error "Unknown Greek law type: ~S" type-designator))
    (getf entry :schema-type)))

(defun law-type-eli-code (type-designator)
  "Get ELI URI path segment for a Greek law type.

   type-designator: keyword or ELI code string
   Returns: string (e.g. \"const\", \"l\", \"pd\")

   Example: (law-type-eli-code :pd) => \"pd\""
  (let ((entry (find-law-type-entry type-designator)))
    (unless entry
      (error "Unknown Greek law type: ~S" type-designator))
    (getf entry :eli-code)))

(defun law-type-greek-name (type-designator)
  "Get official Greek name for a law type.

   Example: (law-type-greek-name :pd) => \"Προεδρικό Διάταγμα\""
  (let ((entry (find-law-type-entry type-designator)))
    (unless entry
      (error "Unknown Greek law type: ~S" type-designator))
    (getf entry :greek-name)))

(defun law-type-fek-issue (type-designator)
  "Get ΦΕΚ issue type for a law type, or NIL if not published in ΦΕΚ.

   Example: (law-type-fek-issue :l) => \"Α\"
            (law-type-fek-issue :cc) => NIL"
  (let ((entry (find-law-type-entry type-designator)))
    (unless entry
      (error "Unknown Greek law type: ~S" type-designator))
    (getf entry :fek-issue)))

(defun law-type-keyword-from-eli-code (eli-code)
  "Convert ELI code string to law type keyword.

   Example: (law-type-keyword-from-eli-code \"pd\") => :PD"
  (let ((entry (find eli-code +greek-law-type-registry+
                     :key (lambda (e) (getf (cdr e) :eli-code))
                     :test #'string=)))
    (when entry (car entry))))

(defun list-all-law-types ()
  "Return list of all registered Greek law type keywords."
  (mapcar #'car +greek-law-type-registry+))

;;; ============================================================
;;; ELI URI CONSTRUCTION
;;; ============================================================

(defun build-eli-law-prefix (base-uri type-designator year)
  "Build the ELI prefix for any Greek law type.

   base-uri:        domain base (e.g. \"https://stavropouloslaw.com/eli/gr\")
   type-designator: keyword or ELI code string
   year:            string or integer (e.g. \"1975\", 2024)

   Returns: ELI prefix string, e.g.:
     \"https://stavropouloslaw.com/eli/gr/const/1975\"
     \"https://stavropouloslaw.com/eli/gr/l/2024\"

   This is the authoritative URI pattern that Greece should use
   per ELI v1.4 specification."
  (format nil "~A/~A/~A"
          base-uri
          (law-type-eli-code type-designator)
          year))

(defun build-eli-article-uri (eli-prefix article-number &optional suffix-or-label)
  "Build the canonical ELI article URI.

   eli-prefix:      result of build-eli-law-prefix
   article-number:  positive integer
   suffix-or-label: optional letter suffix (\"Α\") or full label (\"100Α\") for a
                    lettered article; preserved so 100Α never collapses onto 100.

   Returns: \"https://.../eli/gr/{type}/{year}/art/{N}{suffix}\"

   Delegates the article id to the single source of truth ARTICLE-URI-ID."
  (format nil "~A/art/~A" eli-prefix (article-uri-id article-number suffix-or-label)))

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(+greek-law-type-registry+
          find-law-type-entry
          law-type-eu-resource-uri
          law-type-schema-legislation-type
          law-type-eli-code
          law-type-greek-name
          law-type-fek-issue
          law-type-keyword-from-eli-code
          list-all-law-types
          build-eli-law-prefix
          build-eli-article-uri))
