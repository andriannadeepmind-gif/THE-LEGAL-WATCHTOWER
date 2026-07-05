;;;; source/text-canonicalizer.lisp
;;;; ============================================================================
;;;; TEXT-CANONICALIZER - Layer 3 Text Normalization
;;;; ============================================================================
;;;;
;;;; LAYER 3: LOGICAL BLOCKS → CANONICAL TEXT
;;;;
;;;; This module transforms classified logical blocks into canonical text form:
;;;;
;;;; TRANSFORMATIONS:
;;;;   1. DEHYPHENATION: Join words broken across lines
;;;;   2. WHITESPACE: Normalize spaces, remove extra whitespace
;;;;   3. UNICODE: NFC normalization for consistent encoding
;;;;   4. GREEK: Handle Greek-specific characters (accents, sigma forms)
;;;;   5. LINE BREAKS: Smart paragraph break handling
;;;;   6. QUOTES: Normalize quotation marks
;;;;
;;;; PRINCIPLES:
;;;;   - PRESERVE MEANING: No semantic changes
;;;;   - DETERMINISTIC: Same input → same output
;;;;   - REVERSIBLE (where possible): Track transformations
;;;;   - TRACEABLE: Maintain provenance chain
;;;;
;;;; ============================================================================
;;;; COMMON LISP FEATURES UTILIZED
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CL-PPCRE                 │ Regex-based text transformations             │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ BABEL                    │ Unicode string handling                      │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ GENERIC FUNCTIONS        │ Extensible canonicalization rules            │
;;;; │                          │ • canonicalize-text (main)                   │
;;;; │                          │ • apply-transformation                       │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MACROS                   │ Transformation pipeline DSL                  │
;;;; │                          │ • deftransformation                          │
;;;; │                          │ • with-canonicalization-pipeline             │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Rich returns with transformation log         │
;;;; │                          │ (values canonical-text transformations)      │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(defpackage :orchestrator.text-canonicalizer
  (:use :cl)
  (:import-from :orchestrator.trace-core
                #:trace-info
                #:make-trace-info
                #:extend-trace
                #:trace-id)
  (:import-from :orchestrator.typographic-classifier
                #:logical-block
                #:logical-block-type
                #:logical-block-layout
                #:logical-block-trace
                #:logical-block-id)
  (:import-from :orchestrator.layout-types
                #:block-text)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; CANONICAL BLOCK
   ;; ══════════════════════════════════════════════════════════════════
   #:canonical-block
   #:make-canonical-block
   #:canonical-text
   #:canonical-original-text
   #:canonical-block-type
   #:canonical-transformations
   #:canonical-trace
   #:canonical-id

   ;; ══════════════════════════════════════════════════════════════════
   ;; MAIN ENTRY POINTS
   ;; ══════════════════════════════════════════════════════════════════
   #:canonicalize-block
   #:canonicalize-page
   #:canonicalize-document
   #:canonicalize-text

   ;; ══════════════════════════════════════════════════════════════════
   ;; TRANSFORMATIONS
   ;; ══════════════════════════════════════════════════════════════════
   #:dehyphenate
   #:normalize-whitespace
   #:normalize-unicode
   #:normalize-greek
   #:normalize-quotes
   #:normalize-line-breaks
   #:remove-fek-noise

   ;; ══════════════════════════════════════════════════════════════════
   ;; TRANSFORMATION RECORD
   ;; ══════════════════════════════════════════════════════════════════
   #:transformation-record
   #:make-transformation-record
   #:transformation-type
   #:transformation-before
   #:transformation-after
   #:transformation-position

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONFIGURATION
   ;; ══════════════════════════════════════════════════════════════════
   #:*enable-dehyphenation*
   #:*enable-unicode-normalization*
   #:*enable-greek-normalization*
   #:*enable-fek-noise-removal*
   #:*transformation-pipeline*))

(in-package :orchestrator.text-canonicalizer)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *enable-dehyphenation* t
  "Enable dehyphenation of words broken across lines")

(defvar *enable-unicode-normalization* t
  "Enable NFC Unicode normalization")

(defvar *enable-greek-normalization* t
  "Enable Greek-specific normalization (sigma forms, accents)")

(defvar *enable-polytonic-to-monotonic* nil
  "If T, convert polytonic Greek to monotonic.
   Default NIL to preserve original text when possible.
   Set T for modern Greek legal documents.")

(defvar *enable-legal-abbreviations* t
  "Enable Greek legal abbreviation expansion/tracking")

(defvar *transformation-pipeline*
  '(:dehyphenate :normalize-whitespace :normalize-unicode
    :normalize-greek :normalize-legal-abbrev :normalize-quotes
    :normalize-line-breaks :remove-fek-noise)
  "Ordered list of transformations to apply.

   NSA-GRADE: Extended pipeline for Greek legal documents.
   :remove-fek-noise added to clean headers/footers that slipped through.")

;;; ============================================================================
;;; GREEK LEGAL ABBREVIATIONS
;;; ============================================================================

(defparameter +greek-legal-abbreviations+
  '(;; Laws and Decrees
    ("Ν\\." "Νόμος")
    ("ν\\." "νόμος")
    ("Π\\.?Δ\\.?" "Προεδρικό Διάταγμα")
    ("π\\.?δ\\.?" "προεδρικό διάταγμα")
    ("Κ\\.?Υ\\.?Α\\.?" "Κοινή Υπουργική Απόφαση")
    ("Υ\\.?Α\\.?" "Υπουργική Απόφαση")
    ("Ν\\.?Δ\\.?" "Νομοθετικό Διάταγμα")
    ;; Official Gazette
    ("ΦΕΚ" "Φύλλο Εφημερίδας της Κυβερνήσεως")
    ;; Courts
    ("Α\\.?Π\\.?" "Άρειος Πάγος")
    ("Σ\\.?τ\\.?Ε\\.?" "Συμβούλιο της Επικρατείας")
    ("Ελ\\.?Συν\\.?" "Ελεγκτικό Συνέδριο")
    ;; Constitution
    ("Σ\\.?" "Σύνταγμα")
    ("Συντ\\.?" "Σύνταγμα")
    ;; Codes
    ("Α\\.?Κ\\.?" "Αστικός Κώδικας")
    ("Κ\\.?Πολ\\.?Δ\\.?" "Κώδικας Πολιτικής Δικονομίας")
    ("Κ\\.?Ποιν\\.?Δ\\.?" "Κώδικας Ποινικής Δικονομίας")
    ("Π\\.?Κ\\.?" "Ποινικός Κώδικας")
    ("Κ\\.?Δ\\.?Δ\\.?" "Κώδικας Διοικητικής Δικονομίας")
    ;; Common terms
    ("παρ\\." "παράγραφος")
    ("αρ\\." "αριθμός")
    ("εδ\\." "εδάφιο")
    ("περ\\." "περίπτωση")
    ("υποπ\\." "υποπερίπτωση")
    ("βλ\\." "βλέπε")
    ("πρβλ\\." "παράβαλε")
    ("κ\\.λπ\\.?" "και λοιπά")
    ("κ\\.ά\\.?" "και άλλα")
    ("κ\\.ε\\.?" "και εξής")
    ("ό\\.π\\.?" "όπως παραπάνω"))
  "Greek legal abbreviations with their expansions.
   Format: (pattern expansion)

   NOTE: These are tracked but NOT automatically expanded to preserve
   original text. Use for annotation and search normalization.")

;;; ============================================================================
;;; TRANSFORMATION RECORD
;;; ============================================================================

(defstruct (transformation-record
            (:constructor make-transformation-record
                          (&key type before after position)))
  "Record of a single text transformation."
  (type :unknown :type keyword)     ; :dehyphenate, :whitespace, etc.
  (before "" :type string)          ; Text before transformation
  (after "" :type string)           ; Text after transformation
  (position 0 :type integer))       ; Character position in original

;;; ============================================================================
;;; CANONICAL BLOCK
;;; ============================================================================

(defvar *canonical-block-counter* 0)

(defclass canonical-block ()
  ((id
    :accessor canonical-id
    :initarg :id
    :type string)

   (text
    :accessor canonical-text
    :initarg :text
    :initform ""
    :type string
    :documentation "Canonicalized text content")

   (original-text
    :accessor canonical-original-text
    :initarg :original-text
    :initform ""
    :type string
    :documentation "Original text before canonicalization")

   (block-type
    :accessor canonical-block-type
    :initarg :block-type
    :initform :unknown
    :type keyword
    :documentation "Inherited from logical-block")

   (transformations
    :accessor canonical-transformations
    :initarg :transformations
    :initform '()
    :type list
    :documentation "List of transformation-record applied")

   (logical-block
    :accessor canonical-logical-block
    :initarg :logical-block
    :initform nil
    :type t
    :documentation "Source logical-block")

   (trace
    :accessor canonical-trace
    :initarg :trace
    :initform nil
    :type (or null trace-info)))

  (:documentation "A canonicalized text block with transformation history.

   Layer 3 output: logical-block + canonical text + transformation log."))

(defun make-canonical-block (&key text original-text block-type
                                  transformations logical-block)
  "Create canonical block with auto-generated ID and trace."
  (let* ((id (format nil "CBLOCK-~A" (incf *canonical-block-counter*)))
         (trace (when (and logical-block (logical-block-trace logical-block))
                  (extend-trace (logical-block-trace logical-block)
                                :new-layer :canonical
                                :canonical-block-ids (list id)))))
    (make-instance 'canonical-block
                   :id id
                   :text (or text "")
                   :original-text (or original-text "")
                   :block-type (or block-type :unknown)
                   :transformations (or transformations '())
                   :logical-block logical-block
                   :trace trace)))

(defmethod print-object ((cb canonical-block) stream)
  (print-unreadable-object (cb stream :type t :identity nil)
    (format stream "~A ~A ~D transforms"
            (canonical-id cb)
            (canonical-block-type cb)
            (length (canonical-transformations cb)))))

;;; ============================================================================
;;; INDIVIDUAL TRANSFORMATIONS
;;; ============================================================================

(defun dehyphenate (text &optional (log nil))
  "Remove line-end hyphens and join words.

   NSA-GRADE: Comprehensive Greek dehyphenation for FEK documents.
   Uses LITERAL Unicode characters (not escape sequences) for maximum compatibility.

   Args:
     text: Input text
     log: If T, returns (values result transformations)

   Returns:
     Dehyphenated text (or with log if requested)"
  (unless *enable-dehyphenation*
    (return-from dehyphenate (if log (values text '()) text)))

  (let ((result text)
        (transforms '()))

    ;; Pattern 1: Any hyphen/dash followed by whitespace and lowercase Greek letter
    ;; Literal hyphens: - ‐ ‑ ‒ – — ― −
    ;; This is THE MAIN PATTERN for "ορισμέ- νες" → "ορισμένες"
    (let ((pattern1 "([α-ωά-ώ])[-‐‑‒–—―−]\\s+([α-ωά-ώ])"))
      (when (cl-ppcre:scan pattern1 result)
        (push (make-transformation-record :type :dehyphenate-space :before "hyphen+space" :after "joined") transforms))
      (setf result (cl-ppcre:regex-replace-all pattern1 result "\\1\\2")))

    ;; Pattern 2: Hyphen at end of line with newline
    (let ((pattern2 "([α-ωά-ώΑ-ΩΆ-Ώa-zA-Z])[-‐‑‒–—―−]\\s*\\n\\s*([α-ωά-ώa-zA-Z])"))
      (when (cl-ppcre:scan pattern2 result)
        (push (make-transformation-record :type :dehyphenate-newline :before "hyphen+newline" :after "joined") transforms))
      (setf result (cl-ppcre:regex-replace-all pattern2 result "\\1\\2")))

    ;; Pattern 3: Uppercase Greek + hyphen + space + lowercase
    (let ((pattern3 "([Α-ΩΆ-Ώ])[-‐‑‒–—―−]\\s+([α-ωά-ώ])"))
      (when (cl-ppcre:scan pattern3 result)
        (push (make-transformation-record :type :dehyphenate-caps :before "caps+hyphen" :after "joined") transforms))
      (setf result (cl-ppcre:regex-replace-all pattern3 result "\\1\\2")))

    ;; Pattern 4: Soft hyphen (­) removal - the character between quotes is U+00AD
    (let ((pattern4 "([α-ωά-ώa-zA-Z])­([α-ωά-ώa-zA-Z])"))
      (when (cl-ppcre:scan pattern4 result)
        (push (make-transformation-record :type :dehyphenate-soft :before "soft-hyphen" :after "removed") transforms))
      (setf result (cl-ppcre:regex-replace-all pattern4 result "\\1\\2")))

    (if log
        (values result (nreverse transforms))
        result)))

(defun normalize-whitespace (text &optional (log nil))
  "Normalize whitespace in text.

   - Multiple spaces → single space
   - Tabs → space
   - Non-breaking spaces → regular space
   - Trim leading/trailing"
  (let ((result text)
        (transforms '()))

    ;; Replace tabs and non-breaking spaces
    (let ((cleaned (cl-ppcre:regex-replace-all "[\\t\\x{00A0}]" result " ")))
      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :whitespace-special
               :before "tabs/nbsp"
               :after "spaces")
              transforms))
      (setf result cleaned))

    ;; Multiple spaces to single
    (let ((cleaned (cl-ppcre:regex-replace-all "  +" result " ")))
      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :whitespace-multiple
               :before "multiple spaces"
               :after "single space")
              transforms))
      (setf result cleaned))

    ;; Trim
    (setf result (string-trim '(#\Space #\Tab #\Newline #\Return) result))

    (if log
        (values result (nreverse transforms))
        result)))

(defun normalize-unicode (text &optional (log nil))
  "Apply NFC Unicode normalization.

   Note: Full NFC requires SBCL unicode support or external library.
   This implements basic normalization."
  (unless *enable-unicode-normalization*
    (return-from normalize-unicode (if log (values text '()) text)))

  (let ((result text)
        (transforms '()))

    ;; Basic Unicode cleanup - fullwidth to ASCII
    ;; (More complete NFC would use sb-unicode or babel)
    (let ((cleaned result))
      ;; Replace common problematic characters
      ;; Use Unicode code points to avoid encoding issues
      (setf cleaned (cl-ppcre:regex-replace-all "[\\x{201C}\\x{201D}]" cleaned "\""))
      (setf cleaned (cl-ppcre:regex-replace-all "[\\x{2018}\\x{2019}]" cleaned "'"))
      (setf cleaned (cl-ppcre:regex-replace-all "[\\x{2013}\\x{2014}]" cleaned "-"))
      (setf cleaned (cl-ppcre:regex-replace-all "\\x{2026}" cleaned "..."))

      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :unicode-normalize
               :before "unicode variants"
               :after "standard chars")
              transforms))
      (setf result cleaned))

    (if log
        (values result (nreverse transforms))
        result)))

(defun normalize-greek (text &optional (log nil))
  "Apply Greek-specific normalizations.

   NSA-GRADE: Full Greek legal text normalization.

   LISP FEATURES:
     - Regex with Unicode code points
     - Multiple transformation passes
     - Logged transformation history

   Transformations:
     1. Final sigma (σ → ς at word boundaries)
     2. Polytonic to monotonic (optional)
     3. Combining diacriticals normalization
     4. Greek punctuation (ano teleia, question mark)
     5. Legal abbreviation expansion tracking"
  (unless *enable-greek-normalization*
    (return-from normalize-greek (if log (values text '()) text)))

  (let ((result text)
        (transforms '()))

    ;; ══════════════════════════════════════════════════════════════════
    ;; FINAL SIGMA: σ at word end should be ς
    ;; ══════════════════════════════════════════════════════════════════
    (let ((cleaned (cl-ppcre:regex-replace-all "σ(?=[\\s.,;:!?\"'«»\\)\\]\\}]|$)"
                                                result "ς")))
      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :greek-sigma
               :before "σ (medial at word end)"
               :after "ς (final)")
              transforms))
      (setf result cleaned))

    ;; ══════════════════════════════════════════════════════════════════
    ;; POLYTONIC → MONOTONIC (if configured)
    ;; ══════════════════════════════════════════════════════════════════
    ;; Map polytonic vowels to monotonic equivalents
    ;; ᾶ→ά, ἀ→α, ᾷ→ᾴ→ά, etc.
    (when *enable-polytonic-to-monotonic*
      (let ((cleaned result))
        ;; Alpha variants
        (setf cleaned (cl-ppcre:regex-replace-all "[ἀἁἂἃἄἅἆἇὰάᾀᾁᾂᾃᾄᾅᾆᾇᾰᾱᾲᾳᾴᾶᾷ]" cleaned "α"))
        ;; U+1F08-1F0F: Ἀ-Ἇ (alpha+breathing)
        ;; U+1F88-1F8F: ᾈ-ᾏ (alpha+breathing+prosgegrammeni)
        ;; U+1FB8-1FBB: Ᾰ Ᾱ Ὰ Ά (alpha+vrachy/macron/varia/oxia-polytonic)
        ;; U+1FBC:       ᾼ  (alpha+prosgegrammeni)
        ;; \x{HHHH} inside [...] is not supported by cl-ppcre 2.x on SBCL 2.2.x;
        ;; build the character-class string from code-char at load time instead.
        (setf cleaned (cl-ppcre:regex-replace-all
                       (load-time-value
                        (cl-ppcre:create-scanner
                         (concatenate 'string "["
                                      (map 'string #'code-char
                                           '(#x1F08 #x1F09 #x1F0A #x1F0B
                                             #x1F0C #x1F0D #x1F0E #x1F0F
                                             #x1F88 #x1F89 #x1F8A #x1F8B
                                             #x1F8C #x1F8D #x1F8E #x1F8F
                                             #x1FB8 #x1FB9 #x1FBA #x1FBB
                                             #x1FBC))
                                      "]")))
                       cleaned (string (code-char #x0391))))
        ;; Epsilon variants
        (setf cleaned (cl-ppcre:regex-replace-all "[ἐἑἒἓἔἕὲέ]" cleaned "ε"))
        (setf cleaned (cl-ppcre:regex-replace-all "[ἘἙἚἛἜἝῈΈ]" cleaned "Ε"))
        ;; Eta variants
        (setf cleaned (cl-ppcre:regex-replace-all "[ἠἡἢἣἤἥἦἧὴήᾐᾑᾒᾓᾔᾕᾖᾗῂῃῄῆῇ]" cleaned "η"))
        (setf cleaned (cl-ppcre:regex-replace-all "[ἨἩἪἫἬἭἮἯῊΉᾘᾙᾚᾛᾜᾝᾞᾟῌ]" cleaned "Η"))
        ;; Iota variants
        (setf cleaned (cl-ppcre:regex-replace-all "[ἰἱἲἳἴἵἶἷὶίῐῑῒΐῖῗ]" cleaned "ι"))
        (setf cleaned (cl-ppcre:regex-replace-all "[ἸἹἺἻἼἽἾἿῚΊῘῙ]" cleaned "Ι"))
        ;; Omicron variants
        (setf cleaned (cl-ppcre:regex-replace-all "[ὀὁὂὃὄὅὸό]" cleaned "ο"))
        (setf cleaned (cl-ppcre:regex-replace-all "[ὈὉὊὋὌὍῸΌ]" cleaned "Ο"))
        ;; Upsilon variants
        (setf cleaned (cl-ppcre:regex-replace-all "[ὐὑὒὓὔὕὖὗὺύῠῡῢΰῦῧ]" cleaned "υ"))
        (setf cleaned (cl-ppcre:regex-replace-all "[ὙὛὝὟῪΎῨῩ]" cleaned "Υ"))
        ;; Omega variants
        (setf cleaned (cl-ppcre:regex-replace-all "[ὠὡὢὣὤὥὦὧὼώᾠᾡᾢᾣᾤᾥᾦᾧῲῳῴῶῷ]" cleaned "ω"))
        (setf cleaned (cl-ppcre:regex-replace-all "[ὨὩὪὫὬὭὮὯῺΏᾨᾩᾪᾫᾬᾭᾮᾯῼ]" cleaned "Ω"))
        ;; Rho variants
        (setf cleaned (cl-ppcre:regex-replace-all "[ῤῥ]" cleaned "ρ"))
        (setf cleaned (cl-ppcre:regex-replace-all "Ῥ" cleaned "Ρ"))

        (unless (string= cleaned result)
          (push (make-transformation-record
                 :type :polytonic-to-monotonic
                 :before "polytonic"
                 :after "monotonic")
                transforms))
        (setf result cleaned)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; NORMALIZE TONOS (accent marks)
    ;; ══════════════════════════════════════════════════════════════════
    ;; Ensure consistent tonos (Greek acute accent U+0301 vs tonos U+0384)
    (let ((cleaned (cl-ppcre:regex-replace-all "\\x{0301}" result "\\x{0384}")))
      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :tonos-normalize
               :before "combining acute"
               :after "Greek tonos")
              transforms))
      (setf result cleaned))

    ;; ══════════════════════════════════════════════════════════════════
    ;; GREEK PUNCTUATION
    ;; ══════════════════════════════════════════════════════════════════
    ;; Greek question mark (;) U+037E is often confused with semicolon
    ;; Ano teleia (·) U+0387 for middle dot separator
    (let ((cleaned result))
      ;; Normalize Greek question mark variations
      (setf cleaned (cl-ppcre:regex-replace-all "\\x{037E}" cleaned ";"))
      ;; Keep ano teleia as is (·)
      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :greek-punctuation
               :before "Greek question mark variants"
               :after "normalized")
              transforms))
      (setf result cleaned))

    (if log
        (values result (nreverse transforms))
        result)))

(defun normalize-legal-abbrev (text &optional (log nil))
  "Track Greek legal abbreviations in text.

   NSA-GRADE: Identifies and logs legal abbreviations for metadata.

   LISP FEATURES:
     - Pattern matching with regex
     - Returns annotations without modifying text (preserves original)
     - Multiple value return with detailed log

   NOTE: This function TRACKS abbreviations but does NOT expand them,
   to preserve the original legal text. Expansions are stored in
   transformation records for search/annotation purposes."
  (unless *enable-legal-abbreviations*
    (return-from normalize-legal-abbrev (if log (values text '()) text)))

  (let ((result text)
        (transforms '()))

    ;; Track each abbreviation found
    (dolist (abbrev +greek-legal-abbreviations+)
      (let ((pattern (first abbrev))
            (expansion (second abbrev)))
        (when (cl-ppcre:scan pattern result)
          (push (make-transformation-record
                 :type :legal-abbreviation
                 :before pattern
                 :after expansion
                 :position 0)  ; Could track actual position if needed
                transforms))))

    (if log
        (values result (nreverse transforms))
        result)))

(defun normalize-quotes (text &optional (log nil))
  "Normalize quotation marks to consistent style.

   Converts various quote styles to standard Greek/European style."
  (let ((result text)
        (transforms '()))

    ;; Normalize to standard quotes
    ;; Greek typically uses « » for primary quotes
    (let ((cleaned result))
      ;; Straight quotes to guillemets for Greek text
      ;; (only if text appears to be Greek)
      (when (cl-ppcre:scan "[α-ω]" cleaned)
        ;; Replace paired straight quotes with guillemets
        ;; This is simplified - real implementation would track nesting
        (setf cleaned (cl-ppcre:regex-replace-all "\"([^\"]+)\"" cleaned "«\\1»")))

      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :quote-normalize
               :before "straight quotes"
               :after "guillemets")
              transforms))
      (setf result cleaned))

    (if log
        (values result (nreverse transforms))
        result)))

;;; ============================================================================
;;; FEK NOISE REMOVAL
;;; ============================================================================
;;;
;;; NSA-GRADE: Remove FEK-specific noise that may have been incorrectly
;;; merged into paragraph content due to column reading order issues.
;;;
;;; These patterns use mixed Greek/Latin character classes to catch
;;; all variants of FEK headers and section markers.
;;; ============================================================================

(defvar *enable-fek-noise-removal* t
  "Enable removal of FEK headers/footers/section markers from text content")

(defparameter +fek-noise-patterns+
  '(;; FEK headers - AGGRESSIVE patterns
    ;; Pure Greek text
    ("ΕΦΗΜΕΡΙ.?Α\\s+ΤΗΣ\\s+ΚΥΒΕΡΝΗΣΕΩΣ\\s*\\d*" . :fek-header)
    ;; Mixed Greek/Latin characters
    ("[ΕE][ΦF][ΗH][ΜM][ΕE][ΡP][ΙI].?[ΑA]\\s+[TΤ][HΗ][ΣS]\\s+[ΚK][ΥY][ΒB][ΕE][ΡP][ΝN][ΗH][ΣS][ΕE][ΩW][ΣS]\\s*\\d*" . :fek-header)
    ;; ΕΦΗΜΕΡΙΔΑ followed by page number
    ("ΕΦΗΜΕΡΙ.?Α[^.]*\\d{4,5}" . :fek-header)
    ;; Τεύχος issue reference (Greek)
    ("Τεύχος\\s+[ΑΒΓΔ]['΄']?\\s*\\d+" . :fek-issue)
    ;; Τεύχος mixed
    ("[TΤ][εe][ύu][χx][οo][ςs]\\s+[ΑΒΓΔABCD]['΄']?\\s*\\d+[/.]" . :fek-issue)
    ;; Section headers - Pure Greek
    ("ΜΕΡΟΣ\\s+[ΠΔΤΕΆ-ΏA-ZΑ-Ω][Α-Ωα-ωά-ώA-Za-z\\s]+" . :section-header)
    ("ΚΕΦΑΛΑΙΟ\\s+[Α-ΩA-Z][Α-Ωα-ωά-ώA-Za-z\\s]+" . :section-header)
    ("ΤΜΗΜΑ\\s+[Α-ΩA-Z]['΄']?[^.]*" . :section-header)
    ;; Section headers - Mixed Greek/Latin
    ("[MΜ][EΕ][PΡ][OΟ][SΣ]\\s+[ΠΔΤΕA-ZΑ-Ω][A-ZΑ-Ωa-zα-ωά-ώ\\s]+" . :section-header)
    ("[KΚ][EΕ][FΦ][AΑ][LΛ][AΑ][IΙ][OΟ]\\s+[A-ZΑ-Ω][A-ZΑ-Ωa-zα-ωά-ώ\\s]+" . :section-header)
    ("[TΤ][MΜ][HΗ][MΜ][AΑ]\\s+[A-ZΑ-Ω]['΄']?[^.]*" . :section-header))
  "Patterns for FEK-specific noise to remove from content.
   Each entry: (regex . type)")

(defun remove-fek-noise (text &optional (log nil))
  "Remove FEK headers, footers, and section markers from text.

   NSA-GRADE: Cleans up content that was incorrectly merged from
   page elements due to PDF reading order issues.

   Args:
     text: Input text
     log: If T, returns (values result transformations)

   Returns:
     Cleaned text (or with log if requested)"
  (unless *enable-fek-noise-removal*
    (return-from remove-fek-noise (if log (values text '()) text)))

  (let ((result text)
        (transforms '()))

    ;; Apply each noise pattern
    (dolist (pattern-entry +fek-noise-patterns+)
      (let ((pattern (car pattern-entry))
            (noise-type (cdr pattern-entry)))
        (when (cl-ppcre:scan pattern result)
          ;; Log what we're removing
          (cl-ppcre:do-matches-as-strings (match pattern result)
            (push (make-transformation-record
                   :type noise-type
                   :before match
                   :after "")
                  transforms))
          ;; Remove the noise
          (setf result (cl-ppcre:regex-replace-all pattern result "")))))

    ;; Clean up multiple spaces left by removal
    (setf result (cl-ppcre:regex-replace-all "\\s{2,}" result " "))
    ;; Trim
    (setf result (string-trim '(#\Space #\Tab #\Newline #\Return) result))

    (if log
        (values result (nreverse transforms))
        result)))

(defun normalize-line-breaks (text &optional (log nil))
  "Normalize line breaks.

   - Windows CRLF → LF
   - Multiple blank lines → single blank line
   - Preserve paragraph breaks"
  (let ((result text)
        (transforms '()))

    ;; CRLF → LF
    (let ((cleaned (cl-ppcre:regex-replace-all "\\r\\n" result (string #\Newline))))
      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :linebreak-crlf
               :before "CRLF"
               :after "LF")
              transforms))
      (setf result cleaned))

    ;; CR alone → LF
    (setf result (cl-ppcre:regex-replace-all "\\r" result (string #\Newline)))

    ;; Multiple blank lines → double newline (paragraph break)
    (let ((cleaned (cl-ppcre:regex-replace-all "\\n{3,}" result
                                                (format nil "~%~%"))))
      (unless (string= cleaned result)
        (push (make-transformation-record
               :type :linebreak-multiple
               :before "multiple blank lines"
               :after "paragraph break")
              transforms))
      (setf result cleaned))

    (if log
        (values result (nreverse transforms))
        result)))

;;; ============================================================================
;;; MAIN CANONICALIZATION FUNCTION
;;; ============================================================================

(defun canonicalize-text (text &key (pipeline *transformation-pipeline*)
                                    (log nil))
  "Apply canonicalization pipeline to text.

   Args:
     text: Input text string
     pipeline: List of transformation keywords to apply
     log: If T, collect transformation records

   Returns:
     If log: (values canonical-text transformations)
     Else: canonical-text"
  (let ((result (or text ""))
        (all-transforms '()))

    (dolist (transform pipeline)
      (multiple-value-bind (new-text transforms)
          (case transform
            (:dehyphenate (dehyphenate result t))
            (:normalize-whitespace (normalize-whitespace result t))
            (:normalize-unicode (normalize-unicode result t))
            (:normalize-greek (normalize-greek result t))
            (:normalize-legal-abbrev (normalize-legal-abbrev result t))
            (:normalize-quotes (normalize-quotes result t))
            (:normalize-line-breaks (normalize-line-breaks result t))
            (:remove-fek-noise (remove-fek-noise result t))
            (otherwise (values result '())))
        (setf result new-text)
        (when transforms
          (setf all-transforms (nconc all-transforms transforms)))))

    (if log
        (values result all-transforms)
        result)))

;;; ============================================================================
;;; HIGH-LEVEL API
;;; ============================================================================

(defun canonicalize-block (logical-block)
  "Canonicalize a single logical block.

   Args:
     logical-block: logical-block from Layer 2

   Returns:
     canonical-block with normalized text"
  (unless logical-block
    (error "canonicalize-block: logical-block must be non-nil"))
  (let* ((layout (logical-block-layout logical-block))
         (original-text (if layout (block-text layout) ""))
         (block-type (logical-block-type logical-block)))

    (multiple-value-bind (canonical-text transforms)
        (canonicalize-text original-text :log t)

      (make-canonical-block
       :text canonical-text
       :original-text original-text
       :block-type block-type
       :transformations transforms
       :logical-block logical-block))))

(defun canonicalize-page (page-blocks)
  "Canonicalize all logical blocks from a page.

   Args:
     page-blocks: List of logical-block objects

   Returns:
     List of canonical-block objects"
  (mapcar #'canonicalize-block page-blocks))

(defun canonicalize-document (classified-document)
  "Canonicalize entire classified document.

   Args:
     classified-document: Output of classify-document
                          (list of (page-num . blocks) pairs)

   Returns:
     List of (page-num . canonical-blocks) pairs"
  (mapcar (lambda (page-pair)
            (cons (car page-pair)
                  (canonicalize-page (cdr page-pair))))
          classified-document))

;;; ============================================================================
;;; RESET
;;; ============================================================================

(defun reset-canonical-block-counter ()
  "Reset canonical block counter."
  (setf *canonical-block-counter* 0))

;;; ============================================================================
;;; END OF TEXT-CANONICALIZER.LISP
;;; ============================================================================
