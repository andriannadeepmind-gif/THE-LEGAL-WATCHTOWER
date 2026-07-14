;;;; systems/orchestrator-model/normalized-input.lisp
;;;; Intermediate Internal Representation (IIR) - DeepMind-GRADE
;;;;
;;;; Normalized article input between parse and FRBR generation
;;;; Ensures deterministic FRBR construction regardless of parser changes

(in-package :orchestrator.model)

;;; ============================================================
;;; NORMALIZED ARTICLE INPUT - IIR
;;; ============================================================

(defclass normalized-article-input ()
  ((article-number :accessor article-number
                   :initarg :article-number
                   :type (integer 1 *)
                   :documentation "Article number (1-based, numeric base only)")

   (article-label :accessor article-label
                  :initarg :article-label
                  :type string
                  :documentation "Full article label, e.g. '5' or '5Α' or '9Α'")

   (identity-segment :accessor article-identity
                     :initarg :identity
                     :initform nil
                     :documentation "[0088 Φ6γ-Α] TYPED ταυτότητα από την έδρα
                      orchestrator.identity: article-segment (:article ΒΑΣΗ
                      ΤΑΚΤΙΚΗ-ΘΕΣΗ), υπολογισμένο στην κατασκευή από το
                      resolved label — το IIR κουβαλά την ταυτότητα typed
                      μέσα στο FRBR μονοπάτι.")

   (article-title :accessor article-title
                  :initarg :article-title
                  :type string
                  :documentation "Full article title (normalized UTF-8 NFC)")

   (article-content :accessor article-content
                    :initarg :article-content
                    :type string
                    :documentation "Article body text (normalized UTF-8 NFC)")

   (source-type :accessor source-type
                :initarg :source-type
                :type keyword
                :documentation "Source type (:pdf, :json, :xml)")

   (source-path :accessor source-path
                :initarg :source-path
                :type (or string pathname)
                :documentation "Original source file path")

   (extraction-timestamp :accessor extraction-timestamp
                         :initarg :extraction-timestamp
                         :type string
                         :documentation "ISO-8601 timestamp of extraction")

   (extraction-confidence :accessor extraction-confidence
                          :initarg :extraction-confidence
                          :type (float 0.0 1.0)
                          :initform 1.0
                          :documentation "Confidence score (0.0-1.0)")

   (source-metadata :accessor source-metadata
                    :initarg :source-metadata
                    :initform nil
                    :type list
                    :documentation "Additional metadata (plist)"))

  (:documentation "Normalized intermediate representation for article input

                   This IIR ensures:
                   - Parser independence (FRBR generation doesn't depend on parser)
                   - Text normalization (UTF-8 NFC, whitespace normalized)
                   - Metadata preservation (source tracking, confidence)
                   - Deterministic FRBR construction

                   Flow:
                     parse-pdf → normalized-article-input → FRBR stack"))

;;; ============================================================
;;; CONSTRUCTOR
;;; ============================================================

(defun make-normalized-article-input (&key
                                      article-number
                                      article-label
                                      article-title
                                      article-content
                                      source-type
                                      source-path
                                      (extraction-timestamp (get-iso8601-timestamp))
                                      (extraction-confidence 1.0)
                                      (source-metadata nil))
  "Create normalized article input with validation

   Arguments:
     article-number:           Integer (1-based, numeric base — 5 for both '5' and '5Α')
     article-label:            String label (e.g. '5' or '5Α'); defaults to (format nil ~D article-number)
     article-title:            String (will be normalized)
     article-content:          String (will be normalized)
     source-type:              Keyword (:pdf, :json, :xml)
     source-path:              String or pathname
     extraction-timestamp:     ISO-8601 string (auto-generated if not provided)
     extraction-confidence:    Float 0.0-1.0 (default: 1.0)
     source-metadata:          Plist (optional)

   Returns:
     normalized-article-input instance

   Normalization applied:
     - UTF-8 NFC normalization
     - Horizontal whitespace collapse (newlines preserved — paragraph boundaries)
     - Title extraction (if contains 'Άρθρο N - ')
     - Content cleanup"

  ;; Validation
  (check-type article-number (integer 1 *))
  (check-type article-title string)
  (check-type article-content string)
  (check-type source-type keyword)
  (check-type extraction-confidence (float 0.0 1.0))

  ;; Normalize text (UTF-8 NFC + whitespace, newlines preserved)
  (let ((normalized-title (normalize-text article-title))
        (normalized-content (normalize-text article-content))
        (resolved-label (or article-label (format nil "~D" article-number))))

    (make-instance 'normalized-article-input
                   :article-number article-number
                   :article-label resolved-label
                   ;; [0088 Φ6γ-Α] typed ταυτότητα ΣΤΗ γέννηση του IIR — από
                   ;; την έδρα, με το ΙΔΙΟ συμβόλαιο σφάλματος του builder
                   :identity (%article-identity-segment-for resolved-label article-number)
                   :article-title normalized-title
                   :article-content normalized-content
                   :source-type source-type
                   :source-path source-path
                   :extraction-timestamp extraction-timestamp
                   :extraction-confidence extraction-confidence
                   :source-metadata source-metadata)))

;;; ============================================================
;;; TEXT NORMALIZATION
;;; ============================================================

(defun normalize-text (text)
  "Normalize text for deterministic processing

   Normalization steps:
   1. UTF-8 NFC normalization (canonical composition) - CRITICAL for Greek text
   2. Trim leading/trailing whitespace
   3. Collapse multiple spaces to single space
   4. Normalize line endings to LF
   5. Dehyphenate Greek words (SAFETY NET)
   6. Remove FEK noise (SAFETY NET)

   Returns: Normalized string"

  (when (null text)
    (return-from normalize-text ""))

  ;; Step 1: Unicode NFC normalization (CRITICAL for Greek accented characters)
  (let ((nfc-normalized (unicode-nfc-normalize text)))

    ;; Step 2-4: Whitespace and line ending normalization
    ;; CRITICAL: newlines are preserved — they delimit paragraph boundaries in the
    ;; JSON content-list join and are required by parse-article-into-paragraphs.
    ;; Only horizontal whitespace (spaces/tabs) is collapsed to a single space.
    (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return) nfc-normalized)))
      ;; Normalize CR/CRLF → LF before horizontal collapse
      (let ((lf-normalized (cl-ppcre:regex-replace-all "\\r\\n|\\r" trimmed (string #\Newline))))
        ;; Collapse runs of horizontal whitespace only (NOT newlines)
        (let ((collapsed (cl-ppcre:regex-replace-all "[ \\t]+" lf-normalized " ")))
          ;; Step 5: Final dehyphenation (SAFETY NET)
          (let ((dehyphenated (dehyphenate-greek collapsed)))
            ;; Step 6: Remove FEK noise (SAFETY NET)
            (remove-fek-noise dehyphenated)))))))

(defun unicode-nfc-normalize (text)
  "Apply Unicode NFC (Canonical Composition) normalization

   This is CRITICAL for Greek text because accented characters can be
   represented in two ways:
     - Precomposed: ά (single codepoint U+03AC)
     - Decomposed: α + ́ (base + combining accent U+03B1 + U+0301)

   NFC ensures canonical representation (precomposed form).

   Implementation: SBCL sb-unicode:normalize-string.

   P1.5-pre [0054]: αποτυχία NFC ⇒ ΣΦΑΛΜΑ, ΠΟΤΕ «χρήση αρχικού». Αυτή είναι
   η έδρα IIR — το ΚΑΝΟΝΙΚΟΠΟΙΗΜΕΝΟ κείμενο σφραγίζεται ΑΝΕΞΙΤΗΛΑ με SHA-512/
   RFC-3161 στα releases· ακανονικοποίητα bytes σε νομικό αρτεφάκτ (ή σε
   περιβάλλον χωρίς sb-unicode) ήταν ακριβώς η απαγορευμένη κλάση σιωπηλού
   fallback (δίδυμο του rdf-canonicalization που ήδη κλείστηκε στο [0052])."
  #+sbcl
  (handler-case
      (sb-unicode:normalize-string text :nfc)
    (error (e)
      (error "IIR NFC normalization failed — refusing to seal non-canonical text into legal identity: ~A" e)))

  #-sbcl
  (error "unicode-nfc-normalize: NFC απαιτεί SBCL (sb-unicode) — καμία σιωπηλή παράκαμψη κανονικοποίησης στην έδρα IIR"))

(defun dehyphenate-greek (text)
  "Remove Greek word hyphenation as final safety net.

   FEK PDFs often have words split across lines with hyphens:
     'ορισμέ- νες' → 'ορισμένες'
     'απαγο- ρεύεται' → 'απαγορεύεται'

   Uses LITERAL Unicode hyphen characters for maximum compatibility.
   Hyphens matched: - ‐ ‑ ‒ – — ― −

   Returns: Text with Greek dehyphenation applied"
  (when (null text)
    (return-from dehyphenate-greek ""))

  (let ((result text))
    ;; Pattern 1: lowercase Greek + hyphen + space + lowercase Greek
    ;; This is the main pattern for FEK documents
    (setf result (cl-ppcre:regex-replace-all
                  "([α-ωά-ώ])[-‐‑‒–—―−] ([α-ωά-ώ])"
                  result "\\1\\2"))

    ;; Pattern 2: uppercase Greek + hyphen + space + lowercase Greek
    (setf result (cl-ppcre:regex-replace-all
                  "([Α-ΩΆ-Ώ])[-‐‑‒–—―−] ([α-ωά-ώ])"
                  result "\\1\\2"))

    ;; Pattern 3: Any Greek letter + hyphen + multiple spaces + lowercase Greek
    (setf result (cl-ppcre:regex-replace-all
                  "([α-ωά-ώΑ-ΩΆ-Ώ])[-‐‑‒–—―−]\\s+([α-ωά-ώ])"
                  result "\\1\\2"))

    result))

(defun remove-fek-noise (text)
  "Remove FEK-specific noise from text as final safety net.

   Catches FEK headers and section markers that slipped through earlier layers.

   Returns: Cleaned text"
  (when (null text)
    (return-from remove-fek-noise ""))

  (let ((result text))
    ;; FEK headers
    (setf result (cl-ppcre:regex-replace-all
                  "ΕΦΗΜΕΡΙΔΑ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ \\d+"
                  result ""))
    (setf result (cl-ppcre:regex-replace-all
                  "ΕΦΗΜΕΡΙΔΑ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ"
                  result ""))
    ;; Generic FEK patterns
    (setf result (cl-ppcre:regex-replace-all
                  "ΕΦΗΜΕΡΙ.{0,30}ΚΥΒΕΡΝΗΣ.{0,20}"
                  result ""))

    ;; Section markers (ΜΕΡΟΣ, ΤΜΗΜΑ, ΚΕΦΑΛΑΙΟ)
    (setf result (cl-ppcre:regex-replace-all
                  "ΜΕΡΟΣ (ΠΡΩΤΟ|ΔΕΥΤΕΡΟ|ΤΡΙΤΟ|ΤΕΤΑΡΤΟ|[Α-Ω])[α-ωά-ώΑ-Ω\\s]*"
                  result ""))
    (setf result (cl-ppcre:regex-replace-all
                  "ΤΜΗΜΑ [ΑΒΓ∆Α-Ω].?[α-ωά-ώΑ-Ω\\s]*"
                  result ""))
    (setf result (cl-ppcre:regex-replace-all
                  "ΚΕΦΑΛΑΙΟ [Α-Ω][α-ωά-ώΑ-Ω\\s]*"
                  result ""))

    ;; Clean up multiple horizontal spaces left by removal (preserve newlines)
    (setf result (cl-ppcre:regex-replace-all "[ \\t]{2,}" result " "))
    ;; Trim
    (string-trim '(#\Space #\Tab #\Newline #\Return) result)))

;;; ============================================================
;;; CONVERSION - Article to Normalized Input
;;; ============================================================

(defun article-to-normalized-input (article source-type source-path)
  "Convert existing article instance to normalized input

   This allows backward compatibility with existing pipeline.

   Arguments:
     article:     Article instance (orchestrator.model:article)
     source-type: Keyword (:pdf, :json, :xml)
     source-path: String or pathname

   Returns:
     normalized-article-input instance"

  (make-normalized-article-input
    :article-number (article-number article)
    :article-title (article-title article)
    :article-content (article-content article)
    :source-type source-type
    :source-path source-path
    :extraction-confidence 1.0
    ;; P0 [0041]: διατήρησε το ΠΡΑΓΜΑΤΙΚΟ label (π.χ. «5Α») όταν υπάρχει — το
    ;; παλιό (format ~D number) πετούσε το γράμμα, και ένα lettered άρθρο θα
    ;; κατέρρεε στη βασική ταυτότητα για όποιον caller περνά από εδώ.
    :article-label (or (article-label article)
                       (format nil "~D" (article-number article)))))

;;; ============================================================
;;; EXPORTS
;;; ============================================================
;;;
;;; All exports handled by systems/orchestrator-model/package.lisp
;;; Centralized package definition - no inline exports needed
;;; ============================================================
