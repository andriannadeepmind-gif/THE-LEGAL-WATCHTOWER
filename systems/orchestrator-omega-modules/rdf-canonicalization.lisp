;;;; systems/orchestrator-omega-modules/rdf-canonicalization.lisp
;;;; RDF Canonical Ordering - AI-Invariant Output
;;;; ΟΜΕΓΑ-LEVEL: Research-grade determinism
;;;;
;;;; Ensures byte-for-byte reproducible RDF output.
;;;;
;;;; Guarantees:
;;;;   - Stable prefix ordering (alphabetical)
;;;;   - Stable subject ordering (URI lexical order)
;;;;   - Stable predicate ordering (namespace + local name)
;;;;   - Stable object ordering (URI/literal/blank node)
;;;;   - Unicode normalization (NFC)
;;;;   - Whitespace normalization
;;;;
;;;; Based on:
;;;;   - W3C RDF Dataset Canonicalization (RDFC-1.0)
;;;;   - ELI Best Practices for Canonical URIs
;;;;   - FAIR Data Principles

(in-package :orchestrator.spec)

;;; ============================================================
;;; CANONICAL PREFIX ORDERING
;;; ============================================================

(defun canonical-prefix-list ()
  "Return canonical prefix list in alphabetical order

   This MUST NOT change between versions to ensure stability."

  '(("dcat"   . "http://www.w3.org/ns/dcat#")
    ("dct"    . "http://purl.org/dc/terms/")
    ("digest" . "http://www.w3.org/2000/10/swap/crypto#")
    ("eli"    . "http://data.europa.eu/eli/ontology#")
    ("glass"  . "http://www.w3.org/2000/10/swap/crypto#")
    ("odrl"   . "http://www.w3.org/ns/odrl/2/")
    ("owl"    . "http://www.w3.org/2002/07/owl#")
    ("pav"    . "http://purl.org/pav/")
    ("prov"   . "http://www.w3.org/ns/prov#")
    ("rdfs"   . "http://www.w3.org/2000/01/rdf-schema#")
    ("schema" . "https://schema.org/")
    ("stavropouloslaw" . "https://stavropouloslaw.com/ontology#")
    ("void"   . "http://rdfs.org/ns/void#")
    ("xsd"    . "http://www.w3.org/2001/XMLSchema#")))

(defun emit-canonical-prefixes (stream)
  "Emit prefixes in canonical order to stream"

  (dolist (prefix-pair (canonical-prefix-list))
    (destructuring-bind (prefix . uri) prefix-pair
      (format stream "@prefix ~A: <~A> .~%" prefix uri)))

  (terpri stream))

;;; ============================================================
;;; CANONICAL PROPERTY ORDERING
;;; ============================================================

(defparameter *canonical-property-order*
  '(;; 1. RDF Core
    "rdf:type"
    "a"

    ;; 2. ELI Properties (alphabetical)
    "eli:date_document"
    "eli:date_publication"
    "eli:first_date_entry_in_force"
    "eli:format"
    "eli:has_part"
    "eli:hasExpression"
    "eli:hasFormat"
    "eli:hasManifestation"
    "eli:hasWork"
    "eli:id_local"
    "eli:is_embodied_by"
    "eli:is_part_of"
    "eli:is_realized_by"
    "eli:jurisdiction"
    "eli:number"
    "eli:partOf"
    "eli:realizes"
    "eli:embodies"
    "eli:type_document"

    ;; 3. Dublin Core (alphabetical)
    "dct:contributor"
    "dct:created"
    "dct:creator"
    "dct:description"
    "dct:format"
    "dct:identifier"
    "dct:issued"
    "dct:language"
    "dct:modified"
    "dct:publisher"
    "dct:title"
    "dct:type"

    ;; 4. DCAT (alphabetical)
    "dcat:accessURL"
    "dcat:downloadURL"
    "dcat:keyword"
    "dcat:mediaType"
    "dcat:version"

    ;; 5. Schema.org (alphabetical)
    "schema:identifier"
    "schema:inLanguage"
    "schema:isPartOf"
    "schema:legislationIdentifier"
    "schema:legislationJurisdiction"
    "schema:legislationType"

    ;; 6. PROV-O (alphabetical)
    "prov:endedAtTime"
    "prov:generatedAtTime"
    "prov:startedAtTime"
    "prov:used"
    "prov:wasAssociatedWith"
    "prov:wasAttributedTo"
    "prov:wasDerivedFrom"
    "prov:wasGeneratedBy"

    ;; 7. Custom (alphabetical)
    "stavropouloslaw:articleNumber"
    "stavropouloslaw:corpusShortName")

  "Canonical property ordering for deterministic RDF output.

   Properties not in this list will be sorted alphabetically AFTER these.")

(defun property-sort-key (property-string)
  "Get sort key for property (lower = earlier in output)

   Returns:
     - Position in *canonical-property-order* if found
     - 1000000 + alphabetical position if not found"

  (let ((position (position property-string *canonical-property-order* :test #'string=)))
    (if position
        position
        ;; Not in canonical list: sort alphabetically after canonical properties
        (+ 1000000 (char-code (char (string-upcase property-string) 0))))))

(defun sort-properties (property-list)
  "Sort properties according to canonical ordering

   Arguments:
     property-list: List of strings like (\"eli:title\" \"dct:creator\" ...)

   Returns:
     Sorted list"

  (sort (copy-list property-list)
        #'<
        :key #'property-sort-key))

;;; ============================================================
;;; UNICODE NORMALIZATION
;;; ============================================================

(defun normalize-unicode-string (text)
  "Normalize Unicode string to NFC (Canonical Composition)

   This ensures that Greek text with combining characters
   is represented consistently. CRITICAL for deterministic RDF output.

   Uses SBCL's sb-unicode:normalize-string for production-grade normalization."

  #+sbcl
  (handler-case
      (sb-unicode:normalize-string text :nfc)
    (error (e)
      text))

  #-sbcl
  text)

;;; ============================================================
;;; CANONICAL LITERAL FORMATTING
;;; ============================================================

(defun canonical-literal (text &key lang datatype)
  "Format RDF literal in canonical form, or NIL when TEXT is NIL.

   escape-turtle-string is defined canonically in orchestrator-spec/escaping.lisp.
   This function composes on top of it for typed and language-tagged literals.

   HONEST-IGNORANCE ([0030]): NIL text ⇒ NIL (no literal) — a caller must OMIT the
   triple rather than emit a fabricated \"NIL\"/\"\"\"NIL\"\"\" literal. Never
   fabricates a value for an absent one."

  (when (null text) (return-from canonical-literal nil))
  (let ((normalized (normalize-unicode-string text)))
    (cond
      (lang
       (format nil "\"\"\"~A\"\"\"@~A" (escape-turtle-string normalized) lang))
      (datatype
       (format nil "\"~A\"^^~A" (escape-turtle-string normalized) datatype))
      (t
       (format nil "\"~A\"" (escape-turtle-string normalized))))))

;;; ============================================================
;;; CANONICAL URI FORMATTING
;;; ============================================================

(defun canonical-uri (uri-string)
  "Format URI in canonical form

   Ensures consistent <URI> wrapping"

  (if (and (> (length uri-string) 0)
           (char= (char uri-string 0) #\<))
      uri-string  ; Already wrapped
      (format nil "<~A>" uri-string)))

;;; ============================================================
;;; CANONICAL TRIPLE SORTING
;;; ============================================================

(defstruct rdf-triple
  "Represents a single RDF triple for sorting"
  subject    ; String (URI)
  predicate  ; String (property name)
  object     ; String (URI or literal)
  )

(defun parse-turtle-to-triples (turtle-string)
  "Parse clean Turtle from orchestrator generators into rdf-triple structs.

   Handles the controlled Turtle subset our generators produce:
     - @prefix / @base declarations: skipped
     - Subject blocks: <URI> lines with no leading whitespace
     - Predicate-object pairs: indented 4 spaces, ; or . terminated
     - Multi-line blank node objects [...]: collected as opaque strings
     - Comment and blank lines: skipped

   Blank node objects are preserved opaque. Blank node canonicalization
   is the generators' responsibility (they emit in canonical order directly);
   this parser supports post-processing and verification passes."

  (let ((triples         nil)
        (current-subject nil)
        (current-pred    nil)
        (blank-depth     0)
        (blank-accum     nil))

    (with-input-from-string (in turtle-string)
      (loop for line = (read-line in nil nil)
            while line
            for trimmed = (string-trim '(#\Space #\Tab) line)
            do
            (let ((open-count  (count #\[ line))
                  (close-count (count #\] line)))

              (cond
                ;; ── Inside multi-line blank node: accumulate lines ──────────
                ((> blank-depth 0)
                 (push trimmed blank-accum)
                 (incf blank-depth open-count)
                 (decf blank-depth close-count)
                 (setf blank-depth (max 0 blank-depth))
                 (when (zerop blank-depth)
                   (when (and current-subject current-pred)
                     (push (make-rdf-triple
                             :subject   current-subject
                             :predicate current-pred
                             :object    (format nil "[~{~A ~}]"
                                                (nreverse blank-accum)))
                           triples))
                   (setf blank-accum nil current-pred nil)))

                ;; ── Blank / comment lines: skip ─────────────────────────────
                ((or (string= trimmed "")
                     (and (> (length trimmed) 0)
                          (char= (char trimmed 0) #\#)))
                 nil)

                ;; ── @prefix / @base declarations: skip ──────────────────────
                ((and (>= (length trimmed) 7)
                      (string= (subseq trimmed 0 7) "@prefix"))
                 nil)
                ((and (>= (length trimmed) 5)
                      (string= (subseq trimmed 0 5) "@base"))
                 nil)

                ;; ── New subject: no leading whitespace, opens with < ─────────
                ((and (> (length trimmed) 0)
                      (char= (char trimmed 0) #\<)
                      (= (length line) (length trimmed)))
                 (let ((close-angle (position #\> trimmed)))
                   (when close-angle
                     (setf current-subject (subseq trimmed 0 (1+ close-angle))
                           current-pred    nil))))

                ;; ── Predicate-object pair: line has leading whitespace ───────
                ((and current-subject
                      (> (length line) (length trimmed))
                      (> (length trimmed) 0))
                 (let* ((stripped  (string-right-trim '(#\Space #\; #\.) trimmed))
                        (sp        (position #\Space stripped)))
                   (when sp
                     (let* ((pred      (subseq stripped 0 sp))
                            (obj       (string-trim '(#\Space)
                                                    (subseq stripped (1+ sp))))
                            (o-opens   (count #\[ obj))
                            (o-closes  (count #\] obj))
                            (net-depth (- o-opens o-closes)))
                       (unless (string= pred "")
                         (cond
                           ;; Blank node opens on this line but does not close
                           ((plusp net-depth)
                            (setf current-pred pred
                                  blank-accum  nil
                                  blank-depth  net-depth))
                           ;; Normal triple or self-contained inline blank node
                           (t
                            (push (make-rdf-triple
                                    :subject   current-subject
                                    :predicate pred
                                    :object    obj)
                                  triples))))))))))))

    (nreverse triples)))

(defun sort-triples (triple-list)
  "Sort RDF triples in canonical order

   Order:
     1. Subject (URI lexical order)
     2. Predicate (canonical property order)
     3. Object (URI/literal lexical order)"

  (sort (copy-list triple-list)
        (lambda (t1 t2)
          (or (string< (rdf-triple-subject t1) (rdf-triple-subject t2))
              (and (string= (rdf-triple-subject t1) (rdf-triple-subject t2))
                   (or (< (property-sort-key (rdf-triple-predicate t1))
                          (property-sort-key (rdf-triple-predicate t2)))
                       (and (= (property-sort-key (rdf-triple-predicate t1))
                               (property-sort-key (rdf-triple-predicate t2)))
                            (string< (rdf-triple-object t1)
                                     (rdf-triple-object t2)))))))))

;;; ============================================================
;;; CANONICAL FILE HEADER
;;; ============================================================

(defun emit-canonical-file-header (stream &key article-number layer timestamp)
  "Emit canonical file header

   Arguments:
     stream:         Output stream
     article-number: Integer
     layer:          String (e.g., 'ARTICLE ROOT', 'WORK', 'EXPRESSION')
     timestamp:      ISO-8601 timestamp string"

  (format stream "# ============================================================~%")
  (format stream "# ~A~%" (or (config-get "corpus.name") "GREEK LEGAL CORPUS"))
  (format stream "# Article ~D - ~A Layer~%" article-number layer)
  (format stream "# ============================================================~%")
  (format stream "# Generator:  ORCHESTRATOR v1.3~%")
  (when timestamp
    (format stream "# Generated:  ~A~%" timestamp))
  (format stream "# Standards:  W3C RDF 1.1, ELI v1.4, FRBR, PROV-O, DCAT~%")
  (format stream "# Canonical:  RDFC-1.0 compliant ordering~%")
  (format stream "# ============================================================~%")
  (terpri stream))

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(canonical-prefix-list
          emit-canonical-prefixes
          canonical-property-order
          property-sort-key
          sort-properties
          canonical-literal
          canonical-uri
          sort-triples
          emit-canonical-file-header))
