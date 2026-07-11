;;;; PDF Adapter - ΦΕΚ Government Gazette Parser
;;;; ΕΛΛΗΝΙΚΗ ΔΗΜΟΚΡΑΤΙΑ - STATE OF THE ART
;;;;
;;;; Full exploitation of Common Lisp:
;;;;   - CLOS hierarchy with MOP
;;;;   - Homoiconicity (code-as-data)
;;;;   - Cross-reference semantic graph
;;;;   - Validation with confidence scoring
;;;;   - Amendment tracking
;;;;
;;;; Document Structure (ΦΕΚ Greek Constitution):
;;;;   ΜΕΡΟΣ (Part)        → "ΜΕΡΟΣ ΠΡΩΤΟ", "ΜΕΡΟΣ ΔΕΥΤΕΡΟ"
;;;;     ΤΜΗΜΑ (Section)   → "ΤΜΗΜΑ Α'" + title on next line
;;;;       ΚΕΦΑΛΑΙΟ (Chapter) → Optional subdivision
;;;;         Άρθρο (Article)  → "Άρθρο 1", "**Άρθρο 5Α"
;;;;           Παράγραφος     → "1.", "2.", "3."
;;;;             Εδάφιο       → "α)", "β)", "γ)"
;;;;
;;;; CRITICAL: Article titles come from ΤΜΗΜΑ header, NOT inline!

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; GLOBAL STATE - Cross-reference graph & Document tree
;;; ============================================================================

(defvar *fek-document* nil "Current document being parsed")
(defvar *cross-reference-graph* nil "Directed graph of article cross-references")
(defvar *amendment-registry* nil "Registry of amendments by law reference")
(defvar *validation-errors* nil "Accumulated validation errors")
(defvar *last-parsed-articles* nil "Raw fek-article instances from last pdf-adapter call, for REPL inspection")

;;; ============================================================================
;;; ΦΕΚ DOCUMENT HIERARCHY - CLOS with Full Slots
;;; ============================================================================

(defclass fek-node ()
  ((id :initarg :id :accessor node-id :type symbol)
   (parent :initarg :parent :accessor node-parent :initform nil)
   (children :initarg :children :accessor node-children :initform nil :type list)
   (source-line :initarg :source-line :accessor node-source-line :initform 0)
   (source-span :initarg :source-span :accessor node-source-span :initform nil
                :documentation "(start-char . end-char)")
   (confidence :initarg :confidence :accessor node-confidence :initform 1.0)
   (metadata :initarg :metadata :accessor node-metadata :initform nil))
  (:documentation "Base class for ΦΕΚ document nodes"))

(defclass fek-document (fek-node)
  ((title :initarg :title :accessor document-title :type string)
   (fek-number :initarg :fek-number :accessor document-fek-number)
   (publication-date :initarg :publication-date :accessor document-date)
   (meri :initarg :meri :accessor document-meri :initform nil :type list))
  (:documentation "Root document node - ΦΕΚ publication"))

(defclass fek-meros (fek-node)
  ((name :initarg :name :accessor meros-name :type string
         :documentation "ΠΡΩΤΟ, ΔΕΥΤΕΡΟ, ΤΡΙΤΟ, ΤΕΤΑΡΤΟ")
   (ordinal :initarg :ordinal :accessor meros-ordinal :type integer)
   (tmimata :initarg :tmimata :accessor meros-tmimata :initform nil))
  (:documentation "ΜΕΡΟΣ - Top-level document part"))

(defclass fek-tmima (fek-node)
  ((letter :initarg :letter :accessor tmima-letter :type string
           :documentation "Α', Β', Γ', Δ', Ε', ΣΤ'")
   (title :initarg :title :accessor tmima-title :initform ""
          :documentation "Section title - SOURCE OF ARTICLE TITLES")
   (kefalia :initarg :kefalia :accessor tmima-kefalia :initform nil)
   (articles :initarg :articles :accessor tmima-articles :initform nil))
  (:documentation "ΤΜΗΜΑ - Section with title"))

(defclass fek-kefalaio (fek-node)
  ((letter :initarg :letter :accessor kefalaio-letter :type string)
   (title :initarg :title :accessor kefalaio-title :initform "")
   (articles :initarg :articles :accessor kefalaio-articles :initform nil))
  (:documentation "ΚΕΦΑΛΑΙΟ - Chapter subdivision"))

(defclass fek-article (fek-node)
  ((number :initarg :number :accessor article-number :type string
           :documentation "1, 2, 5Α, 5Β - string for amendments")
   (numeric :initarg :numeric :accessor article-numeric :type integer
            :documentation "Numeric part only for sorting")
   (suffix :initarg :suffix :accessor article-suffix :initform nil
           :documentation "Α, Β for amended articles")
   (amended-p :initarg :amended-p :accessor article-amended-p :initform nil
              :documentation "T if marked with ** prefix")
   (amendment-info :initarg :amendment-info :accessor article-amendment-info :initform nil
                   :documentation "Plist with :law :fek :date")
   (paragraphs :initarg :paragraphs :accessor article-paragraphs :initform nil)
   (cross-refs :initarg :cross-refs :accessor article-cross-refs :initform nil)
   (interpretive :initarg :interpretive :accessor article-interpretive :initform nil)
   (transitional-p :initarg :transitional-p :accessor article-transitional-p :initform nil
                   :documentation "T if in Μεταβατικές διατάξεις")
   (rubric :initarg :rubric :accessor article-rubric :initform nil
           :documentation "πλαγιότιτλος — the article's marginal heading, promoted to the title")
   (pending-rubric :accessor article-pending-rubric :initform nil
                   :documentation "First-line heading candidate awaiting confirmation by the next line"))
  (:documentation "Άρθρο - Article (title inherited from parent ΤΜΗΜΑ)"))

(defclass fek-paragraph (fek-node)
  ((number :initarg :number :accessor paragraph-number :type integer)
   (text :initarg :text :accessor paragraph-text :initform "")
   (clauses :initarg :clauses :accessor paragraph-clauses :initform nil)
   (cross-refs :initarg :cross-refs :accessor paragraph-cross-refs :initform nil))
  (:documentation "Numbered paragraph within article"))

(defclass fek-clause (fek-node)
  ((marker :initarg :marker :accessor clause-marker :type string
           :documentation "α, β, γ or i, ii, iii")
   (text :initarg :text :accessor clause-text :initform "")
   (sub-clauses :initarg :sub-clauses :accessor clause-sub-clauses :initform nil))
  (:documentation "Clause within paragraph - εδάφιο"))

(defclass fek-interpretive (fek-node)
  ((text :initarg :text :accessor interpretive-text :initform "")
   (applies-to :initarg :applies-to :accessor interpretive-applies-to
               :documentation "Article number this applies to"))
  (:documentation "Ερμηνευτική δήλωση - Interpretive statement"))

;;; ============================================================================
;;; CROSS-REFERENCE STRUCTURE
;;; ============================================================================

(defclass cross-reference ()
  ((source-article :initarg :source-article :accessor xref-source-article)
   (source-paragraph :initarg :source-paragraph :accessor xref-source-paragraph :initform nil)
   (target-article :initarg :target-article :accessor xref-target-article)
   (target-paragraph :initarg :target-paragraph :accessor xref-target-paragraph :initform nil)
   (reference-type :initarg :reference-type :accessor xref-type :initform :citation
                   :documentation ":citation :amendment :exception :condition :delegation")
   (context :initarg :context :accessor xref-context :initform ""
            :documentation "Surrounding text"))
  (:documentation "Cross-reference between legal provisions"))

(defclass amendment-record ()
  ((law-number :initarg :law-number :accessor amendment-law-number)
   (law-year :initarg :law-year :accessor amendment-law-year)
   (fek-reference :initarg :fek-reference :accessor amendment-fek)
   (date :initarg :date :accessor amendment-date)
   (change-type :initarg :change-type :accessor amendment-change-type
                :documentation ":addition :modification :deletion :replacement")
   (affected-articles :initarg :affected-articles :accessor amendment-affected :initform nil))
  (:documentation "Amendment tracking record"))

;;; ============================================================================
;;; ΦΕΚ PATTERNS - Complete regex set
;;; ============================================================================

(defparameter *fek-meros-pattern*
  "^\\s*[MΜ][ΕE][PΡ][OΟ][ΣΣ]\\s+([ΠPΡПPΩΤΟΔΕΥΤΡΙΑO]+)\\s*$"
  "Pattern for ΜΕΡΟΣ header - handles Latin/Greek mixed chars")

(defparameter *fek-tmima-pattern*
  "^\\s*[TΤ][MΜ][HΗ][MΜ][AΑ]\\s+([Α-ΩA-Z]+['ʹ΄'ʼ]?)\\s*$"
  "Pattern for ΤΜΗΜΑ header (title on next line) - handles Latin/Greek and apostrophe variants")

(defparameter *fek-tmima-inline-pattern*
  "^\\s*[TΤ][MΜ][HΗ][MΜ][AΑ]\\s+([Α-ΩA-Z]+['ʹ΄'ʼ]?)\\s+(.+)$"
  "Pattern for ΤΜΗΜΑ with inline title - handles Latin/Greek and apostrophe variants")

(defparameter *fek-kefalaio-pattern*
  "^\\s*ΚΕΦΑΛΑΙΟ\\s+([Α-Ω]+'?)\\s*$"
  "Pattern for ΚΕΦΑΛΑΙΟ header")

(defparameter *fek-kefalaio-inline-pattern*
  "^\\s*ΚΕΦΑΛΑΙΟ\\s+([Α-Ω]+'?)\\s+(.+)$"
  "Pattern for ΚΕΦΑΛΑΙΟ with inline title")

(defparameter *fek-article-pattern*
  "^\\s*(?:\\*\\*)?(?:[Άά]ρθρο[ν]?|ΑΡΘΡΟ[Ν]?)\\s+(\\d+)([Α-ΩA-Z])?\\s*(?:\\*\\*)?(?:\\s*\\.?\\s*[-–—]\\s*.*)?\\s*$"
  "Article header at line start: 'Άρθρο 5', '**Άρθρο 5Α', and the inline-title form
   'Άρθρο 1. - Ποινικά Δικαστήρια.' (number, then an optional '. - <title>'). The
   line-start anchor + required digits keep inline cross-references ('κατά το άρθρο
   489') and repeal ranges ('Άρθρα 3 - 4') from matching as headers.")

(defparameter *fek-paragraph-pattern*
  "^\\s*(?:\\*\\*)?\\s*(\\d+)\\.\\s+(.+)"
  "Pattern for numbered paragraph: optional bold PDF marker (**4. text)")

(defparameter *fek-clause-pattern*
  "^\\s*([α-ωΑ-Ω]|[ivxlcdmIVXLCDM]+)[).]\\s+(.+)"
  "Pattern for clause: lowercase/uppercase Greek (α)/Α)) and Roman numeral (i./I.) markers")

(defparameter *fek-interpretive-pattern*
  "^\\s*Ερμηνευτική\\s+δήλωση"
  "Pattern for interpretive statement: matches standalone line or inline (Ερμηνευτική δήλωση: text)")

(defparameter *fek-transitional-pattern*
  "^\\s*(?:Μεταβατικ[έή]ς\\s+διατάξεις|ΜΕΤΑΒΑΤΙΚ[ΕΗ]Σ\\s+ΔΙΑΤΑΞΕΙΣ)\\s*$"
  "Pattern for transitional provisions: mixed-case and ALL-CAPS ΦΕΚ variant")

(defparameter *fek-cross-ref-pattern*
  "(?:κατ[άα]\\s+τ[οη]ν?|σύμφωνα\\s+με\\s+τ[οη]ν?|βλ\\.?|ως\\s+ορίζ(?:ει|εται)\\s+(?:στο|στην?)|του\\s+άρθρου|το\\s+άρθρο)\\s+(\\d+)(?:\\s*(?:παρ(?:άγραφος|\\.)?|§)\\s*(\\d+))?"
  "Pattern for cross-references")

(defparameter *fek-amendment-pattern*
  "(?:όπως\\s+(?:τροποποιήθηκε|αντικαταστάθηκε|προστέθηκε)|τροποποίηση)\\s+(?:με|από)\\s+(?:το\\s+)?(?:ν\\.?|νόμο)\\s*(\\d+)/(\\d+)"
  "Pattern for amendment references")

(defparameter *fek-repeal-range-pattern*
  "[ΆΑ]ρθρα\\s+(\\d+)([Α-Ω])?\\s*[-–—]\\s*(\\d+)([Α-Ω])?\\s*\\(\\s*[Κκ]αταργ"
  "Repeal of an article RANGE — «Άρθρα 3 - 4 (Καταργούνται)», «Άρθρα 37 – 41
   (Καταργούνται)», «Άρθρα 137Β – 137Δ (Καταργούνται)», «Άρθρα 182 - 182Α
   (Καταργούνται)». Captures BOTH endpoints with an optional Greek-letter suffix
   (g1=n1 g2=s1 g3=n2 g4=s2). The verb may be lower/upper-case and past/present
   («[Κκ]αταργ» covers Καταργούνται/καταργούνται/Καταργήθηκαν…); the dash may be a
   hyphen, en- or em-dash with or without spaces; «(…» may sit on the NEXT line
   (\\s spans the newline). «Άρθρα» (plural, -α) marks a RANGE, never a header.")

(defparameter *fek-repeal-single-pattern*
  "[ΆΑ]ρθρο[ν]?\\s+(\\d+)([Α-Ω])?\\s*\\(\\s*[Κκ]αταργ"
  "Repeal of a SINGLE article — «Άρθρο 43 (Καταργείται)», «Άρθρο 237Β
   (Καταργείται)», «Άρθρο 350 (καταργείται)». «Άρθρο» (singular, -ο) followed
   immediately (only whitespace, incl. a newline) by «([Κκ]αταργ» — so a normal
   header whose body merely mentions a repeal later is not captured.")

(defparameter *greek-suffix-alphabet*
  #("" "Α" "Β" "Γ" "Δ" "Ε" "Ζ" "Η" "Θ" "Ι" "Κ" "Λ" "Μ" "Ν" "Ξ" "Ο" "Π" "Ρ"
    "Σ" "Τ" "Υ" "Φ" "Χ" "Ψ" "Ω")
  "Article-suffix order: the bare article («») precedes Α, then the Greek
   uppercase letters. Used to enumerate lettered repeal ranges (137Β – 137Δ).")

(defparameter *fek-noise-patterns*
  '("ΕΦΗΜΕΡΙ[ΔΣ]Α?\\s+ΤΗΣ\\s+ΚΥΒΕΡΝΗΣΕΩΣ"    ; Anywhere in line
    "^\\s*Τεύχος\\s+[Α-ΩA-Z]"
    "^\\s*ΦΕΚ\\s+[Α-Ω]?\\s*'?\\s*\\d+"
    "^\\s*\\d+\\s*$"
    "^\\s*-\\s*\\d+\\s*-\\s*$"
    "^\\s*[Σσ]ελ[ίι]?[δς]?α?\\.?\\s*\\d+"
    "^\\s*ΠΡΟΕΔΡΟΣ\\s+ΤΗΣ"
    "^\\s*Θεωρήθηκε\\s+και"
    "^\\s*Stavropoulos"                        ; Publisher noise
    "^\\s*Ελληνική\\s+Βουλή\\s*$"              ; Parliament header
    "^\\s*$")
  "Patterns for ΦΕΚ noise removal")

(defparameter *spelled-ordinal-word*
  "ΠΡΩΤΟ|ΔΕΥΤΕΡΟ|ΤΡΙΤΟ|ΤΕΤΑΡΤΟ|ΠΕΜΠΤΟ|ΕΚΤΟ|ΕΒΔΟΜΟ|ΟΓΔΟΟ|ΕΝΑΤΟ|ΔΕΚΑΤΟ|ΕΝΔΕΚΑΤΟ|ΔΩΔΕΚΑΤΟ|ΕΙΚΟΣΤΟ|ΤΡΙΑΚΟΣΤΟ"
  "Alternation of spelled-out neuter Greek ordinals that introduce a structural
   division written BEFORE its noun (ΕΚΤΟ ΚΕΦΑΛΑΙΟ, ΟΓΔΟΟ ΜΕΡΟΣ). Compound
   ordinals (ΔΕΚΑΤΟ ΤΕΤΑΡΤΟ) are two of these in sequence.")

(defparameter *spelled-ordinal-section-pattern*
  (format nil "^\\s*(?:~A)(?:\\s+(?:~A))?\\s+(?:ΚΕΦΑΛΑΙΟ|ΜΕΡΟΣ|ΒΙΒΛΙΟ|ΤΜΗΜΑ|ΤΙΤΛΟΣ)\\b"
          *spelled-ordinal-word* *spelled-ordinal-word*)
  "A line that OPENS with a spelled-out ordinal (optionally compound) followed by
   a structural noun — «ΕΚΤΟ ΚΕΦΑΛΑΙΟ:», «ΟΓΔΟΟ ΚΕΦΑΛΑΙΟ», «ΔΕΚΑΤΟ ΤΕΤΑΡΤΟ
   ΚΕΦΑΛΑΙΟ». The Isokratis source writes chapter banners this way; the inline
   matchers only know the «ΚΕΦΑΛΑΙΟ Α'» form, so without this the banner bled into
   the next article's body. Anchored at line start so the words can never trip a
   match mid-sentence.")

(defun section-header-in-text-p (text)
  "Check if text contains section headers that should be filtered from content"
  (or (cl-ppcre:scan "[MΜ][ΕE][PΡ][OΟ][ΣΣ]\\s+[ΠPΡПPΩΤΟΔΕΥΤΡΙΑO]+" text)
      (cl-ppcre:scan "[TΤ][MΜ][HΗ][MΜ][AΑ]\\s+[Α-ΩA-Z]+['ʹ΄'ʼ]?" text)
      (cl-ppcre:scan "ΚΕΦΑΛΑΙΟ\\s+[Α-Ω]+" text)
      (cl-ppcre:scan *spelled-ordinal-section-pattern* text)))

(defun looks-like-article-header-p (text)
  "Check if text looks like an article header based on STRUCTURE.
   Article headers are: short line ending with a number or number+Greek/Latin suffix (5Α, 5Β)."
  (let ((trimmed (string-trim '(#\Space #\Tab) text)))
    (and (> (length trimmed) 0)
         (< (length trimmed) 30)
         (cl-ppcre:scan "\\d+[Α-ΩA-Z]?\\s*$" trimmed))))

;;; ============================================================================
;;; ORDINAL CONVERSION - Greek numerals
;;; ============================================================================

(defparameter *greek-ordinals*
  '(("ΠΡΩΤΟ" . 1) ("ΔΕΥΤΕΡΟ" . 2) ("ΤΡΙΤΟ" . 3) ("ΤΕΤΑΡΤΟ" . 4)
    ("ΠΕΜΠΤΟ" . 5) ("ΕΚΤΟ" . 6) ("ΕΒΔΟΜΟ" . 7) ("ΟΓΔΟΟ" . 8))
  "Greek ordinal words to numbers")

(defparameter *greek-letters-ordinal*
  '(("Α" . 1) ("Β" . 2) ("Γ" . 3) ("Δ" . 4) ("Ε" . 5) ("ΣΤ" . 6)
    ("Ζ" . 7) ("Η" . 8) ("Θ" . 9) ("Ι" . 10) ("ΙΑ" . 11) ("ΙΒ" . 12))
  "Greek letter ordinals")

(defun greek-ordinal-to-number (text)
  "Convert Greek ordinal to number"
  (let ((clean (string-trim '(#\Space #\' #\') text)))
    (or (cdr (assoc clean *greek-ordinals* :test #'string-equal))
        (cdr (assoc clean *greek-letters-ordinal* :test #'string-equal))
        0)))

;;; ============================================================================
;;; PARSER STATE MACHINE - Extended
;;; ============================================================================

(defstruct fek-parser-state
  "State machine for ΦΕΚ parsing"
  (document nil)
  (current-meros nil)
  (current-tmima nil)
  (current-kefalaio nil)
  (current-article nil)
  (current-paragraph nil)
  (pending-title nil :type (or null keyword))
  (pending-target nil)
  (in-interpretive nil :type boolean)
  (in-transitional nil :type boolean)
  (line-number 0 :type integer)
  (char-offset 0 :type integer)
  (articles nil :type list)
  (cross-refs nil :type list)
  (amendments nil :type list)
  (warnings nil :type list))

(defun make-parser ()
  "Create fresh parser state"
  (make-fek-parser-state
   :document (make-instance 'fek-document :id 'ROOT)))

;;; ============================================================================
;;; TEXT CLEANING
;;; ============================================================================

(defun fek-noise-p (line)
  "Check if line is ΦΕΚ noise"
  (let ((trimmed (string-trim '(#\Space #\Tab #\Return) line)))
    (or (zerop (length trimmed))
        (loop for pattern in *fek-noise-patterns*
              thereis (cl-ppcre:scan pattern trimmed)))))

(defun pre-clean-noise-lines (text)
  "Remove known single-line noise patterns from raw text before hyphenation.
   Noise lines between hyphenated word parts (φυλα-↵[noise]↵κίζεται) must be
   removed first so fix-hyphenation can join them correctly."
  (cl-ppcre:regex-replace-all
   "(?m)^\\s*(?:ΕΦΗΜΕΡΙ[ΔΣ]Α?\\s+ΤΗΣ\\s+ΚΥΒΕΡΝΗΣΕΩΣ|Τεύχος\\s+[Α-ΩA-Z][^\\n]*|ΦΕΚ\\s+[Α-ΩA-Z][^\\n]*|Stavropoulos[^\\n]*|Ελληνική\\s+Βουλή|\\d+)\\s*$"
   text ""))

(defun fix-hyphenation (text)
  "Fix words split across lines with hyphens - Greek-aware"
  (cl-ppcre:regex-replace-all
   "([α-ωά-ώϊϋΐΰΑ-ΩΆ-ΏΪΫ]+)-\\s*\\n\\s*([α-ωά-ώϊϋΐΰ]+)"
   text "\\1\\2"))

(defun normalize-whitespace (text)
  "Normalize whitespace"
  (cl-ppcre:regex-replace-all "[ \\t]+"
    (cl-ppcre:regex-replace-all "\\r" text "") " "))

;; Greek proclitic stems that ELIDE before a vowel and take an apostrophe
;; (γι' απ' κατ' …). Each of these tokens never stands alone in correct Greek
;; WITHOUT elision, so when one appears bare immediately before a vowel-initial
;; lowercase word, the apostrophe was dropped during PDF extraction and can be
;; restored deterministically. (Listed longest-first; all lowercase, so all-caps
;; header text never matches.)
(defparameter *greek-elision-stems*
  '("ανθ" "αντ" "καθ" "κατ" "μετ" "παρ" "αφ" "απ" "εφ" "επ" "υφ" "υπ" "γι" "δι")
  "Proclitic elision stems (deterministic: γι'/απ'/κατ'/… only before a vowel).")

(defparameter *greek-elision-scanner*
  (cl-ppcre:create-scanner
   (format nil "(^|[\\s(])(~{~A~^|~})\\s+([αεηιουωάέήίόύώϊϋΐΰ])"
           *greek-elision-stems*)
   :multi-line-mode t)
  "Matches a bare elision stem before a vowel-initial lowercase word.
   Group 1 = preceding boundary, 2 = stem, 3 = the following vowel.")

(defun restore-greek-elisions (text)
  "Restore elision apostrophes dropped during PDF extraction: a bare proclitic
   stem (γι/απ/κατ/…) immediately before a lowercase vowel-initial word regains
   its apostrophe and is re-joined (γι<newline/space>αυτή → γι' αυτή). Pure,
   deterministic Greek orthography:
     · fires ONLY before a vowel — so non-elided forms (για, κατά, εξ, από …)
       are untouched (their next char is not a separate vowel token);
     · requires a LOWERCASE vowel after — so it never reaches across a structural
       boundary into a Capitalised label/header (e.g. a body ending in a bare
       stem followed by 'Αρθρο:');
     · stems are lowercase — all-caps text never matches."
  (cl-ppcre:regex-replace-all *greek-elision-scanner* text "\\1\\2' \\3"))

;; A detached Greek accent (the spacing tonos/oxia U+0384/U+1FFD or a plain acute
;; U+00B4) that poppler emits just before the vowel it belongs to — e.g.
;; "΄Οποιος" instead of "Όποιος". A standalone accent before a vowel is never
;; valid Greek, so the precomposed accented vowel is the deterministic repair.
(defparameter *greek-accent-map*
  '((#\Α . #\Ά) (#\Ε . #\Έ) (#\Η . #\Ή) (#\Ι . #\Ί) (#\Ο . #\Ό) (#\Υ . #\Ύ) (#\Ω . #\Ώ)
    (#\α . #\ά) (#\ε . #\έ) (#\η . #\ή) (#\ι . #\ί) (#\ο . #\ό) (#\υ . #\ύ) (#\ω . #\ώ))
  "Vowel -> tonos-accented vowel (capitals and lowercase).")

(defparameter *greek-detached-accents*
  (list (code-char #x0384) (code-char #x00B4) (code-char #x1FFD))
  "Spacing accent characters poppler leaves detached before a vowel.")

(defun recombine-greek-accents (text)
  "Recombine a detached Greek accent with the vowel it belongs to:
   <spacing-accent>[space]VOWEL → the precomposed accented vowel
   (΄Οποιος → Όποιος, ΄ ανθρωπος → άνθρωπος). Deterministic; a standalone accent
   before a vowel is never correct Greek, so this never alters valid text."
  (let ((out (make-string-output-stream))
        (n (length text)) (i 0))
    (loop while (< i n) do
      (let ((c (char text i)))
        (cond
          ((and (member c *greek-detached-accents* :test #'char=) (< (1+ i) n))
           ;; optional single space, then a vowel?
           (let* ((j (1+ i))
                  (j (if (and (< j n) (char= (char text j) #\Space)) (1+ j) j))
                  (v (and (< j n) (cdr (assoc (char text j) *greek-accent-map* :test #'char=)))))
             (if v
                 (progn (write-char v out) (setf i (1+ j)))
                 (progn (write-char c out) (incf i)))))
          (t (write-char c out) (incf i)))))
    (get-output-stream-string out)))

(defun strip-dsanet-chrome (text)
  "Remove DSAnet web-print chrome that repeats on every page of a
   print_law_record export and interleaves itself into the flowing text:
     · the print_law_record URL, with any trailing 'page/total' and date that
       belong to that footer (anchored on the URL, so a legal reference like
       'ν. 4619/2019' or a real date inside an article is never touched);
     · the 'ΟΘΟΝΗ ΕΚΤΥΠΩΣΗΣ' (print-screen) header.
   Safe to run on non-DSAnet text (the patterns simply never match)."
  (let ((s text))
    ;; URL + optional trailing  <page>/<total>  and  DD/M/YYYY  (the page footer)
    (setf s (cl-ppcre:regex-replace-all
             "(?:https?://)?www\\.dsanet\\.gr\\S*(?:\\s+\\d+\\s*/\\s*\\d+)?(?:\\s+\\d{1,2}/\\d{1,2}/\\d{2,4})?"
             s " "))
    ;; Any leftover print_law_record fragment
    (setf s (cl-ppcre:regex-replace-all "\\S*print_law_record\\S*" s " "))
    ;; The repeated print-screen header
    (setf s (cl-ppcre:regex-replace-all "ΟΘΟΝΗ\\s+ΕΚΤΥΠΩΣΗΣ" s " "))
    s))

;; Capital-initial Greek words whose accent libpoppler sometimes drops ENTIRELY
;; (Οποιος instead of Όποιος — no detached accent to recombine). This is a
;; STRICT, conservative whitelist: every unaccented form below is never a valid
;; Greek word, and the accent unambiguously falls on the first (capital) vowel,
;; so restoring it can never corrupt correct text. (Ambiguous cases like
;; "Αλλα" = άλλα/αλλά are deliberately excluded.)
(defparameter *greek-capital-accent-fixes*
  '("Οποιος" "Όποιος" "Οποια" "Όποια" "Οποιο" "Όποιο" "Οποιον" "Όποιον"
    "Οποιοι" "Όποιοι" "Οποιες" "Όποιες" "Οποιους" "Όποιους"
    "Οσος" "Όσος" "Οση" "Όση" "Οσο" "Όσο" "Οσοι" "Όσοι" "Οσες" "Όσες"
    "Οσα" "Όσα" "Οσον" "Όσον" "Οσους" "Όσους"
    "Ολος" "Όλος" "Ολη" "Όλη" "Ολο" "Όλο" "Ολοι" "Όλοι" "Ολες" "Όλες"
    "Ολα" "Όλα" "Ολον" "Όλον" "Ολους" "Όλους"
    "Οταν" "Όταν" "Οπου" "Όπου" "Οπως" "Όπως" "Ομως" "Όμως"
    "Οτι" "Ότι" "Οτου" "Ότου"
    "Ηταν" "Ήταν" "Ηδη" "Ήδη" "Ετσι" "Έτσι" "Ωστε" "Ώστε")
  "Flat list of (bad good) capital-initial words with the tonos dropped.")

(defparameter *greek-capital-accent-scanners*
  ;; Greek letter class built from the real Unicode ranges (cl-ppcre has no
  ;; \x{...} syntax) — Greek block U+0370–U+03FF and extended U+1F00–U+1FFF.
  (let ((gl (format nil "[~A-~A~A-~A]"
                    (code-char #x0370) (code-char #x03FF)
                    (code-char #x1F00) (code-char #x1FFF))))
    (loop for (bad good) on *greek-capital-accent-fixes* by #'cddr
          collect (cons (cl-ppcre:create-scanner
                         (format nil "(?<!~A)~A(?!~A)" gl bad gl))
                        good)))
  "Pre-compiled whole-word scanners (no Greek letter on either side).")

(defun restore-common-greek-accents (text)
  "Restore the tonos on a strict whitelist of capital-initial words whose accent
   libpoppler dropped entirely (Όποιος, Όταν, Όλα, Ότι, Ήταν …). Whole-word only;
   every target's unaccented form is never valid Greek, so correct text is safe."
  (let ((s text))
    (dolist (pair *greek-capital-accent-scanners* s)
      (setf s (cl-ppcre:regex-replace-all (car pair) s (cdr pair))))))

(defun strip-isokratis-markers (text)
  "Remove Isokratis editorial annotations that are NOT part of the normative legal
   text. The export's editorial pattern is STRUCTURAL, not a fixed phrase: it
   prepends an attention note and wraps the actual law in ASCII straight quotes —
       ΠΡΟΣΟΧΗ!!! Βλ. σχόλια \"<the law>\"
       προσοχή && \"<the law>\"
   The note and the ASCII-quote WRAPPER are chrome; the law is what's inside. So
   the primary rule unwraps to the quoted text whenever a line OPENS with an
   editorial trigger (προσοχή/ΠΡΟΣΟΧΗ, βλ./Βλ. σχόλια, &&, a leading !) followed by
   a quoted block — case- and accent-insensitive, and never touching a Greek « »
   quotation or an ASCII quote that is NOT preceded by such a trigger (so genuine
   in-text quotes survive). Remaining strips handle the no-wrapper variants:
     · '(βλ. σχόλια)' / bare 'βλ. σχόλια' pointer;
     · the '&&' chaining operator;
     · a line-initial attention bang;
     · runs of *, # or ^ (amendment markers);
     · runs of 3+ orphan single letters (extraction debris)."
  (let ((s text))
    ;; PRIMARY, STRUCTURAL: «<editorial note> \"<law>\"» → «<law>». The trigger must
    ;; be at line start, so a legitimate ASCII quote mid-sentence is never unwrapped.
    (setf s (cl-ppcre:regex-replace-all
             "(?im)^[ \\t]*(?:προσοχ[ήη]|β?λ[έεπ]*\\.?[ \\t]*σχόλια|&&|!)[^\"\\n]*?\"([^\"]*)\""
             s "\\1"))
    ;; "(βλ. σχόλια)" / "(βλέπε σχόλια κατωτέρω)" → drop the pointer (case-insensitive)
    (setf s (cl-ppcre:regex-replace-all "(?i)\\(\\s*βλ[έπε]*\\.?[^)]*σχόλια[^)]*\\)" s ""))
    ;; bare, unparenthesised pointer — «προσοχή && βλ. σχόλια», «Βλ. σχόλια» (no wrapper)
    (setf s (cl-ppcre:regex-replace-all "(?i)(?:προσοχ[ήη]\\s*)?(?:&&\\s*)?βλ[έπε]*\\.?\\s*σχόλια" s ""))
    ;; the '&&' database operator (with any leftover «προσοχή» it chained)
    (setf s (cl-ppcre:regex-replace-all "(?i)(?:προσοχ[ήη]\\s*)?&&+" s " "))
    ;; leading editorial attention bang «! » at the start of a line
    (setf s (cl-ppcre:regex-replace-all "(?m)^\\s*!+\\s+" s ""))
    ;; runs of amendment markers * # ^
    (setf s (cl-ppcre:regex-replace-all "[*#^]+" s ""))
    ;; runs of 3+ space-separated single letters: LETTERSPACED text («κ α τ α ρ
    ;; γ ή θ η κ ε» — emphasis typography whose text layer split per glyph). JOIN
    ;; the letters back into the word they spell — deleting them (the old rule)
    ;; LOST normative text (the ΚΔΔ repeal notices 231-243). Real words rejoin
    ;; correctly; column debris merely stays visible instead of vanishing.
    ;; Confined to a single line so bare letters are never joined across the
    ;; newline that still separates them at this stage of the pipeline.
    (setf s (cl-ppcre:regex-replace-all
             "(?m)(^|[^Α-Ωα-ωΆ-Ώά-ώϊϋΐΰ])([Α-Ωα-ωΆ-Ώά-ώϊϋΐΰ](?:[ \\t]+[Α-Ωα-ωΆ-Ώά-ώϊϋΐΰ]){2,})(?=[ \\t]|$)"
             s
             (lambda (match sep letters)
               (declare (ignore match))
               (concatenate 'string sep
                            (remove-if (lambda (c) (member c '(#\Space #\Tab))) letters)))
             :simple-calls t))
    s))

;;; ============================================================================
;;; ORTHOGRAPHY AUTHORITY — re-homed into orchestrator.orthography
;;; (source/orthography-lexicon.lisp), where the corpus's LEARNED spelling map is
;;; a backend of the greek-nlp LEXICON protocol (composable, queryable). The PDF
;;; parser below consumes it via orchestrator.orthography:learn-orthography and
;;; restore-orthography — behaviour unchanged (the same frequency-majority learner).
;;; ============================================================================

(defparameter *latin->greek-homoglyph*
  '((#\A . #\Α) (#\B . #\Β) (#\E . #\Ε) (#\Z . #\Ζ) (#\H . #\Η) (#\I . #\Ι)
    (#\K . #\Κ) (#\M . #\Μ) (#\N . #\Ν) (#\O . #\Ο) (#\P . #\Ρ) (#\T . #\Τ)
    (#\Y . #\Υ) (#\X . #\Χ) (#\o . #\ο) (#\v . #\ν))
  "Latin capitals (and lowercase o) that ΦΕΚ PDFs emit in place of the visually
   identical Greek letter (Oι, Aν, EYAΓΓΕΛΟΣ, στoν). Applied ONLY inside a token
   that ALSO contains a real Greek-codepoint letter, so pure-Latin tokens — URLs,
   GDPR, English abbreviations — are never touched.")

(defparameter *greek-symbol-homoglyph*
  (list (cons (code-char #x2206) #\Δ)   ; ∆ INCREMENT  → Δ GREEK CAPITAL DELTA
        (cons (code-char #x2126) #\Ω)   ; Ω OHM SIGN   → Ω GREEK CAPITAL OMEGA
        (cons (code-char #x00B5) #\μ))  ; µ MICRO SIGN → μ GREEK SMALL MU
  "Math/technical SYMBOLS a ΦΕΚ PDF emits for the identical Greek letter. Unlike the
   Latin homoglyphs these are not letters — they break tokenisation and the masthead
   («ΕΦΗΜΕΡΙ∆Α») so the noise regex misses it, which then loses body text at the page
   seam where a hyphenated word breaks. They never occur legitimately in Greek legal
   prose, so they are replaced globally (not gated on token context).")

(declaim (inline %greek-letter-p %homoglyph-word-char-p))
(defun %greek-letter-p (ch)
  "True for a real Greek-block letter (monotonic or polytonic)."
  (let ((c (char-code ch)))
    (or (<= #x0370 c #x03FF) (<= #x1F00 c #x1FFF))))

(defun %homoglyph-word-char-p (ch)
  (or (alpha-char-p ch) (%greek-letter-p ch)))

(defun normalize-greek-homoglyphs (text)
  "Repair Greek homoglyphs in two passes:
     1. SYMBOL homoglyphs (∆/Ω/µ → Δ/Ω/μ) globally — these break the masthead noise
        match and cost body text at the seam, and never occur legitimately;
     2. LATIN homoglyphs (Oι → Οι, στoν → στον) only INSIDE a token that already has
        a real Greek letter, so genuine Latin (URLs, GDPR, ν. refs) is preserved."
  (let* ((sym (map 'string (lambda (c) (or (cdr (assoc c *greek-symbol-homoglyph*)) c)) text))
         (out (make-string-output-stream))
         (n (length sym))
         (i 0))
    (loop while (< i n) do
      (let ((ch (char sym i)))
        (if (%homoglyph-word-char-p ch)
            (let ((j i))
              (loop while (and (< j n) (%homoglyph-word-char-p (char sym j))) do (incf j))
              (let* ((token (subseq sym i j))
                     (greekp (some #'%greek-letter-p token)))
                (write-string
                 (if greekp
                     (map 'string (lambda (c)
                                    (or (cdr (assoc c *latin->greek-homoglyph*)) c))
                          token)
                     token)
                 out))
              (setf i j))
            (progn (write-char ch out) (incf i)))))
    (get-output-stream-string out)))

(defun clean-fek-text (text)
  "Full text cleaning pipeline: source-chrome removal → Isokratis editorial
   markers → noise removal → hyphenation → whitespace normalization → Greek
   elision-apostrophe restoration → detached-accent recombination → strict
   whitelist tonos. (Corpus-driven orthography is applied LATER, to article
   bodies/titles only, so it can never rewrite the structural labels such as
   'Κείμενο Αρθρου'.)"
  (restore-common-greek-accents
   (recombine-greek-accents
    (restore-greek-elisions
     (normalize-whitespace
      (fix-hyphenation
       (pre-clean-noise-lines
        (normalize-greek-homoglyphs
         (strip-isokratis-markers (strip-dsanet-chrome text))))))))))

(defun strip-section-headers-from-text (text)
  "Remove section headers that accidentally got into paragraph text.
   Operates per-line (multiline-mode) so patterns cannot eat across sentence boundaries."
  (let ((result text))
    ;; Remove full ΜΕΡΟΣ header lines (Latin/Greek mix handles both cases)
    (setf result (cl-ppcre:regex-replace-all
                  "(?m)^\\s*[MΜ][ΕE][PΡ][OΟ][ΣΣ]\\s+[ΠPΡПPΩΤΟΔΕΥΤΡΙΑO]+[^\\n]*$"
                  result ""))
    ;; Remove full ΤΜΗΜΑ header lines including optional inline title
    (setf result (cl-ppcre:regex-replace-all
                  "(?m)^\\s*[TΤ][MΜ][HΗ][MΜ][AΑ]\\s+[Α-ΩA-Z]+['ʹ΄'ʼ]?[^\\n]*$"
                  result ""))
    ;; Remove spelled-out-ordinal chapter banners — «ΕΚΤΟ ΚΕΦΑΛΑΙΟ: …»,
    ;; «ΔΕΚΑΤΟ ΤΕΤΑΡΤΟ ΚΕΦΑΛΑΙΟ …» — that leaked past the inline matcher.
    (setf result (cl-ppcre:regex-replace-all
                  (format nil "(?m)^\\s*(?:~A)(?:\\s+(?:~A))?\\s+(?:ΚΕΦΑΛΑΙΟ|ΜΕΡΟΣ|ΒΙΒΛΙΟ|ΤΙΤΛΟΣ)\\b[^\\n]*$"
                          *spelled-ordinal-word* *spelled-ordinal-word*)
                  result ""))
    ;; Remove ΕΦΗΜΕΡΙΔΑ noise lines
    (setf result (cl-ppcre:regex-replace-all
                  "(?m)^\\s*ΕΦΗΜΕΡΙ[ΔΣ∆]Α?\\s+ΤΗΣ\\s+ΚΥΒΕΡΝΗΣΕΩΣ[^\\n]*$"
                  result ""))
    ;; Normalize resulting whitespace
    (cl-ppcre:regex-replace-all "\\s{2,}" result " ")))

;;; ============================================================================
;;; PATTERN MATCHING
;;; ============================================================================

(defun match-meros (line)
  "Match ΜΕΡΟΣ, return name or NIL"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings *fek-meros-pattern* line)
    (when match (aref groups 0))))

(defun match-tmima (line)
  "Match ΤΜΗΜΑ, return (letter . title-or-nil)"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings *fek-tmima-inline-pattern* line)
    (if match
        (cons (aref groups 0) (aref groups 1))
        (multiple-value-bind (m2 g2)
            (cl-ppcre:scan-to-strings *fek-tmima-pattern* line)
          (when m2 (cons (aref g2 0) nil))))))

(defun match-kefalaio (line)
  "Match ΚΕΦΑΛΑΙΟ, return (letter . title-or-nil)"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings *fek-kefalaio-inline-pattern* line)
    (if match
        (cons (aref groups 0) (aref groups 1))
        (multiple-value-bind (m2 g2)
            (cl-ppcre:scan-to-strings *fek-kefalaio-pattern* line)
          (when m2 (cons (aref g2 0) nil))))))

(defun match-article (line)
  "Match Άρθρο, return (number suffix amended-p) or NIL"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings *fek-article-pattern* line)
    (when match
      (list (aref groups 0)                              ; number
            (when (> (length groups) 1) (aref groups 1)) ; suffix (Α, Β)
            (cl-ppcre:scan "\\*\\*" line)))))

(defun match-paragraph (line)
  "Match paragraph, return (number . text) or NIL"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings *fek-paragraph-pattern* line)
    (when match
      (cons (parse-integer (aref groups 0)) (aref groups 1)))))

(defun match-clause (line)
  "Match clause, return (marker . text) or NIL"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings *fek-clause-pattern* line)
    (when match
      (cons (aref groups 0) (aref groups 1)))))

(defun match-interpretive (line)
  "Match Ερμηνευτική δήλωση"
  (cl-ppcre:scan *fek-interpretive-pattern* line))

(defun match-transitional (line)
  "Match Μεταβατικές διατάξεις"
  (cl-ppcre:scan *fek-transitional-pattern* line))

;;; ============================================================================
;;; CROSS-REFERENCE EXTRACTION
;;; ============================================================================

(defun extract-cross-references (text source-article &optional source-paragraph)
  "Extract all cross-references from text"
  (let ((refs nil))
    (cl-ppcre:do-register-groups (art-num para-num)
        (*fek-cross-ref-pattern* text)
      (when art-num
        (push (make-instance 'cross-reference
                             :source-article source-article
                             :source-paragraph source-paragraph
                             :target-article (parse-integer art-num)
                             :target-paragraph (when para-num (parse-integer para-num))
                             :reference-type :citation
                             :context (extract-context text art-num))
              refs)))
    (nreverse refs)))

(defun extract-context (text target &optional (window 30))
  "Extract surrounding context for cross-reference"
  (let ((pos (search target text)))
    (when pos
      (subseq text
              (max 0 (- pos window))
              (min (length text) (+ pos (length target) window))))))

(defun extract-amendments (text)
  "Extract amendment references from text"
  (let ((amendments nil))
    (cl-ppcre:do-register-groups (law-num law-year)
        (*fek-amendment-pattern* text)
      (when (and law-num law-year)
        (push (make-instance 'amendment-record
                             :law-number (parse-integer law-num)
                             :law-year (parse-integer law-year)
                             :change-type :modification)
              amendments)))
    (nreverse amendments)))

;;; ============================================================================
;;; STATE MACHINE TRANSITIONS
;;; ============================================================================

(defun finalize-paragraph (state)
  "Save current paragraph"
  (when (and (fek-parser-state-current-paragraph state)
             (fek-parser-state-current-article state))
    ;; Extract cross-refs from paragraph
    (let* ((para (fek-parser-state-current-paragraph state))
           (art (fek-parser-state-current-article state))
           (refs (extract-cross-references
                  (paragraph-text para)
                  (article-numeric art)
                  (paragraph-number para))))
      (setf (paragraph-cross-refs para) refs)
      (setf (article-cross-refs art)
            (append (article-cross-refs art) refs)))
    (push (fek-parser-state-current-paragraph state)
          (article-paragraphs (fek-parser-state-current-article state))))
  (setf (fek-parser-state-current-paragraph state) nil))

(defun %split-sequential-numbered (text)
  "The CORE splitter: if TEXT carries SEQUENTIAL top-level numbering
   (1. … 2. …), return a list of (number . clean-text) with the redundant
   leading numbers removed; else NIL. Only digit numbers split, and only if
   they run 1,2,3,…; nested «…» quotes and lettered sub-items (α. β) γ)) stay
   inside their paragraph."
  (let* ((marked (cl-ppcre:regex-replace-all
                  "(\\.\\s+)(\\d+\\.\\s)" (or text "")
                  (format nil "\\1~C\\2" #\Nul)))
         (chunks (cl-ppcre:split (string #\Nul) marked))
         (paras '()))
    (dolist (c chunks)
      (multiple-value-bind (m g)
          (cl-ppcre:scan-to-strings "^\\s*(\\d+)\\.\\s+(.*)$" c)
        (when m
          (push (cons (parse-integer (aref g 0))
                      (string-trim '(#\Space) (aref g 1)))
                paras))))
    (setf paras (nreverse paras))
    (when (and (>= (length paras) 2)
               (loop for i from 1 for p in paras always (= (car p) i)))
      paras)))

(defun %split-amended-paragraphs (text)
  "If TEXT is one «…» amended block whose body carries sequential top-level
   numbering, split it via %SPLIT-SEQUENTIAL-NUMBERED with the outer guillemet
   wrapper removed. Else NIL. This is the root of the «1. «1. …»
   double-numbering: the source ships an amended article as one guillemet block
   with its paragraph numbers baked into the text."
  (let ((s (string-trim '(#\Space #\Tab #\Newline #\Return) (or text ""))))
    (when (and (>= (length s) 2) (char= (char s 0) #\«))
      (%split-sequential-numbered
       (cl-ppcre:regex-replace "»\\s*\\.?\\s*$" (string-left-trim '(#\« #\Space) s) "")))))

(defun %split-plain-numbered-paragraphs (text)
  "If TEXT is a plain (unwrapped) article body that STARTS at paragraph 1 and
   carries sequential top-level numbering, split it into its real paragraphs —
   so the served content is a true paragraph array (the Constitution's rich
   canonical shape), not one blob. Else NIL."
  (let ((s (string-trim '(#\Space #\Tab #\Newline #\Return) (or text ""))))
    (when (cl-ppcre:scan "^1\\.\\s" s)
      (%split-sequential-numbered s))))

(defun %expand-amended-paragraphs (article paragraphs)
  "Replace any paragraph whose text is a single amended «…» block with sequential
   internal numbering by its constituent, cleanly-numbered paragraphs. Other
   paragraphs pass through untouched."
  (let ((out '()))
    (dolist (p paragraphs (nreverse out))
      (let ((split (%split-amended-paragraphs (paragraph-text p))))
        (if split
            (dolist (np split)
              (push (make-instance 'fek-paragraph
                                   :number (car np) :text (cdr np)
                                   :source-line (node-source-line p)
                                   :id (intern (format nil "PARA-~D" (car np)))
                                   :parent article)
                    out))
            (push p out))))))

(defun finalize-article (state)
  "Save current article"
  ;; A held heading candidate that was the article's ONLY line was never a
  ;; heading — it is the article's (short) body. Restore it as body content.
  (let ((art (fek-parser-state-current-article state)))
    (when (and art (article-pending-rubric art)
               (null (fek-parser-state-current-paragraph state))
               (null (article-paragraphs art)))
      (setf (fek-parser-state-current-paragraph state)
            (make-instance 'fek-paragraph :number 0
                           :text (article-pending-rubric art)
                           :source-line (node-source-line art)
                           :id 'PARA-0 :parent art))
      (setf (article-pending-rubric art) nil)))
  (finalize-paragraph state)
  (when (fek-parser-state-current-article state)
    (let ((article (fek-parser-state-current-article state)))
      ;; Reverse paragraphs
      (setf (article-paragraphs article)
            (nreverse (article-paragraphs article)))
      ;; Split a single amended «…» block that carries internal sequential numbering
      ;; into its real paragraphs (root fix for the «1. «1. …» double-numbering —
      ;; the source bakes paragraph numbers into one guillemet-wrapped block).
      (setf (article-paragraphs article)
            (%expand-amended-paragraphs article (article-paragraphs article)))
      ;; Compute confidence
      (setf (node-confidence article)
            (compute-article-confidence article))
      ;; Add to list
      (push article (fek-parser-state-articles state))
      ;; Add cross-refs to global graph
      (dolist (ref (article-cross-refs article))
        (push ref (fek-parser-state-cross-refs state)))))
  (setf (fek-parser-state-current-article state) nil)
  (setf (fek-parser-state-in-interpretive state) nil))

(defun process-meros (state name line-num)
  "Process ΜΕΡΟΣ"
  (finalize-article state)
  (let ((meros (make-instance 'fek-meros
                              :name name
                              :ordinal (greek-ordinal-to-number name)
                              :source-line line-num
                              :id (intern (format nil "MEROS-~A" name)))))
    (setf (fek-parser-state-current-meros state) meros)
    (setf (fek-parser-state-current-tmima state) nil)
    (setf (fek-parser-state-current-kefalaio state) nil)
    (push meros (document-meri (fek-parser-state-document state)))))

(defun process-tmima (state letter title line-num)
  "Process ΤΜΗΜΑ"
  (finalize-article state)
  (log:debug () "ΤΜΗΜΑ: letter=~A title=~A line=~D" letter title line-num)
  (let ((tmima (make-instance 'fek-tmima
                              :letter letter
                              :title (or title "")
                              :source-line line-num
                              :id (intern (format nil "TMIMA-~A" letter))
                              :parent (fek-parser-state-current-meros state))))
    (setf (fek-parser-state-current-tmima state) tmima)
    (setf (fek-parser-state-current-kefalaio state) nil)
    (when (null title)
      (log:debug () "Setting pending-title for ΤΜΗΜΑ ~A" letter)
      (setf (fek-parser-state-pending-title state) :tmima)
      (setf (fek-parser-state-pending-target state) tmima))
    (when (fek-parser-state-current-meros state)
      (push tmima (meros-tmimata (fek-parser-state-current-meros state))))))

(defun process-kefalaio (state letter title line-num)
  "Process ΚΕΦΑΛΑΙΟ"
  (finalize-article state)
  (let ((kef (make-instance 'fek-kefalaio
                            :letter letter
                            :title (or title "")
                            :source-line line-num
                            :id (intern (format nil "KEF-~A" letter))
                            :parent (or (fek-parser-state-current-tmima state)
                                       (fek-parser-state-current-meros state)))))
    (setf (fek-parser-state-current-kefalaio state) kef)
    (when (null title)
      (setf (fek-parser-state-pending-title state) :kefalaio)
      (setf (fek-parser-state-pending-target state) kef))
    (when (fek-parser-state-current-tmima state)
      (push kef (tmima-kefalia (fek-parser-state-current-tmima state))))))

(defun process-article (state number suffix amended-p line-num)
  "Process Άρθρο"
  (finalize-article state)
  ;; Clear pending title - article header means no title line came
  (setf (fek-parser-state-pending-title state) nil)
  (setf (fek-parser-state-pending-target state) nil)
  (let* ((full-num (if suffix (format nil "~A~A" number suffix) number))
         (parent (or (fek-parser-state-current-kefalaio state)
                     (fek-parser-state-current-tmima state)))
         (parent-title (when parent
                        (typecase parent
                          (fek-tmima (tmima-title parent))
                          (fek-kefalaio (kefalaio-title parent))
                          (t nil))))
         (article (make-instance 'fek-article
                                 :number full-num
                                 :numeric (parse-integer number)
                                 :suffix suffix
                                 :amended-p amended-p
                                 :transitional-p (fek-parser-state-in-transitional state)
                                 :source-line line-num
                                 :id (intern (format nil "ARTICLE-~A" full-num))
                                 :parent parent)))
    (format *error-output* "~%>>> ARTICLE ~A: parent=~A parent-title=\"~A\"~%"
            full-num
            (when parent (typecase parent (fek-tmima (tmima-letter parent)) (fek-kefalaio (kefalaio-letter parent))))
            (or parent-title "NIL"))
    (setf (fek-parser-state-current-article state) article)))

(defun process-paragraph (state number text line-num)
  "Process paragraph"
  (finalize-paragraph state)
  ;; A numbered paragraph confirms any held heading candidate as the rubric.
  (let ((art (fek-parser-state-current-article state)))
    (when (and art (article-pending-rubric art))
      (setf (article-rubric art) (article-pending-rubric art)
            (article-pending-rubric art) nil)))
  (when (fek-parser-state-current-article state)
    (let ((para (make-instance 'fek-paragraph
                               :number number
                               :text text
                               :source-line line-num
                               :id (intern (format nil "PARA-~D" number))
                               :parent (fek-parser-state-current-article state))))
      (setf (fek-parser-state-current-paragraph state) para))))

(defun process-clause (state marker text line-num)
  "Process clause within paragraph"
  (when (fek-parser-state-current-paragraph state)
    (let ((clause (make-instance 'fek-clause
                                 :marker marker
                                 :text text
                                 :source-line line-num
                                 :id (intern (format nil "CLAUSE-~A" marker))
                                 :parent (fek-parser-state-current-paragraph state))))
      (push clause (paragraph-clauses (fek-parser-state-current-paragraph state))))))

(defun process-interpretive (state line-num)
  "Process Ερμηνευτική δήλωση header"
  (declare (ignore line-num))
  (finalize-paragraph state)
  (setf (fek-parser-state-in-interpretive state) t))

(defun process-transitional (state line-num)
  "Process Μεταβατικές διατάξεις section"
  (declare (ignore line-num))
  (setf (fek-parser-state-in-transitional state) t))

(defun %char-upper-letter-p (ch)
  "T if CH is an uppercase Greek (incl. accented) or Latin letter."
  (let ((c (char-code ch)))
    (or (<= #x41 c #x5A)                         ; A-Z (Latin homoglyphs)
        (= c #x0386) (<= #x0388 c #x038A)        ; Ά Έ Ή Ί
        (= c #x038C) (= c #x038E) (= c #x038F)   ; Ό Ύ Ώ
        (<= #x0391 c #x03A1)                     ; Α-Ρ
        (<= #x03A3 c #x03AB))))                  ; Σ-Ϋ

(defun %char-lower-letter-p (ch)
  "T if CH is a lowercase Greek (incl. accented, final sigma) or Latin letter."
  (let ((c (char-code ch)))
    (or (<= #x61 c #x7A)                         ; a-z
        (= c #x0390)                             ; ΐ
        (<= #x03AC c #x03CE))))                  ; ά-ώ (incl. ς U+03C2)

(defun %lower-start-p (s)
  "T if the first non-space character of S is lowercase — i.e. a continuation
   of the previous line rather than the start of a fresh sentence."
  (let ((s (string-left-trim '(#\Space #\Tab #\Return) s)))
    (and (plusp (length s)) (%char-lower-letter-p (char s 0)))))

(defun %looks-like-rubric-p (s)
  "T if S is a short, heading-shaped line — the article's πλαγιότιτλος — rather
   than a sentence of body text. Deliberately conservative: a false positive
   would fabricate an article title out of real legal text."
  (let ((s (string-trim '(#\Space #\Tab #\Return) s)))
    (and (<= 2 (length s) 70)
         (%char-upper-letter-p (char s 0))
         (let ((last (char s (1- (length s)))))
           (not (member last '(#\. #\: #\; #\, #\·)))))))

(defun %strip-leading-rubric-echo (rubric text)
  "If TEXT opens by repeating RUBRIC verbatim — the Isokratis export sometimes
   prints the πλαγιότιτλος both as the heading line AND again at the head of the
   body — drop that leading echo together with a trailing separator, so the rubric
   is never duplicated. Exact, case-insensitive PREFIX only: text that merely
   shares an opening word is untouched."
  (let* ((rt (string-trim '(#\Space #\Tab #\Return) rubric))
         (tt (string-left-trim '(#\Space #\Tab #\Return) text))
         (rl (length rt)))
    (if (and (plusp rl)
             (>= (length tt) rl)
             (string-equal rt (subseq tt 0 rl)))
        (string-left-trim '(#\Space #\Tab #\Return #\. #\· #\: #\; #\,)
                          (subseq tt rl))
        text)))

(defun process-content (state line)
  "Process content line - filters section headers from content"
  (let ((trimmed (string-trim '(#\Space #\Tab #\Return) line)))
    ;; Skip if line contains section headers (ΜΕΡΟΣ, ΤΜΗΜΑ, ΚΕΦΑΛΑΙΟ)
    (when (section-header-in-text-p trimmed)
      (log:debug () "Skipping section header in content: ~A" trimmed)
      (return-from process-content nil))

    (cond
      ;; Pending title for ΤΜΗΜΑ or ΚΕΦΑΛΑΙΟ
      ;; Only accept if it's NOT an article header (lenient check)
      ((and (fek-parser-state-pending-title state)
            (fek-parser-state-pending-target state)
            (not (looks-like-article-header-p trimmed)))
       (log:debug () "Capturing pending title: ~A" trimmed)
       (let ((target (fek-parser-state-pending-target state)))
         (typecase target
           (fek-tmima
            (setf (tmima-title target) trimmed)
            (log:debug () "Set ΤΜΗΜΑ title: ~A" trimmed))
           (fek-kefalaio (setf (kefalaio-title target) trimmed))))
       (setf (fek-parser-state-pending-title state) nil)
       (setf (fek-parser-state-pending-target state) nil))

      ;; Interpretive statement content
      ((fek-parser-state-in-interpretive state)
       (when (fek-parser-state-current-article state)
         (let ((current (article-interpretive
                         (fek-parser-state-current-article state))))
           (setf (article-interpretive
                  (fek-parser-state-current-article state))
                 (if current
                     (concatenate 'string current " " trimmed)
                     trimmed)))))

      ;; Clause within paragraph
      ((and (fek-parser-state-current-paragraph state)
            (match-clause trimmed))
       (let ((result (match-clause trimmed)))
         (process-clause state (car result) (cdr result)
                         (fek-parser-state-line-number state))))

      ;; Continue paragraph
      ((fek-parser-state-current-paragraph state)
       (setf (paragraph-text (fek-parser-state-current-paragraph state))
             (concatenate 'string
                          (paragraph-text (fek-parser-state-current-paragraph state))
                          " " trimmed)))

      ;; Unnumbered content before first paragraph — this is where an article's
      ;; πλαγιότιτλος (marginal heading) sits. Capture it as the article RUBRIC
      ;; (which becomes the title, exactly as the Isokratis path does) instead of
      ;; fusing it into the body. Confirmation is deferred one line: only if a
      ;; fresh sentence (or a numbered paragraph) follows is the held line a
      ;; heading — a lowercase continuation means it was wrapped body text.
      ((fek-parser-state-current-article state)
       (let ((art (fek-parser-state-current-article state)))
         (flet ((start-para0 (txt)
                  (setf (fek-parser-state-current-paragraph state)
                        (make-instance 'fek-paragraph :number 0 :text txt
                                       :source-line (fek-parser-state-line-number state)
                                       :id 'PARA-0 :parent art))))
           (cond
             ;; (A) very first line after the header, heading-shaped → hold it
             ((and (null (article-rubric art))
                   (null (article-pending-rubric art))
                   (null (article-paragraphs art))
                   (null (fek-parser-state-current-paragraph state))
                   (%looks-like-rubric-p trimmed))
              (setf (article-pending-rubric art) trimmed))
             ;; (B) a held candidate is decided by THIS line
             ((article-pending-rubric art)
              (let ((pend (article-pending-rubric art)))
                (setf (article-pending-rubric art) nil)
                (if (%lower-start-p trimmed)
                    ;; lowercase → the held line was really body; restore the fusion
                    (start-para0 (concatenate 'string pend " " trimmed))
                    ;; fresh sentence → the held line was the rubric. Drop a verbatim
                    ;; echo of it at the head of the body so it is never duplicated.
                    (progn (setf (article-rubric art) pend)
                           (let ((body (%strip-leading-rubric-echo pend trimmed)))
                             (when (plusp (length (string-trim '(#\Space #\Tab #\Return) body)))
                               (start-para0 body)))))))
             ;; (C) ordinary unnumbered body
             (t (start-para0 trimmed)))))))))

;;; ============================================================================
;;; VALIDATION & CONFIDENCE
;;; ============================================================================

(defun compute-article-confidence (article)
  "Compute confidence score for extracted article"
  (let ((score 1.0))
    ;; Penalty for no paragraphs
    (when (null (article-paragraphs article))
      (decf score 0.3))
    ;; Penalty for very short content
    (let ((total-text (format nil "~{~A~}"
                              (mapcar #'paragraph-text
                                      (article-paragraphs article)))))
      (when (< (length total-text) 50)
        (decf score 0.2))
      ;; Penalty for OCR artifacts
      (when (cl-ppcre:scan "[□■◊�]" total-text)
        (decf score 0.15)))
    ;; Bonus for cross-references (indicates coherent legal text)
    (when (article-cross-refs article)
      (incf score 0.05))
    ;; Ensure bounds
    (max 0.1 (min 1.0 score))))

(defun validate-article-sequence (articles)
  "Validate sequential numbering, return gaps"
  (let ((gaps nil)
        (prev-num 0))
    (dolist (art (sort (copy-list articles) #'< :key #'article-numeric))
      (let ((num (article-numeric art)))
        (when (and (> num (1+ prev-num)) (> prev-num 0))
          (push (cons prev-num num) gaps))
        (setf prev-num num)))
    (nreverse gaps)))

(defun validate-cross-references (articles cross-refs)
  "Validate all cross-references point to existing articles"
  (let ((article-nums (mapcar #'article-numeric articles))
        (invalid nil))
    (dolist (ref cross-refs)
      (unless (member (xref-target-article ref) article-nums)
        (push ref invalid)))
    (nreverse invalid)))

;;; ============================================================================
;;; REPEALED-ARTICLE SYNTHESIS  — a complete sequence, no false gaps
;;; ============================================================================
;;; When a code repeals articles, the ΦΕΚ does not reprint them as headers; it
;;; states the range once: «Άρθρα 3 - 4 \n (Καταργούνται)». A naive parser then
;;; sees a GAP (2 → 5) and the audit flags it as suspect. We codify FAITHFULLY:
;;; the articles ARE repealed, so we materialise them as explicit stubs carrying
;;; a single «Καταργήθηκε.» paragraph. The numbering is then continuous and the
;;; repeal is recorded exactly as the legislator wrote it — not judged, not hidden.

(defun %article-num< (a b)
  "Order articles by numeric id, then by suffix (5 < 5Α < 5Β)."
  (let ((na (article-numeric a)) (nb (article-numeric b)))
    (if (= na nb)
        (string< (or (article-suffix a) "") (or (article-suffix b) ""))
        (< na nb))))

(defun %make-repealed-article (numeric &optional suffix)
  "Build a repealed-article stub: real number, single «Καταργήθηκε.» paragraph,
   no parent (title resolves empty). Marked via node-metadata :repealed t."
  (let* ((full-num (if (and suffix (plusp (length suffix)))
                       (format nil "~D~A" numeric suffix)
                       (format nil "~D" numeric)))
         (art (make-instance 'fek-article
                             :number full-num
                             :numeric numeric
                             :suffix (when (and suffix (plusp (length suffix))) suffix)
                             :amended-p nil
                             :source-line 0
                             :id (intern (format nil "ARTICLE-~A" full-num))
                             :parent nil))
         (para (make-instance 'fek-paragraph
                              :number 0
                              :text "Καταργήθηκε."
                              :source-line 0
                              :id (intern (format nil "PARA-REPEALED-~A" full-num))
                              :parent art)))
    (setf (article-paragraphs art) (list para))
    (setf (node-metadata art) (list :repealed t))
    (setf (node-confidence art) 1.0)
    art))

(defun %suffix-index (s)
  "Position of suffix S in *greek-suffix-alphabet* (NIL/«» → 0, the bare article)."
  (or (position (or s "") *greek-suffix-alphabet* :test #'string=) 0))

(defun %enumerate-repeal-range (n1 s1 n2 s2)
  "List of (numeric . suffix) covered by «Άρθρα n1[s1] – n2[s2]». Same base number
   walks the suffix alphabet (137Β..137Δ → 137Β,137Γ,137Δ; 182..182Α → 182,182Α);
   different bases enumerate the plain integers in between, keeping the lettered
   endpoints exactly (322Α..323 → 322Α,323 — no invented 322)."
  (let ((s1 (or s1 "")) (s2 (or s2 "")) (acc nil))
    (cond
      ((= n1 n2)
       (loop for i from (%suffix-index s1) to (%suffix-index s2)
             do (push (cons n1 (aref *greek-suffix-alphabet* i)) acc)))
      ((< n1 n2)
       (loop for n from n1 to n2
             do (cond ((= n n1) (push (cons n1 s1) acc))
                      ((= n n2) (push (cons n2 s2) acc))
                      (t        (push (cons n "")  acc))))))
    (nreverse acc)))

(defun %article-bare-repeal-p (art)
  "T if ART carries no real body — empty, or only a «(καταργ…)» repeal notice — so
   it can be safely normalised to the «Καταργήθηκε.» repealed form. This catches a
   single repeal whose «Άρθρο N» line WAS a parseable header (so the article is
   present) but whose only content is the repeal notice itself (e.g. «Άρθρο 274 /
   (καταργείται)»)."
  (let ((txt (string-trim '(#\Space #\Tab #\Newline #\Return #\( #\) #\. #\,)
                          (format nil "~{~A~^ ~}"
                                  (loop for p in (article-paragraphs art)
                                        collect (paragraph-text p))))))
    (or (< (length txt) 3)
        (and (<= (length txt) 24)
             (cl-ppcre:scan "(?i)καταργ" txt)))))

(defun %normalize-to-repealed (art)
  "Rewrite a present-but-bare repealed ART into the canonical «Καταργήθηκε.» form,
   so every repealed article reads the same whether it came from a range or a
   present single."
  (setf (article-paragraphs art)
        (list (make-instance 'fek-paragraph
                             :number 0 :text "Καταργήθηκε."
                             :source-line (node-source-line art)
                             :id (intern (format nil "PARA-REPEALED-~A" (article-number art)))
                             :parent art)))
  (setf (node-metadata art) (list* :repealed t (node-metadata art)))
  art)

(defun synthesize-repealed-articles (text articles)
  "Scan TEXT for repeal markers and complete the article sequence faithfully:
   a covered number not yet present becomes a «Καταργήθηκε.» stub; a number that
   IS present but whose «Άρθρο N» header has only a bare «(καταργ…)» body is
   normalised to the same repealed form. A present article with a REAL body is
   left untouched (we record, we do not judge). Returns the merged list sorted by
   numeric (then suffix)."
  (let ((present (make-hash-table :test 'equal))
        (repealed nil)
        (extra nil))
    (dolist (a articles)
      (setf (gethash (article-number a) present) a))
    (flet ((note (numeric suffix)
             (push (cons numeric (when (and suffix (plusp (length suffix))) suffix))
                   repealed)))
      ;; Collect every repealed (numeric . suffix) the gazette declares.
      ;; Ranges: «Άρθρα X[s] - Y[s] (Καταργούνται)»
      (cl-ppcre:do-register-groups (n1 s1 n2 s2) (*fek-repeal-range-pattern* text)
        (let ((a (parse-integer n1)) (b (parse-integer n2)))
          (when (and (<= a b) (< (- b a) 1000))   ; sanity bound
            (dolist (cell (%enumerate-repeal-range a s1 b s2))
              (note (car cell) (cdr cell))))))
      ;; Singles: «Άρθρο X[s] (Καταργείται)»
      (cl-ppcre:do-register-groups (num suffix) (*fek-repeal-single-pattern* text)
        (note (parse-integer num) suffix)))
    ;; Apply: stub if missing, normalise if present-but-bare, else leave alone.
    (dolist (cell (nreverse repealed))
      (let* ((numeric (car cell)) (suf (cdr cell))
             (key (if suf (format nil "~D~A" numeric suf) (format nil "~D" numeric)))
             (exist (gethash key present)))
        (cond
          ((null exist)
           (let ((stub (%make-repealed-article numeric suf)))
             (setf (gethash key present) stub)
             (push stub extra)))
          ((%article-bare-repeal-p exist) (%normalize-to-repealed exist)))))
    (if extra
        (sort (append articles extra) #'%article-num<)
        articles)))

;;; ============================================================================
;;; MAIN PARSER
;;; ============================================================================

(defun parse-fek-text (text)
  "Parse ΦΕΚ text into structured hierarchy"
  (let ((state (make-parser))
        (lines (uiop:split-string text :separator '(#\Newline))))

    (loop for line in lines
          for line-num from 1
          for trimmed = (string-trim '(#\Space #\Tab #\Return) line)
          do (setf (fek-parser-state-line-number state) line-num)
             (cond
               ((fek-noise-p trimmed) nil)

               ((match-meros trimmed)
                (process-meros state (match-meros trimmed) line-num))

               ((match-tmima trimmed)
                (let ((r (match-tmima trimmed)))
                  (process-tmima state (car r) (cdr r) line-num)))

               ((match-kefalaio trimmed)
                (let ((r (match-kefalaio trimmed)))
                  (process-kefalaio state (car r) (cdr r) line-num)))

               ((match-transitional trimmed)
                (process-transitional state line-num))

               ((match-article trimmed)
                (let ((r (match-article trimmed)))
                  (process-article state (first r) (second r) (third r) line-num)))

               ((match-interpretive trimmed)
                (process-interpretive state line-num)
                ;; Capture inline content after "Ερμηνευτική δήλωση: ..."
                (let ((colon-pos (position #\: trimmed)))
                  (when (and colon-pos (fek-parser-state-current-article state))
                    (let ((inline (string-trim '(#\Space #\Tab)
                                               (subseq trimmed (1+ colon-pos)))))
                      (when (> (length inline) 0)
                        (setf (article-interpretive
                               (fek-parser-state-current-article state))
                              inline))))))

               ((and (fek-parser-state-current-article state)
                     (match-paragraph trimmed))
                (let ((r (match-paragraph trimmed)))
                  (process-paragraph state (car r) (cdr r) line-num)))

               ((> (length trimmed) 0)
                (process-content state trimmed))))

    ;; Finalize
    (finalize-article state)

    ;; Set globals
    (setf *fek-document* (fek-parser-state-document state))
    (setf *cross-reference-graph* (fek-parser-state-cross-refs state))

    ;; Return articles — completed with repealed-article stubs so the sequence
    ;; has no false gaps («Άρθρα X - Y (Καταργούνται)» becomes explicit entries).
    (synthesize-repealed-articles
     text (nreverse (fek-parser-state-articles state)))))

;;; ============================================================================
;;; HOMOICONIC REPRESENTATION - Code as Data
;;; ============================================================================

(defun article-to-sexp (article)
  "Convert article to S-expression - HOMOICONICITY"
  `(article
    :id ,(node-id article)
    :number ,(article-number article)
    :numeric ,(article-numeric article)
    :amended ,(article-amended-p article)
    :transitional ,(article-transitional-p article)
    :confidence ,(node-confidence article)
    :tmima ,(when (and (node-parent article)
                       (typep (node-parent article) 'fek-tmima))
              (tmima-letter (node-parent article)))
    :title ,(resolve-article-title article)
    :paragraphs ,(mapcar #'paragraph-to-sexp (article-paragraphs article))
    :cross-refs ,(mapcar #'xref-to-sexp (article-cross-refs article))
    :interpretive ,(article-interpretive article)))

(defun paragraph-to-sexp (para)
  "Convert paragraph to S-expression"
  `(paragraph
    :number ,(paragraph-number para)
    :text ,(paragraph-text para)
    :clauses ,(mapcar #'clause-to-sexp (paragraph-clauses para))
    :cross-refs ,(length (paragraph-cross-refs para))))

(defun clause-to-sexp (clause)
  "Convert clause to S-expression"
  `(clause :marker ,(clause-marker clause) :text ,(clause-text clause)))

(defun xref-to-sexp (xref)
  "Convert cross-reference to S-expression"
  `(xref :from ,(xref-source-article xref)
         :to ,(xref-target-article xref)
         :type ,(xref-type xref)))

(defun document-to-sexp ()
  "Export entire document as S-expression"
  (when *fek-document*
    `(fek-document
      :meri ,(loop for meros in (document-meri *fek-document*)
                   collect `(meros :name ,(meros-name meros)
                                   :ordinal ,(meros-ordinal meros)))
      :cross-ref-count ,(length *cross-reference-graph*))))

;;; ============================================================================
;;; ARTICLE TITLE RESOLUTION
;;; ============================================================================

(defun resolve-article-title (article)
  "Resolve the article title: an explicit Isokratis 'Τίτλος Αρθρου' (carried in
   node-metadata) wins; otherwise inherit from the parent ΤΜΗΜΑ / ΚΕΦΑΛΑΙΟ."
  (let ((explicit (and (node-metadata article)
                       (getf (node-metadata article) :title)))
        (rubric (article-rubric article)))
    (cond
      ;; explicit Isokratis 'Τίτλος Αρθρου'
      ((and explicit (plusp (length explicit))) explicit)
      ;; πλαγιότιτλος captured from the ΦΕΚ body — the per-article heading
      ((and rubric (plusp (length rubric))) rubric)
      ;; otherwise inherit from the parent section
      (t (let ((parent (node-parent article)))
           (typecase parent
             (fek-kefalaio
              (or (kefalaio-title parent)
                  (when (node-parent parent)
                    (tmima-title (node-parent parent)))
                  ""))
             (fek-tmima (or (tmima-title parent) ""))
             (t "")))))))

;;; ============================================================================
;;; IIR CONVERSION
;;; ============================================================================

(defun article-to-iir (article source-path)
  "Convert to normalized-article-input with full metadata"
  (let* ((title (resolve-article-title article))
         (article-num (article-number article))
         (formatted-title (if (and title (> (length title) 0))
                              (format nil "Άρθρο ~A - ~A" article-num title)
                              (format nil "Άρθρο ~A" article-num)))
         (content (strip-section-headers-from-text
                   (format nil "~{~A~^~%~}"
                           (loop for para in (article-paragraphs article)
                                 collect (format nil "~@[~D. ~]~A"
                                                 (unless (zerop (paragraph-number para))
                                                   (paragraph-number para))
                                                 (paragraph-text para)))))))

    (orchestrator.model:make-normalized-article-input
     :article-number (article-numeric article)
     :article-label (let ((suffix (article-suffix article)))
                      (if (and suffix (plusp (length suffix)))
                          (format nil "~D~A" (article-numeric article) suffix)
                          (format nil "~D" (article-numeric article))))
     :article-title formatted-title
     :article-content content
     :source-type :pdf
     :source-path source-path
     :extraction-confidence (node-confidence article)
     :source-metadata (list* :extractor "pdf-state-machine"
                            ;; per-article version date, when the source records it —
                            ;; the substrate of tempus regit actum matching
                            (append
                             (let ((d (getf (node-metadata article) :last-modified)))
                               (when d (list :last-modified d)))
                             (list
                            :trace-id (format nil "fek-art-~A-~A"
                                              (article-numeric article)
                                              (node-source-line article))
                            :article-id (article-number article)
                            :amended (article-amended-p article)
                            :suffix (article-suffix article)
                            :transitional (article-transitional-p article)
                            :tmima (when (typep (node-parent article) 'fek-tmima)
                                    (tmima-letter (node-parent article)))
                            :kefalaio (when (typep (node-parent article) 'fek-kefalaio)
                                       (kefalaio-letter (node-parent article)))
                            :paragraphs (length (article-paragraphs article))
                            :clauses (reduce #'+ (article-paragraphs article)
                                            :key (lambda (p) (length (paragraph-clauses p)))
                                            :initial-value 0)
                            :cross-refs (length (article-cross-refs article))
                            :interpretive (article-interpretive article)
                            :sexp (article-to-sexp article)))))))

;;; ============================================================================
;;; MAIN ENTRY POINT
;;; ============================================================================

;;; ============================================================================
;;; CODIFICATION VALIDATION GATE  — the correctness guarantee
;;; ============================================================================
;;;
;;; Whatever the PDF style, the parse must be SELF-CONSISTENT before anything is
;;; published. This gate detects exactly the failures SHACL cannot: duplicate
;;; article numbers, numeric collisions (lettered articles 187Α colliding with
;;; the base 187 — silent data loss), sequence gaps, and a count that disagrees
;;; with the expected total. It does not fix; it REPORTS, so an uncertain parse
;;; is flagged for review instead of published as authoritative law.

(defun validate-codification (articles &key expected-count)
  "Return (values ok-p report). REPORT is a plist describing the parse's
   integrity; OK-P is true only when there are no duplicates, no sequence gaps,
   no numeric collisions, and (when EXPECTED-COUNT is given) the unique count
   matches it."
  (let* ((numbers (mapcar #'article-number articles))
         (uniq (remove-duplicates numbers :test #'equal))
         (dups (let ((h (make-hash-table :test 'equal)) (d '()))
                 (dolist (n numbers) (incf (gethash n h 0)))
                 (maphash (lambda (k v) (when (> v 1) (push k d))) h)
                 (sort d #'string<)))
         (collisions (let ((h (make-hash-table)) (c '()))
                       (dolist (a articles)
                         (pushnew (article-number a) (gethash (article-numeric a) h)
                                  :test #'equal))
                       (maphash (lambda (k v) (when (> (length v) 1)
                                                (push (cons k (sort (copy-list v) #'string<)) c)))
                                h)
                       (sort c #'< :key #'car)))
         (sorted (sort (remove-duplicates (mapcar #'article-numeric articles)) #'<))
         (gaps (loop for (a b) on sorted when (and b (> b (1+ a))) collect (cons a b)))
         (lettered (sort (remove-if-not #'article-suffix (copy-list articles))
                         #'< :key #'article-numeric))
         ;; For each true duplicate, where it occurs (source line) and a snippet
         ;; of each occurrence's body — so the cause can be seen, not guessed.
         (dup-details
          (loop for d in dups
                collect (cons d
                              (loop for a in articles
                                    when (string= (article-number a) d)
                                    collect (cons (node-source-line a)
                                                  (let ((p (first (article-paragraphs a))))
                                                    (when p
                                                      (let ((tx (paragraph-text p)))
                                                        (subseq tx 0 (min 70 (length tx)))))))))))
         ;; A numeric shared by DISTINCT labels (70 and 70Α) is a legitimate
         ;; lettered family — handled by article-file-id, NOT data loss. Only a
         ;; repeated FULL label (a true duplicate) or a sequence gap fails OK.
         (ok (and (null dups) (null gaps)
                  (or (null expected-count) (= (length uniq) expected-count)))))
    (values ok
            (list :total (length articles) :unique (length uniq)
                  :min (first sorted) :max (car (last sorted))
                  :duplicates dups :numeric-collisions collisions :gaps gaps
                  :duplicate-details dup-details
                  :lettered (mapcar #'article-number lettered)
                  :expected expected-count :ok ok))))

(defun log-codification-report (report)
  "Emit the validation REPORT prominently; warn on every flagged issue."
  (log:info () "=== CODIFICATION VALIDATION ===")
  (log:info () "  total=~D unique=~D range=~A..~A lettered=~D"
            (getf report :total) (getf report :unique)
            (getf report :min) (getf report :max) (length (getf report :lettered)))
  (when (getf report :expected)
    (log:info () "  expected=~D" (getf report :expected)))
  (when (getf report :duplicates)
    (log:warn () "  ⚠ DUPLICATE article numbers (~D): ~{~A~^, ~}"
              (length (getf report :duplicates)) (getf report :duplicates))
    (dolist (d (getf report :duplicate-details))
      (log:warn () "    duplicate ~A:" (car d))
      (dolist (occ (cdr d))
        (log:warn () "      @line ~A: |~A|" (car occ) (or (cdr occ) "<empty>")))))
  (when (getf report :numeric-collisions)
    (log:info () "  · lettered families (~D, preserved via file-id, not duplicates): ~{~A~^; ~}"
              (length (getf report :numeric-collisions))
              (mapcar (lambda (c) (format nil "~D→{~{~A~^,~}}" (car c) (cdr c)))
                      (getf report :numeric-collisions))))
  (when (getf report :gaps)
    (log:warn () "  ⚠ SEQUENCE GAPS: ~{~A~^, ~}"
              (mapcar (lambda (g) (format nil "~D→~D" (car g) (cdr g))) (getf report :gaps))))
  (if (getf report :ok)
      (log:info () "  ✓ VALIDATION PASSED — parse is self-consistent")
      (log:warn () "  ⚠ VALIDATION FLAGGED — review the above before publishing as authoritative")))

;;; ============================================================================
;;; ISOKRATIS (ΔΣΑ legal database) FORMAT  — a different source style
;;; ============================================================================
;;;
;;; The Isokratis export is highly regular:
;;;     Αρθρο: N            (no tonos, colon — NOT the ΦΕΚ 'Άρθρο N' form)
;;;     Τίτλος Αρθρου       (label; following lines are the title / amendment note)
;;;     Κείμενο Αρθρου      (label; following lines are the article body)
;;;     … (until the next 'Αρθρο: N')
;;; A dedicated parser yields the same FEK-ARTICLE objects, so everything
;;; downstream (validation, IIR, RDF, HTML) works unchanged.

(defparameter +article-suffix-regex+
  "([Α-ΩA-Zα-ω]+)"
  "Η ΜΙΑ γραμματική ΑΝΑΓΝΩΡΙΣΗΣ γράμμα-επιθήματος σε ΒΡΩΜΙΚΕΣ πηγές
   (PDF/Isokratis): μία ή περισσότερες αλφαβητικές (ελληνικά, ή λατινικά
   ομόγλυφα που κανονικοποιούνται στον καταναλωτή της κεφαλίδας). ΦΙΛΕΛΕΥΘΕΡΗ
   ΩΣ ΣΧΗΜΑ ώστε να πιάνει ΚΑΘΕ νομοθετικό επίθημα (Α, ΣΤ, ΙΑ, ΙΣΤ, ΚΑ…) —
   η ΕΓΚΥΡΟΤΗΤΑ/σειρά κρίνεται ΑΠΟΚΛΕΙΣΤΙΚΑ από την έδρα
   orchestrator.model:article-suffix-ordinal (μονογράμματο pattern εδώ είχε
   αφήσει το ΣΤ τυφλό σημείο· η ίδια κλάση θα ξαναχτυπούσε στα ΙΑ/ΚΑ).")

(defparameter *isokratis-article-scanner*
  ;; the suffix letter may be a LATIN homoglyph («Αρθρο: 105A») — accepted here
  ;; and normalised to Greek where the header is consumed, so lettered articles
  ;; are never silently dropped (nor their bodies swallowed by the previous one).
  (cl-ppcre:create-scanner
   (format nil "^\\s*[ΆΑA]ρθρο\\s*:\\s*(\\d+)\\s*~A?\\s*$" +article-suffix-regex+))
  "Isokratis article header 'Αρθρο: N' (Reg 1 = number, Reg 2 = optional suffix).")

(defun isokratis-text-p (text)
  "True when TEXT is an Isokratis (ΔΣΑ) legal-database export."
  (and text (or (search "ΙΣΟΚΡΑΤΗΣ" text)
                (and (search "Κείμενο Αρθρου" text) (search "ρθρο:" text)))))

(defun %structural-header-p (line)
  "True when LINE is an all-caps structural heading that the Isokratis export
   folds into the first article of a book/part/chapter — e.g. 'ΠΡΩΤΟ ΒΙΒΛΙΟ',
   'ΓΕΝΙΚΟ ΜΕΡΟΣ', 'ΠΡΩΤΟ ΚΕΦΑΛΑΙΟ', 'Ο ΠΟΙΝΙΚΟΣ ΝΟΜΟΣ', 'Ι. ΒΑΣΙΚΕΣ ΑΡΧΕΣ',
   'ΙΙ. ΤΟΠΙΚΑ ΟΡΙΑ ...'. It has cased letters, none of them lower-case, and is
   short. Normative article text is mixed-case, so it is never matched."
  (let ((s (string-trim '(#\Space #\Tab #\Return) line)))
    (and (plusp (length s))
         ;; 100: banners wrap — «ΔΙΑΦΟΡΕΣ ΠΟΥ ΑΝΑΦΥΟΝΤΑΙ ΚΑΤΑ ΤΗΝ ΕΚΛΟΓΙΚΗ
         ;; ΔΙΑΔΙΚΑΣΙΑ ΣΤΑ ΝΟΜΙΚΑ ΠΡΟΣΩΠΑ» is 75 chars. Normative prose is
         ;; never an all-caps line, so the wider limit cannot eat body text.
         (<= (length s) 100)
         (some (lambda (c) (and (alpha-char-p c) (upper-case-p c))) s)
         (notany (lambda (c) (and (alpha-char-p c) (lower-case-p c))) s))))

(defun isolate-isokratis-labels (text)
  "Put every structural body/title label on its OWN line. The Isokratis .docx export
   (unlike its PDF) folds a label into an adjacent paragraph two ways:
     • prefix — «Κείμενο Αρθρου  «1. …»   (label + first body line together), and
     • suffix — «… ΜΗ ΕΜΦΑΝΙΣΗ ΔΙΑΔΙΚΟΥ Κείμενο Αρθρου» (keywords + label together).
   Either way an exact line match misses the body and the article comes out empty.
   Surrounding each label with newlines normalises both cases back to the canonical
   one-label-per-line form the parser expects, with NO loss of text. Only the two
   fully-capitalised two-word labels are isolated (they do not occur in body prose),
   so normative text is never split."
  (let ((s text))
    (dolist (label '("Κείμενο Αρθρου" "Τίτλος Αρθρου") s)
      (setf s (cl-ppcre:regex-replace-all
               (cl-ppcre:quote-meta-chars label) s
               (format nil "~%~A~%" label))))))

(defun %section-label-rest (line label)
  "If LINE begins with the section LABEL (followed by whitespace or end-of-line),
   return the trimmed remainder after the label — or T when nothing follows; NIL when
   LINE is not this label at all. Defensive: even after ISOLATE-ISOKRATIS-LABELS puts
   each label on its own line, this keeps the merged-prefix case handled precisely
   (whitespace boundary required after the label so the match stays exact)."
  (let ((ll (length label)) (sl (length line)))
    (when (and (>= sl ll)
               (string= line label :end1 ll)
               (or (= sl ll) (member (char line ll) '(#\Space #\Tab))))
      (let ((rest (string-left-trim '(#\Space #\Tab) (subseq line ll))))
        (if (plusp (length rest)) rest t)))))

(defun isokratis-consolidated-p (text)
  "True for the Isokratis (ΔΣΑ) CONSOLIDATED code export — the format that lists a
   table of contents, then «Άρθρο : N» (bare) / title / «Ημ/νία τελευταίας
   τροποποίησης» / body per article, and has NO «Κείμενο Αρθρου» label (that label
   marks the OTHER, per-article-metadata Isokratis export handled directly)."
  (and text
       (search "τελευταίας τροποποίησης" text)
       (not (search "Κείμενο Αρθρου" text))))

(defun isokratis-consolidated->canonical (text)
  "Rewrite the Isokratis CONSOLIDATED export into the canonical labelled form that
   PARSE-ISOKRATIS-TEXT already understands (Αρθρο: N / Τίτλος Αρθρου / Κείμενο Αρθρου),
   so ALL article-building logic — orthography, paragraph splitting, marker stripping —
   is REUSED, never duplicated. The leading table of contents is skipped automatically:
   its entries are «Άρθρο : N Title …dots», never a bare «Άρθρο : N» line, so only the
   body's bare headers open an article. A repealed article («ΠΑΡΑΛΕΙΠΕΤΑΙ ως ΜΗ ισχύον»)
   carries that notice as its body, so it reads as repealed — not empty."
  (let ((hdr (load-time-value
              ;; the suffix letter may be a LATIN homoglyph in the export
              ;; («Άρθρο : 142A», «361B») — accepted and normalised to Greek
              ;; below, so those articles are never silently dropped.
              (cl-ppcre:create-scanner
               (format nil "^\\s*[ΆΑ]ρθρο\\s*:\\s*([0-9]+)\\s*~A?\\s*$" +article-suffix-regex+))))
        (out (make-string-output-stream))
        (num nil) (title nil) (body '()) (state :seek) (moddate nil))
    (labels ((defang (s)
               ;; upcase AND strip tonos, so «Παραλείπεται» → «ΠΑΡΑΛΕΙΠΕΤΑΙ» (Greek
               ;; upcase keeps the tonos: Ί≠Ι) and the repeal test is accent-insensitive.
               (map 'string (lambda (c)
                              (case c ((#\Ά) #\Α) ((#\Έ) #\Ε) ((#\Ή) #\Η) ((#\Ί #\Ϊ) #\Ι)
                                      ((#\Ό) #\Ο) ((#\Ύ #\Ϋ) #\Υ) ((#\Ώ) #\Ω) (t c)))
                    (string-upcase (or s ""))))
             (repeal-p (s)
               ;; «ΠΑΡΑΛΕΙΠΕΤΑΙ ΩΣ ΜΗ ΙΣΧΥΟΝ» / «Παραλείπεται ως μη ισχύον» /
               ;; «Καταργήθηκε» — accent- and case-insensitive.
               (let ((u (defang s)))
                 (or (search "ΠΑΡΑΛΕΙΠΕΤΑΙ" u) (search "ΚΑΤΑΡΓΗΘΗΚΕ" u)
                     (search "ΚΑΤΑΡΓΕΙΤΑΙ" u) (search "ΜΗ ΙΣΧΥΟΝ" u))))
             (alnum (s) (some #'alphanumericp s))
             (flush ()
               (when num
                 (let* ((btext (string-trim '(#\Space #\Newline #\Tab)
                                            (format nil "~{~A~^~%~}" (nreverse body))))
                        (has-body (alnum btext))
                        ;; no body + substantive title = the whole article IS that
                        ;; sentence (e.g. the entry-into-force article). It becomes
                        ;; the BODY ONLY — emitting it as title too would serve the
                        ;; same sentence twice (title AND content).
                        (title-is-body (and (not has-body)
                                            title (plusp (length title))
                                            (not (repeal-p title)))))
                   (format out "Αρθρο: ~A~%" num)
                   ;; the export's per-article versioning fact — the substrate of
                   ;; point-in-time law (tempus regit actum): a decision dated
                   ;; BEFORE this applied the very text served today, PROVABLY.
                   (when moddate
                     (format out "Ημ/νία τελευταίας τροποποίησης : ~A~%" moddate))
                   (when (and title (plusp (length title)) (not title-is-body))
                     (format out "Τίτλος Αρθρου~%~A~%"
                             (if (repeal-p title) "(καταργήθηκε)" title)))
                   (format out "Κείμενο Αρθρου~%")
                   (cond
                     ;; repealed (in title or body) → surviving, mixed-case notice
                     ((or (repeal-p title) (repeal-p btext))
                      (format out "Καταργήθηκε ως μη ισχύον.~%"))
                     (has-body (format out "~A~%" btext))
                     (title-is-body (format out "~A~%" title))
                     (t (format out "Καταργήθηκε ως μη ισχύον.~%"))))
                 (setf num nil title nil body nil moddate nil))))
      (dolist (raw (uiop:split-string text :separator '(#\Newline)))
        (let ((s (string-trim '(#\Space #\Tab #\Return) raw)))
          (multiple-value-bind (m g) (cl-ppcre:scan-to-strings hdr s)
            (cond
              (m (flush)
                 (setf num (format nil "~A~@[~A~]"
                                   (aref g 0)
                                   (let ((suf (aref g 1)))
                                     (when (and suf (plusp (length suf)))
                                       ;; Latin homoglyph suffix → Greek (142A → 142Α)
                                       (map 'string   ; per-char, so the digraph ΣΤ (370ΣΤ) passes intact
                                            (lambda (c) (or (cdr (assoc c *latin->greek-homoglyph*)) c))
                                            suf))))
                       title nil body nil state :title))
              ((eq state :title)
               (cond ((zerop (length s)) nil)
                     ((eql 0 (search "Ημ/νία" s))          ; capture, don't drop
                      (let ((c (position #\: s)))
                        (when c (setf moddate (string-trim " " (subseq s (1+ c)))))))
                     ((%structural-header-p s) nil)        ; drop chapter banner
                     (t (setf title s state :body))))      ; first real line = title
              ((eq state :body)
               (cond ((eql 0 (search "Ημ/νία" s))          ; capture, don't drop
                      (let ((c (position #\: s)))
                        (when (and c (not moddate))
                          (setf moddate (string-trim " " (subseq s (1+ c)))))))
                     ;; a chapter banner between articles («ΚΕΦΑΛΑΙΟ …») belongs to the
                     ;; NEXT section, not this article's body — drop it, so a one-sentence
                     ;; article (whose text became the title) is not left with only a
                     ;; banner as body (which clean-body would then strip → empty).
                     ;; BUT a repeal notice «(ΤΟ ΠΑΡΟΝ ΑΡΘΡΟ ΠΑΡΑΛΕΙΠΕΤΑΙ ΩΣ ΜΗ ΙΣΧΥΟΝ).»
                     ;; is itself all-caps and short, so it trips %structural-header-p —
                     ;; yet it IS the article's body (it marks the article repealed). Keep
                     ;; it, so flush sees the repeal and emits «Καταργήθηκε ως μη ισχύον.»
                     ;; instead of falling back to the title-as-content branch.
                     ;; The banner\'s mixed-case SUBTITLE line(s) («ΚΕΦΑΛΑΙΟ ΤΕΤΑΡΤΟ» /
                     ;; «Κατά τόπον αρμοδιότητα») also belong to the NEXT section, so the
                     ;; banner switches to :tail — everything up to the next article
                     ;; header is dropped, never glued to this article\'s body.
                     ((and (%structural-header-p s) (not (repeal-p s)))
                      (setf state :tail))
                     (t
                      ;; DEMOTE a false title: an untitled article's body starts
                      ;; right after the header, so its (wrapped) first line was
                      ;; taken as the title. Greek never wraps a line onto an
                      ;; upper-case continuation, so a body line that STARTS
                      ;; lower-case proves the held "title" is the body's first
                      ;; line — put it back in front of the body.
                      (when (and title (null body) (plusp (length s))
                                 (let ((c (char s 0)))
                                   (and (alpha-char-p c) (char= c (char-downcase c)))))
                        (push title body)
                        (setf title nil))
                      (push raw body))))
              (t nil)))))                                  ; :seek → drop (TOC prefix)
      (flush))
    (get-output-stream-string out)))

;;; ============================================================================
;;; ΒΟΥΛΗ (Hellenic Parliament) print edition — e.g. the official Σύνταγμα book
;;; ============================================================================
;;;
;;; Structure: prologue → table of contents (the ONLY place article titles live:
;;; «Άρθρο 101. Τίτλος …dots… page» / continuation «102. Τίτλος …») → body with
;;; BARE headers («Άρθρο N», revision-marked «**Άρθρο 5Α») → signature («Αθήνα,
;;; …») → notes/index (back matter, dropped). Typography quirks handled here:
;;; Latin homoglyphs inside Greek words (Bουλή, Kυβερνήσεως, «O σεβασμός»),
;;; soft-hyphen line-break continuations (πολι­\n…τικής), standalone page-number
;;; lines interleaved mid-paragraph, and the stereotyped revision-footnote blocks
;;; («** Με δύο αστερίσκους δηλώνονται … Βουλής των Ελλήνων.»). The output is
;;; the SAME canonical labelled form the Isokratis parser consumes, so ALL
;;; article building (orthography, marker stripping, paragraph splitting) is
;;; REUSED — never duplicated.

(defun %fix-homoglyphs (line)
  "Normalise Latin homoglyphs to Greek inside Greek-lettered tokens, and the
   standalone article/pronoun tokens «O»/«H» that Greek prose uses."
  (cl-ppcre:regex-replace-all
   (load-time-value
    (cl-ppcre:create-scanner
     (format nil "[A-Za-z~A-~A~A-~A]+"
             (code-char #x0370) (code-char #x03FF)
             (code-char #x1F00) (code-char #x1FFF))))
   line
   (lambda (tok)
     (cond
       ;; token mixes Latin homoglyphs into a word with real Greek letters
       ((and (some (lambda (c) (assoc c *latin->greek-homoglyph*)) tok)
             (some (lambda (c) (and (char>= c (code-char #x0370))
                                    (char<= c (code-char #x1FFF))))
                   tok))
        (map 'string (lambda (c) (or (cdr (assoc c *latin->greek-homoglyph*)) c)) tok))
       ;; standalone Latin O/H = the Greek article Ο / Η in this typography
       ((string= tok "O") "Ο")
       ((string= tok "H") "Η")
       (t tok)))
   :simple-calls t))

(defparameter *vouli-bare-header*
  (cl-ppcre:create-scanner "^\\*{0,4}\\s*[ΆΑ]ρθρο\\s+(\\d{1,3})\\s*([ΑA])?\\s*\\*{0,4}$")
  "Body header of the Βουλή edition: bare «Άρθρο N», possibly revision-starred
   («**Άρθρο 5Α») and possibly with a Latin-homoglyph letter suffix.")

(defparameter *vouli-toc-entry*
  (cl-ppcre:create-scanner "^(?:[ΆΑ]ρθρο\\s+)?(\\d{1,3})\\s*([ΑA])?\\.\\s+(.*)$")
  "Table-of-contents entry: «Άρθρο 101. Τίτλος …» or the continuation style
   «101A. Τίτλος …» / «102. Τίτλος …» (the label «Άρθρο» appears once per group).")

(defun vouli-syntagma-p (text)
  "True for the Hellenic Parliament print edition of the Σύνταγμα: revision
   resolutions cited up front, bare «Άρθρο N» body headers, and NONE of the
   Isokratis labels."
  (and text
       (search "Αναθεωρητικ" text)          ; «…Αναθεωρητικής Βουλής των Ελλήνων»
       (search "Βουλής των Ελλήνων" text)
       (not (search "Κείμενο Αρθρου" text))
       (not (cl-ppcre:scan "(?m)^\\s*[ΆΑ]ρθρο\\s*:" text))
       (cl-ppcre:scan "(?m)^\\*{0,4}\\s*[ΆΑ]ρθρο\\s+\\d+\\s*$" text)))

(defun %vouli-toc-titles (lines end)
  "Parse the table of contents out of LINES[0:END): article label («5Α») →
   title. An entry's title may wrap; it is complete at the dotted leader with
   the page number, which is stripped. Prologue prose never carries dotted
   leaders, so it cannot produce an entry."
  (let ((titles (make-hash-table :test 'equal))
        (label nil) (acc '()))
    (labels ((finish (line)
               (let* ((joined (format nil "~{~A ~}~A" (nreverse acc) line))
                      ;; strip the dotted leader + page number, tolerating the
                      ;; stray «. » some entries carry before the dots
                      (title (cl-ppcre:regex-replace "[.\\s]*\\.{2,}[.\\s]*\\d+\\s*$" joined "")))
                 (setf title (string-trim '(#\Space #\.)
                                          (cl-ppcre:regex-replace-all "\\s{2,}" title " ")))
                 (when (and label (plusp (length title)))
                   (setf (gethash label titles) (%fix-homoglyphs title))))
               (setf label nil acc '())))
      (loop for i from 0 below end
            for raw = (string-trim '(#\Space #\Tab #\Return) (aref lines i))
            do (multiple-value-bind (m g) (cl-ppcre:scan-to-strings *vouli-toc-entry* raw)
                 (cond
                   (m (when label (setf label nil acc '()))   ; unfinished → discard
                      (setf label (format nil "~A~@[~A~]" (aref g 0)
                                          (when (and (aref g 1) (plusp (length (aref g 1)))) "Α"))
                            acc '())
                      (if (cl-ppcre:scan "\\.{2,}\\s*\\d+\\s*$" (aref g 2))
                          (finish (aref g 2))
                          (push (aref g 2) acc)))
                   ((and label (cl-ppcre:scan "\\.{2,}\\s*\\d+\\s*$" raw)) (finish raw))
                   ;; a page number or blank line inside a wrapped entry (the
                   ;; ToC itself breaks across pages) — keep accumulating
                   ((and label (or (zerop (length raw))
                                   (cl-ppcre:scan "^\\d{1,3}$" raw))))
                   ((and label (plusp (length raw))
                         (not (%structural-header-p raw)))
                    (if (> (length acc) 2)                     ; runaway → not an entry
                        (setf label nil acc '())
                        (push raw acc)))
                   (t (setf label nil acc '()))))))
    titles))

(defun %vouli-merge-soft-hyphens (lines)
  "Join soft-hyphen (U+00AD) line-break continuations: a line ending with ­ is
   glued to the next line with the hyphen (and any spaces around it) removed.
   Page numbers / footnote blocks are already gone, so the continuation IS the
   next line. Mid-line soft hyphens are deleted."
  (let ((out '()) (pending nil))
    (dolist (l lines)
      (let* ((joined (if pending (concatenate 'string pending (string-left-trim " " l)) l))
             (trimmed (string-right-trim " " joined)))
        (if (and (plusp (length trimmed))
                 (char= (char trimmed (1- (length trimmed))) (code-char #xAD)))
            ;; line breaks mid-word: hold the prefix, glue the next line to it
            (setf pending (string-right-trim " " (subseq trimmed 0 (1- (length trimmed)))))
            (progn (push (remove (code-char #xAD) joined) out)
                   (setf pending nil)))))
    (when pending (push (remove (code-char #xAD) pending) out))
    (nreverse out)))

(defun vouli->canonical (text)
  "Rewrite the Βουλή print edition into the canonical labelled form
   (Αρθρο: N / Τίτλος Αρθρου / Κείμενο Αρθρου) that PARSE-ISOKRATIS-TEXT
   consumes. Titles come from the table of contents; back matter (signature,
   notes, index) is cut; page numbers, revision-footnote blocks, section
   banners with their subtitle lines, and typography artifacts are removed
   structurally. Joined-word artifacts are repaired by corpus evidence
   (ORCHESTRATOR.ORTHOGRAPHY:RESEGMENT-TEXT) at the end."
  (let* ((lines (coerce (uiop:split-string text :separator '(#\Newline)) 'vector))
         (n (length lines))
         ;; first body header = end of the front matter / ToC region
         (body-start (loop for i from 0 below n
                           when (cl-ppcre:scan *vouli-bare-header*
                                               (string-trim '(#\Space #\Tab #\Return) (aref lines i)))
                           return i))
         (titles (%vouli-toc-titles lines (or body-start n)))
         (out (make-string-output-stream))
         (cur nil) (body '()) (skip-until-header nil) (in-footnote nil))
    (labels ((flush ()
               (when cur
                 (let ((merged (%vouli-merge-soft-hyphens (nreverse body))))
                   (format out "Αρθρο: ~A~%" cur)
                   (let ((title (gethash cur titles)))
                     (when title (format out "Τίτλος Αρθρου~%~A~%" title)))
                   (format out "Κείμενο Αρθρου~%")
                   (dolist (l merged) (format out "~A~%" l)))
                 (setf cur nil body '()))))
      (loop for i from (or body-start n) below n
            for raw = (aref lines i)
            for s = (string-trim '(#\Space #\Tab #\Return) raw)
            do (cond
                 ;; hard stop: signature / back matter after the last article
                 ((or (cl-ppcre:scan "^Αθήνα,\\s*\\d" s)
                      (string= s "ΕΥΡΕΤΗΡΙΟ") (string= s "Σημειώσεις"))
                  (loop-finish))
                 ;; revision-footnote block: «** Με N αστερίσκους δηλώνονται …»
                 ;; runs to the first line that closes the sentence.
                 (in-footnote
                  (when (and (plusp (length s)) (char= (char s (1- (length s))) #\.))
                    (setf in-footnote nil)))
                 ((cl-ppcre:scan "^\\*+\\s*Με\\s.*αστερίσκ" s)
                  (unless (and (plusp (length s)) (char= (char s (1- (length s))) #\.))
                    (setf in-footnote t)))
                 ;; standalone page number
                 ((cl-ppcre:scan "^\\d{1,3}$" s))
                 ;; article header opens the next article
                 (t (multiple-value-bind (m g) (cl-ppcre:scan-to-strings *vouli-bare-header* s)
                      (cond
                        (m (flush)
                           (setf cur (format nil "~A~@[~A~]" (aref g 0)
                                             (when (and (aref g 1) (plusp (length (aref g 1)))) "Α"))
                                 skip-until-header nil))
                        ;; a section banner (with its subtitle lines) belongs to
                        ;; the NEXT article — drop everything until its header
                        ((%structural-header-p (%fix-homoglyphs s))
                         (setf skip-until-header t))
                        (skip-until-header)
                        ((zerop (length s)))
                        (cur (push (%fix-homoglyphs s) body)))))))
      (flush))
    (let ((canon (get-output-stream-string out)))
      (orchestrator.orthography:resegment-text
       canon (orchestrator.orthography:learn-orthography canon)))))

(defun parse-isokratis-text (text)
  "Parse an Isokratis (ΔΣΑ) export into FEK-ARTICLE objects. Recognizes the
   labeled sections of each 'Αρθρο: N' block —
     Τίτλος Αρθρου  → the article title (kept in node-metadata :title),
     Λήμματα        → keywords (skipped, never leak into title/body),
     Σχόλια         → amendment provenance (kept as article-amendment-info :note),
     Κείμενο Αρθρου → the normative body,
   ignores the per-article metadata lines (Ημ/νία…, Περιγραφή όρου θησαυρού…),
   and strips the leading structural headers (ΒΙΒΛΙΟ/ΜΕΡΟΣ/ΚΕΦΑΛΑΙΟ / roman
   sections) the export folds into a body. Deterministic; loses no normative text."
  (setf *fek-document* (make-instance 'fek-document :id 'ROOT :title "" :meri nil)
        *cross-reference-graph* nil)
  (let ((articles '()) (cur nil) (section :pre)
        (title-lines '()) (body-lines '()) (note-lines '()) (line-num 0)
        ;; Learn the corpus's own spelling ONCE from the whole text, then apply it
        ;; only to extracted bodies/titles below — never to the structural labels.
        (lexicon (orchestrator.orthography:learn-orthography text)))
    (labels ((tr (s) (string-trim '(#\Space #\Tab #\Return) s))
             (collapse (s) (tr (cl-ppcre:regex-replace-all "\\s{2,}" s " ")))
             (join (lines) (collapse (format nil "~{~A~^ ~}" (reverse lines))))
             (clean-body (lines)
               ;; LINES are in reverse (push) order; restore, then drop the leading
               ;; run of blank / structural-header lines before the real text.
               (let ((ls (reverse lines)))
                 (loop while (and ls (let ((h (tr (car ls))))
                                       (or (zerop (length h)) (%structural-header-p h))))
                       do (pop ls))
                 (collapse (format nil "~{~A~^ ~}" ls))))
             (meta-line-p (line)
               (or (eql 0 (search "Ημ/νία" line))
                   (eql 0 (search "Περιγραφή όρου θησαυρού" line))))
             (capture-moddate (line)
               ;; «Ημ/νία τελευταίας τροποποίησης : 01/05/2024» (consolidated) or
               ;; «Ημ/νία: 23.04.2010» (labelled export) → per-article version date,
               ;; normalised to DD/MM/YYYY. Kept in node-metadata :last-modified.
               (when (and cur
                          (or (eql 0 (search "Ημ/νία τελευταίας τροποποίησης" line))
                              (eql 0 (search "Ημ/νία:" line))))
                 (let ((c (position #\: line)))
                   (when c
                     (let ((d (substitute #\/ #\. (string-trim " " (subseq line (1+ c))))))
                       (when (and (= (length d) 10)
                                  (not (getf (node-metadata cur) :last-modified)))
                         (setf (node-metadata cur)
                               (list* :last-modified d (node-metadata cur)))))))))
             (flush ()
               (when cur
                 ;; Trim the quotes/guillemets the export wraps an amended title in
                 ;; ("Εγκληματική οργάνωση" / «Αναστολή …») — the title is the bare text.
                 ;; Apply corpus-driven orthography to the extracted title/body
                 ;; only (the structural labels were already consumed above).
                 (let ((title (orchestrator.orthography:restore-orthography
                               (string-trim '(#\Space #\Tab #\Newline #\" #\« #\» #\')
                                            (join title-lines))
                               lexicon))
                       (body (orchestrator.orthography:restore-orthography (clean-body body-lines) lexicon))
                       (note (join note-lines)))
                   (when (plusp (length title))
                     (setf (node-metadata cur) (list* :title title (node-metadata cur))))
                   (when (plusp (length body))
                     ;; The Isokratis export prepends an editorial note and wraps the
                     ;; text in quotes/guillemets at the HEAD of the body.
                     ;; strip-isokratis-markers is line-anchored, so re-run it here
                     ;; where the preamble sits at the body START — this clears
                     ;; «προσοχή && "…"» / «ΠΡΟΣΟΧΗ!!! Βλ. σχόλια "…"» that the raw,
                     ;; mid-line pass missed. Then split a guillemet-wrapped amended
                     ;; block «1. … 2. …» — or a plain sequentially-numbered body —
                     ;; into its real, cleanly-numbered paragraphs (the Constitution's
                     ;; rich canonical content shape).
                     (let* ((clean (strip-isokratis-markers body))
                            (split (or (%split-amended-paragraphs clean)
                                       (%split-plain-numbered-paragraphs clean))))
                       (setf (article-paragraphs cur)
                             (if split
                                 (loop for cell in split
                                       collect (make-instance 'fek-paragraph
                                                              :id (intern (format nil "PARA-~A-~D"
                                                                                  (article-number cur) (car cell)))
                                                              :number (car cell) :text (cdr cell)))
                                 (list (make-instance 'fek-paragraph
                                                      :id (intern (format nil "PARA-~A-0" (article-number cur)))
                                                      :number 0 :text clean))))))
                   (when (plusp (length note))
                     (setf (article-amendment-info cur) (list :note note)))
                   (push cur articles))
                 (setf cur nil section :pre title-lines nil body-lines nil note-lines nil))))
      (dolist (raw (uiop:split-string (isolate-isokratis-labels text) :separator '(#\Newline)))
        (incf line-num)
        (let ((line (tr raw)))
          (multiple-value-bind (m g) (cl-ppcre:scan-to-strings *isokratis-article-scanner* line)
            (cond
              (m
               (flush)
               (let* ((num (aref g 0))
                      (suf (let ((x (and (> (length g) 1) (aref g 1))))
                             ;; Latin homoglyph suffix → Greek (105A → 105Α)
                             (when (and x (plusp (length x)))
                               (map 'string   ; per-char, so the digraph ΣΤ (272ΣΤ) passes intact
                                    (lambda (c) (or (cdr (assoc c *latin->greek-homoglyph*)) c))
                                    x))))
                      (full (if suf (concatenate 'string num suf) num)))
                 (setf cur (make-instance 'fek-article
                                          :id (intern (format nil "ARTICLE-~A" full))
                                          :number full
                                          :numeric (or (ignore-errors (parse-integer num)) 0)
                                          :suffix suf
                                          :confidence 1.0 :source-line line-num)
                       section :pre)))
              ((%section-label-rest line "Τίτλος Αρθρου")
               (setf section :title)
               (let ((rest (%section-label-rest line "Τίτλος Αρθρου")))
                 (when (and cur (stringp rest) (plusp (length rest))) (push rest title-lines))))
              ((%section-label-rest line "Κείμενο Αρθρου")
               (setf section :body)
               (let ((rest (%section-label-rest line "Κείμενο Αρθρου")))
                 ;; body kept verbatim elsewhere; the merged first line is trimmed only
                 ;; of the label + its separating spaces, preserving the legal text.
                 (when (and cur (stringp rest)) (push rest body-lines))))
              ((%section-label-rest line "Σχόλια")
               (setf section :note)
               (let ((rest (%section-label-rest line "Σχόλια")))
                 (when (and cur (stringp rest) (plusp (length rest))) (push rest note-lines))))
              ((member line '("Λήμματα" "Λέξεις Κλειδιά" "Λέξεις-Κλειδιά Αρθρου"
                              "Λέξεις Κλειδιά Αρθρου") :test #'string=)
               (setf section :skip))
              ((and cur (meta-line-p line)) (capture-moddate line))
              (cur
               (case section
                 (:title (when (plusp (length line)) (push line title-lines)))
                 (:body (push raw body-lines))
                 (:note (when (plusp (length line)) (push line note-lines)))
                 (t nil)))))))
      (flush))
    (dedupe-isokratis-articles (nreverse articles))))

(defun %article-body-text (a)
  (let ((p (first (article-paragraphs a)))) (if p (paragraph-text p) "")))

(defun %pick-current-version (versions)
  "VERSIONS are articles sharing one label. Keep the CURRENT one: prefer a body
   carrying the amendment marker («/**) — the replacement text — else the longest
   substantive body. Returns (values kept dropped)."
  (if (= 1 (length versions))
      (values (first versions) nil)
      (let* ((marked (remove-if-not (lambda (a)
                                      (let ((b (%article-body-text a)))
                                        (or (search "«" b) (search "**" b))))
                                    versions))
             (ranked (sort (copy-list (or marked versions)) #'>
                           :key (lambda (a) (length (%article-body-text a)))))
             (kept (first ranked)))
        (values kept (remove kept versions)))))

(defun dedupe-isokratis-articles (articles)
  "Collapse repeated article labels to a single CURRENT version (the Isokratis
   export lists amended articles as original+replacement, repealed+new, or exact
   reprints). Transparent: logs each kept/dropped decision for audit."
  (let ((groups (make-hash-table :test 'equal)) (order '()))
    (dolist (a articles)
      (let ((lbl (article-number a)))
        (unless (nth-value 1 (gethash lbl groups)) (push lbl order))
        (push a (gethash lbl groups))))
    (let ((result '()))
      (dolist (lbl (nreverse order))
        (let ((versions (nreverse (gethash lbl groups))))
          (multiple-value-bind (kept dropped) (%pick-current-version versions)
            (when dropped
              (log:warn () "  dedup ~A: kept @line ~A, dropped ~{@line ~A~^, ~} (current version retained)"
                        lbl (node-source-line kept) (mapcar #'node-source-line dropped)))
            (push kept result))))
      (nreverse result))))

(defun pdf-adapter (pdf-path &key (encoding :utf-8) use-pipeline)
  "Extract and parse ΦΕΚ PDF - STATE OF THE ART"
  (declare (ignore encoding use-pipeline))
  (handler-case
      (progn
        (log:info () "ΦΕΚ PDF Adapter [STATE-OF-ART]: ~A" pdf-path)

        (unless (probe-file pdf-path)
          (error 'orchestrator.spec:config-error
                 :message (format nil "PDF not found: ~A" pdf-path)
                 :config-key :pdf-path))

        ;; Reset globals
        (setf *fek-document* nil
              *cross-reference-graph* nil
              *amendment-registry* nil
              *validation-errors* nil)

        ;; Extract and parse. The extraction strategy is chosen by SOURCE STYLE,
        ;; detected once on a cheap plain pass:
        ;;   • Isokratis (ΔΣΑ) is single-column — poppler's native order is correct
        ;;     and the Isokratis parser depends on it → use the plain text.
        ;;   • ΦΕΚ is two-column — poppler interleaves it and loses articles at the
        ;;     column/page seams → rebuild the reading order with the column-aware
        ;;     XY-cut extraction.
        ;; Overrides for comparison: PDF_PLAIN_EXTRACTION=1 (raw poppler order),
        ;; PDF_LAYOUT_EXTRACTION=1 (band-filter only).
        (let* ((plain-text (orchestrator.pdf-authority:extract-text-from-pdf pdf-path))
               (plain-clean (clean-fek-text plain-text))
               (isokratis (isokratis-text-p plain-clean))
               ;; The Isokratis CONSOLIDATED export (ToC + «Άρθρο : N»/title/body, no
               ;; «Κείμενο Αρθρου») is single-column like Isokratis; detect it too.
               (consolidated (isokratis-consolidated-p plain-clean))
               ;; The Βουλή print edition (the official Σύνταγμα book) is also
               ;; single-column with its own structure.
               (vouli (vouli-syntagma-p plain-clean))
               (raw-text (cond ((uiop:getenv "PDF_PLAIN_EXTRACTION") plain-text)
                               ((uiop:getenv "PDF_LAYOUT_EXTRACTION")
                                (orchestrator.pdf-authority:extract-text-layout-from-pdf pdf-path))
                               ;; Single-column sources keep poppler's FLOW order.
                               ;; MEASURED decision, not an assumption: routing the
                               ;; Isokratis exports through the XY-cut geometric
                               ;; rebuild was tested against the independent audit —
                               ;; it fixed NONE of the four known order quirks (their
                               ;; glyph boxes are anomalous in the PDF itself, so no
                               ;; ordering algorithm can recover them) and INTRODUCED
                               ;; four new ones (ΚΔΔ 30/63/82, ΚΠολΔ 368). Flow order
                               ;; is objectively superior here; the XY-cut remains
                               ;; the authority for the two-column ΦΕΚ layout.
                               ((or isokratis consolidated vouli) plain-text)
                               (t
                                (orchestrator.pdf-authority:extract-text-columns-from-pdf pdf-path))))
               (cleaned (clean-fek-text raw-text))
               ;; Dispatch to the right parser. All produce FEK-ARTICLE objects, so the
               ;; pipeline is style-agnostic. The consolidated export and the Βουλή
               ;; edition are normalised into the labelled Isokratis form and reuse
               ;; PARSE-ISOKRATIS-TEXT entirely.
               (articles (cond
                           (consolidated
                            (log:info () "Detected source style: Isokratis (ΔΣΑ) consolidated")
                            (parse-isokratis-text (isokratis-consolidated->canonical cleaned)))
                           (isokratis
                            (log:info () "Detected source style: Isokratis (ΔΣΑ)")
                            (parse-isokratis-text cleaned))
                           (vouli
                            (log:info () "Detected source style: Βουλή print edition")
                            ;; RAW text, not clean-fek-text: the generic cleaner
                            ;; dehyphenates across page breaks, which would splice
                            ;; a page-bottom revision footnote into the paragraph
                            ;; it interrupts. VOULI->CANONICAL removes footnotes
                            ;; and page numbers FIRST, then joins hyphenation.
                            (parse-isokratis-text (vouli->canonical plain-text)))
                           (t
                            (log:info () "Detected source style: ΦΕΚ")
                            (parse-fek-text cleaned)))))

          ;; Diagnostics: surface what actually came out of the PDF so a parse
          ;; of 0 articles can be told apart from an empty text extraction.
          (log:info () "PDF extraction: raw=~D chars, cleaned=~D chars, articles=~D"
                    (length (or raw-text "")) (length (or cleaned "")) (length articles))
          (when (null articles)
            (log:warn () "0 articles parsed. First 600 chars of cleaned text follow:~%~A"
                      (subseq (or cleaned "") 0 (min 600 (length (or cleaned "")))))
            ;; Dump the first lines that mention an article, so the real header
            ;; format of THIS source (e.g. Isokratis vs ΦΕΚ) is visible.
            (let ((shown 0))
              (dolist (ln (uiop:split-string (or cleaned "") :separator '(#\Newline)))
                (when (and (< shown 12)
                           (or (search "ρθρο" ln) (search "ΡΘΡΟ" ln)))
                  (incf shown)
                  (log:warn () "  article-line[~D]: |~A|" shown
                            (subseq ln 0 (min 120 (length ln))))))))

          ;; Validation
          (let ((gaps (validate-article-sequence articles))
                (invalid-refs (validate-cross-references articles *cross-reference-graph*)))
            (when gaps
              (log:warn () "Article sequence gaps: ~A" gaps)
              (push (list :gaps gaps) *validation-errors*))
            (when invalid-refs
              (log:warn () "Invalid cross-references: ~D" (length invalid-refs))
              (push (list :invalid-refs (length invalid-refs)) *validation-errors*)))

          ;; Log summary
          (log:info () "Parsed: ~D articles, ~D cross-refs, ~D ΜΕΡΗ"
                    (length articles)
                    (length *cross-reference-graph*)
                    (length (document-meri *fek-document*)))

          ;; Codification validation gate — flag duplicates / collisions / gaps
          ;; before anything downstream publishes the parse as authoritative.
          (when articles
            (multiple-value-bind (ok report) (validate-codification articles)
              (declare (ignore ok))
              (log-codification-report report)))

          ;; Confidence — guard the empty case (reduce #'min on '() calls (min)
          ;; with zero arguments and errors).
          (when articles
            (log:info () "Confidence: min=~,2F avg=~,2F max=~,2F"
                      (reduce #'min articles :key #'node-confidence)
                      (/ (reduce #'+ articles :key #'node-confidence) (max 1 (length articles)))
                      (reduce #'max articles :key #'node-confidence)))

          ;; Store for REPL inspection
          (setf *last-parsed-articles* articles)

          ;; Convert to IIR
          (mapcar (lambda (art) (article-to-iir art pdf-path)) articles)))

    (error (e)
      (error 'orchestrator.spec:stage-error
             :message (format nil "ΦΕΚ PDF adapter failed: ~A" e)
             :stage-name :pdf-adapter))))

;;; ============================================================================
;;; REPL UTILITIES
;;; ============================================================================

(defun inspect-article (num)
  "Find article by number in last parse (uses *last-parsed-articles*)"
  (find num *last-parsed-articles* :key #'article-numeric))

(defun show-cross-ref-graph ()
  "Display cross-reference graph"
  (loop for ref in *cross-reference-graph*
        collect (list (xref-source-article ref)
                      '-> (xref-target-article ref))))

(defun export-lisp (articles &optional (stream *standard-output*))
  "Export as executable Lisp"
  (format stream ";;;; Ελληνικό Σύνταγμα - Homoiconic Export~%")
  (format stream "(defparameter *syntagma*~%  '(~%")
  (dolist (art articles)
    (format stream "    ~S~%" (article-to-sexp art)))
  (format stream "  ))~%"))
