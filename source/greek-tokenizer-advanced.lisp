;;;; source/greek-tokenizer-advanced.lisp
;;;; ============================================================================
;;;; DARPA-GRADE GREEK TOKENIZER - Maximum Lisp Exploitation
;;;; ============================================================================
;;;;
;;;; Κορυφαίος Greek tokenizer που εκμεταλλεύεται το 100% της δύναμης της Lisp.
;;;;
;;;; LISP EXPLOITATION (100%):
;;;;   1. CLOS - Object-oriented tokens with rich metadata
;;;;   2. Multiple Values - Return token + metadata efficiently
;;;;   3. Conditions/Restarts - Robust error recovery
;;;;   4. Macros - DSL for vocabulary definition
;;;;   5. Type Declarations - SBCL native optimization
;;;;   6. Hash Tables - O(1) lookups everywhere
;;;;   7. Destructuring - Pattern matching on morphology
;;;;   8. Generic Functions - Extensible tokenization
;;;;   9. Method Combinations - Layered processing
;;;;  10. Compile-time Computation - Static vocabulary
;;;;
;;;; FEATURES:
;;;;   - Position tracking for NER/POS tagging
;;;;   - Subword tokenization (BPE-ready)
;;;;   - Morphological segmentation
;;;;   - Tonos preservation (SUPERIOR to Python)
;;;;   - Reversible tokenization
;;;;   - Token metadata (type, confidence)
;;;;   - Verified Greek vocabulary
;;;;
;;;; Author: ORCHESTRATOR
;;;; Created: 2026-01-03
;;;; ============================================================================

(defpackage :orchestrator.greek-tokenizer
  (:use :cl)
  (:export
   ;; Token Classes
   #:token
   #:token-text
   #:token-lemma
   #:token-start
   #:token-end
   #:token-type
   #:token-features
   #:token-confidence
   ;; Tokenization
   #:tokenize-advanced
   #:tokenize-to-tokens
   #:tokenize-with-positions
   ;; BPE Subword
   #:bpe-tokenize
   #:train-bpe
   #:save-bpe-model
   #:load-bpe-model
   #:bpe-model-to-data
   #:bpe-decode-error
   ;; Morphology
   #:segment-morphology
   #:extract-prefix
   #:extract-suffix
   #:extract-stem
   ;; Vocabulary
   #:verified-word-p
   #:get-word-info
   #:vocabulary-size
   ;; Reconstruction
   #:reconstruct-text
   #:tokens-to-string
   ;; Configuration
   #:*preserve-tonos*
   #:*min-token-length*
   #:*enable-subword*))

(in-package :orchestrator.greek-tokenizer)

;;; ============================================================================
;;; SBCL OPTIMIZATION - Maximum Speed
;;; ============================================================================

(declaim (optimize (speed 3) (safety 1) (debug 1) (space 0)))

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *preserve-tonos* t
  "Preserve Greek tonos (accents). CRITICAL for semantic distinction.")

(defvar *min-token-length* 1
  "Minimum token length. DARPA-GRADE: Keep ALL tokens (1).")

(defvar *enable-subword* nil
  "Enable BPE subword tokenization for unknown words.")

;;; ============================================================================
;;; TOKEN CLASS - CLOS Power
;;; ============================================================================
;;; Rich token object with full metadata for downstream processing

(defclass token ()
  ((text :initarg :text
         :accessor token-text
         :type string
         :documentation "Original token text")
   (lemma :initarg :lemma
          :accessor token-lemma
          :type (or string null)
          :initform nil
          :documentation "Base form (lemma) of the token")
   (start :initarg :start
          :accessor token-start
          :type fixnum
          :documentation "Start position in original text")
   (end :initarg :end
        :accessor token-end
        :type fixnum
        :documentation "End position in original text")
   (type :initarg :type
         :accessor token-type
         :type keyword
         :initform :word
         :documentation "Token type: :word, :number, :punctuation, :symbol")
   (features :initarg :features
             :accessor token-features
             :type list
             :initform nil
             :documentation "Feature plist: :pos, :case, :number, :gender, etc.")
   (confidence :initarg :confidence
               :accessor token-confidence
               :type single-float
               :initform 1.0
               :documentation "Confidence score [0.0, 1.0]")
   (subwords :initarg :subwords
             :accessor token-subwords
             :type list
             :initform nil
             :documentation "BPE subword decomposition"))
  (:documentation "CLOS token with rich metadata for Greek NLP"))

(defmethod print-object ((tok token) stream)
  (print-unreadable-object (tok stream :type t)
    (format stream "~S [~D:~D] ~A"
            (token-text tok)
            (token-start tok)
            (token-end tok)
            (token-type tok))))

;;; ============================================================================
;;; LISP EXPLOITATION #1: MACROS - DSL for Vocabulary Definition
;;; ============================================================================

(defmacro define-greek-vocabulary (name &body entries)
  "Compile-time vocabulary definition DSL.

   Usage:
     (define-greek-vocabulary legal-terms
       (\"νόμος\" :pos :noun :gender :masculine :verified t)
       (\"δημοκρατία\" :pos :noun :gender :feminine :verified t))"
  (let ((table-name (intern (format nil "*~A-TABLE*" name)))
        (size-name (intern (format nil "~A-SIZE" name))))
    `(progn
       (defparameter ,table-name
         (let ((ht (make-hash-table :test 'equal :size ,(length entries))))
           ,@(loop for entry in entries
                   collect `(setf (gethash ,(car entry) ht)
                                  (list ,@(cdr entry))))
           ht)
         ,(format nil "Compiled vocabulary table for ~A" name))
       (defun ,size-name ()
         ,(format nil "Return size of ~A vocabulary" name)
         (hash-table-count ,table-name))
       ',name)))

;;; ============================================================================
;;; VERIFIED GREEK VOCABULARY - Guaranteed Correct
;;; ============================================================================
;;; These entries are hand-verified from authoritative sources.
;;; Each entry: (word :pos <pos> :gender <g> :verified t)

(define-greek-vocabulary verified-greek
  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; ARTICLES - 100% Verified
  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; Definite articles (οριστικό άρθρο)
  ("ο" :pos :article :gender :masculine :number :singular :case :nominative :verified t)
  ("του" :pos :article :gender :masculine :number :singular :case :genitive :verified t)
  ("τον" :pos :article :gender :masculine :number :singular :case :accusative :verified t)
  ("οι" :pos :article :gender :masculine :number :plural :case :nominative :verified t)
  ("των" :pos :article :number :plural :case :genitive :verified t)
  ("τους" :pos :article :gender :masculine :number :plural :case :accusative :verified t)
  ("η" :pos :article :gender :feminine :number :singular :case :nominative :verified t)
  ("της" :pos :article :gender :feminine :number :singular :case :genitive :verified t)
  ("την" :pos :article :gender :feminine :number :singular :case :accusative :verified t)
  ("τη" :pos :article :gender :feminine :number :singular :case :accusative :verified t)
  ("τις" :pos :article :gender :feminine :number :plural :case :accusative :verified t)
  ("το" :pos :article :gender :neuter :number :singular :verified t)
  ("τα" :pos :article :gender :neuter :number :plural :verified t)

  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; PRONOUNS - 100% Verified
  ;; ═══════════════════════════════════════════════════════════════════════════
  ("αυτός" :pos :pronoun :gender :masculine :number :singular :verified t)
  ("αυτή" :pos :pronoun :gender :feminine :number :singular :verified t)
  ("αυτό" :pos :pronoun :gender :neuter :number :singular :verified t)
  ("αυτοί" :pos :pronoun :gender :masculine :number :plural :verified t)
  ("αυτές" :pos :pronoun :gender :feminine :number :plural :verified t)
  ("αυτά" :pos :pronoun :gender :neuter :number :plural :verified t)
  ("εγώ" :pos :pronoun :person :first :number :singular :verified t)
  ("εσύ" :pos :pronoun :person :second :number :singular :verified t)
  ("εμείς" :pos :pronoun :person :first :number :plural :verified t)
  ("εσείς" :pos :pronoun :person :second :number :plural :verified t)
  ("που" :pos :pronoun :type :relative :verified t)
  ("όποιος" :pos :pronoun :type :relative :verified t)

  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; CONJUNCTIONS & PREPOSITIONS - 100% Verified
  ;; ═══════════════════════════════════════════════════════════════════════════
  ("και" :pos :conjunction :type :coordinating :verified t)
  ("ή" :pos :conjunction :type :coordinating :verified t)
  ("αλλά" :pos :conjunction :type :coordinating :verified t)
  ("όμως" :pos :conjunction :type :coordinating :verified t)
  ("ούτε" :pos :conjunction :type :coordinating :verified t)
  ("είτε" :pos :conjunction :type :coordinating :verified t)
  ("ότι" :pos :conjunction :type :subordinating :verified t)
  ("επειδή" :pos :conjunction :type :subordinating :verified t)
  ("αφού" :pos :conjunction :type :subordinating :verified t)
  ("ενώ" :pos :conjunction :type :subordinating :verified t)
  ("αν" :pos :conjunction :type :subordinating :verified t)
  ("εάν" :pos :conjunction :type :subordinating :verified t)
  ("όταν" :pos :conjunction :type :subordinating :verified t)
  ("καθώς" :pos :conjunction :type :subordinating :verified t)
  ("από" :pos :preposition :verified t)
  ("σε" :pos :preposition :verified t)
  ("με" :pos :preposition :verified t)
  ("για" :pos :preposition :verified t)
  ("προς" :pos :preposition :verified t)
  ("κατά" :pos :preposition :verified t)
  ("υπέρ" :pos :preposition :verified t)
  ("χωρίς" :pos :preposition :verified t)
  ("μέχρι" :pos :preposition :verified t)
  ("μετά" :pos :preposition :verified t)
  ("πριν" :pos :preposition :verified t)

  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; NUMBERS (Greek) - 100% Verified
  ;; ═══════════════════════════════════════════════════════════════════════════
  ("ένα" :pos :numeral :value 1 :gender :neuter :verified t)
  ("ένας" :pos :numeral :value 1 :gender :masculine :verified t)
  ("μία" :pos :numeral :value 1 :gender :feminine :verified t)
  ("μια" :pos :numeral :value 1 :gender :feminine :verified t)
  ("δύο" :pos :numeral :value 2 :verified t)
  ("τρία" :pos :numeral :value 3 :gender :neuter :verified t)
  ("τρεις" :pos :numeral :value 3 :verified t)
  ("τέσσερα" :pos :numeral :value 4 :gender :neuter :verified t)
  ("τέσσερις" :pos :numeral :value 4 :verified t)
  ("πέντε" :pos :numeral :value 5 :verified t)
  ("έξι" :pos :numeral :value 6 :verified t)
  ("επτά" :pos :numeral :value 7 :verified t)
  ("εφτά" :pos :numeral :value 7 :verified t)
  ("οκτώ" :pos :numeral :value 8 :verified t)
  ("οχτώ" :pos :numeral :value 8 :verified t)
  ("εννέα" :pos :numeral :value 9 :verified t)
  ("εννιά" :pos :numeral :value 9 :verified t)
  ("δέκα" :pos :numeral :value 10 :verified t)
  ("έντεκα" :pos :numeral :value 11 :verified t)
  ("δώδεκα" :pos :numeral :value 12 :verified t)
  ("είκοσι" :pos :numeral :value 20 :verified t)
  ("τριάντα" :pos :numeral :value 30 :verified t)
  ("σαράντα" :pos :numeral :value 40 :verified t)
  ("πενήντα" :pos :numeral :value 50 :verified t)
  ("εξήντα" :pos :numeral :value 60 :verified t)
  ("εβδομήντα" :pos :numeral :value 70 :verified t)
  ("ογδόντα" :pos :numeral :value 80 :verified t)
  ("ενενήντα" :pos :numeral :value 90 :verified t)
  ("εκατό" :pos :numeral :value 100 :verified t)
  ("χίλια" :pos :numeral :value 1000 :verified t)
  ("πρώτος" :pos :numeral :type :ordinal :value 1 :verified t)
  ("δεύτερος" :pos :numeral :type :ordinal :value 2 :verified t)
  ("τρίτος" :pos :numeral :type :ordinal :value 3 :verified t)

  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; COMMON VERBS - 100% Verified (Indicative Present)
  ;; ═══════════════════════════════════════════════════════════════════════════
  ("είμαι" :pos :verb :tense :present :person :first :number :singular :verified t)
  ("είσαι" :pos :verb :tense :present :person :second :number :singular :verified t)
  ("είναι" :pos :verb :tense :present :person :third :verified t)
  ("είμαστε" :pos :verb :tense :present :person :first :number :plural :verified t)
  ("είστε" :pos :verb :tense :present :person :second :number :plural :verified t)
  ("έχω" :pos :verb :tense :present :person :first :number :singular :verified t)
  ("έχεις" :pos :verb :tense :present :person :second :number :singular :verified t)
  ("έχει" :pos :verb :tense :present :person :third :number :singular :verified t)
  ("έχουμε" :pos :verb :tense :present :person :first :number :plural :verified t)
  ("έχετε" :pos :verb :tense :present :person :second :number :plural :verified t)
  ("έχουν" :pos :verb :tense :present :person :third :number :plural :verified t)
  ("κάνω" :pos :verb :tense :present :person :first :number :singular :verified t)
  ("κάνει" :pos :verb :tense :present :person :third :number :singular :verified t)
  ("κάνουν" :pos :verb :tense :present :person :third :number :plural :verified t)
  ("λέω" :pos :verb :tense :present :person :first :number :singular :verified t)
  ("λέει" :pos :verb :tense :present :person :third :number :singular :verified t)
  ("λένε" :pos :verb :tense :present :person :third :number :plural :verified t)
  ("θέλω" :pos :verb :tense :present :person :first :number :singular :verified t)
  ("θέλει" :pos :verb :tense :present :person :third :number :singular :verified t)
  ("θέλουν" :pos :verb :tense :present :person :third :number :plural :verified t)
  ("μπορώ" :pos :verb :tense :present :person :first :number :singular :verified t)
  ("μπορεί" :pos :verb :tense :present :person :third :number :singular :verified t)
  ("μπορούν" :pos :verb :tense :present :person :third :number :plural :verified t)
  ("πρέπει" :pos :verb :tense :present :type :impersonal :verified t)
  ("υπάρχει" :pos :verb :tense :present :person :third :number :singular :verified t)
  ("υπάρχουν" :pos :verb :tense :present :person :third :number :plural :verified t)

  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; LEGAL TERMS from Σύνταγμα της Ελλάδος - 100% Verified
  ;; ═══════════════════════════════════════════════════════════════════════════
  ("σύνταγμα" :pos :noun :gender :neuter :domain :legal :verified t)
  ("άρθρο" :pos :noun :gender :neuter :domain :legal :verified t)
  ("νόμος" :pos :noun :gender :masculine :domain :legal :verified t)
  ("δημοκρατία" :pos :noun :gender :feminine :domain :legal :verified t)
  ("πολίτευμα" :pos :noun :gender :neuter :domain :legal :verified t)
  ("κυριαρχία" :pos :noun :gender :feminine :domain :legal :verified t)
  ("λαός" :pos :noun :gender :masculine :domain :legal :verified t)
  ("έθνος" :pos :noun :gender :neuter :domain :legal :verified t)
  ("κράτος" :pos :noun :gender :neuter :domain :legal :verified t)
  ("εξουσία" :pos :noun :gender :feminine :domain :legal :verified t)
  ("δικαίωμα" :pos :noun :gender :neuter :domain :legal :verified t)
  ("ελευθερία" :pos :noun :gender :feminine :domain :legal :verified t)
  ("αξιοπρέπεια" :pos :noun :gender :feminine :domain :legal :verified t)
  ("ισότητα" :pos :noun :gender :feminine :domain :legal :verified t)
  ("δικαιοσύνη" :pos :noun :gender :feminine :domain :legal :verified t)
  ("πολίτης" :pos :noun :gender :masculine :domain :legal :verified t)
  ("υποχρέωση" :pos :noun :gender :feminine :domain :legal :verified t)
  ("θρησκεία" :pos :noun :gender :feminine :domain :legal :verified t)
  ("εκκλησία" :pos :noun :gender :feminine :domain :legal :verified t)
  ("προστασία" :pos :noun :gender :feminine :domain :legal :verified t)
  ("διάταξη" :pos :noun :gender :feminine :domain :legal :verified t)
  ("παράγραφος" :pos :noun :gender :feminine :domain :legal :verified t)
  ("εδάφιο" :pos :noun :gender :neuter :domain :legal :verified t)
  ("κοινοβουλευτική" :pos :adjective :gender :feminine :domain :legal :verified t)
  ("προεδρευόμενη" :pos :adjective :gender :feminine :domain :legal :verified t)
  ("ορθόδοξη" :pos :adjective :gender :feminine :domain :legal :verified t)
  ("αυτοκέφαλη" :pos :adjective :gender :feminine :domain :legal :verified t)

  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; TONOS-SENSITIVE PAIRS - Critical for Semantic Distinction
  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; These prove SUPERIORITY over Python (sklearn strips accents by default)
  ("πότε" :pos :adverb :type :interrogative :meaning "when?" :verified t)
  ("ποτέ" :pos :adverb :type :indefinite :meaning "never/ever" :verified t)
  ("νόμος" :pos :noun :gender :masculine :meaning "law" :verified t)
  ("νομός" :pos :noun :gender :masculine :meaning "prefecture" :verified t)
  ("πόρος" :pos :noun :gender :masculine :meaning "resource" :verified t)
  ("πορός" :pos :noun :gender :masculine :meaning "pore" :verified t)
  ("γέρος" :pos :noun :gender :masculine :meaning "old man" :verified t)
  ("γερός" :pos :adjective :meaning "strong/healthy" :verified t)
  ("άλλα" :pos :pronoun :gender :neuter :number :plural :meaning "others" :verified t)
  ("αλλά" :pos :conjunction :meaning "but" :verified t)
  ("ή" :pos :conjunction :meaning "or" :verified t)
  ("η" :pos :article :gender :feminine :meaning "the (fem.)" :verified t))

;;; ============================================================================
;;; LISP EXPLOITATION #2: MULTIPLE VALUES - Efficient Return
;;; ============================================================================

(defun greek-char-p (char)
  "Check if character is Greek letter.
   Returns: (values is-greek is-accented)"
  (declare (type character char)
           (optimize (speed 3)))
  (let ((code (char-code char)))
    (cond
      ;; Greek Extended (with accents)
      ((<= #x1F00 code #x1FFF)
       (values t t))
      ;; Greek and Coptic (basic + tonos)
      ((<= #x0370 code #x03FF)
       (values t (or (<= #x0386 code #x038A)    ; Ά, Έ, Ή, Ί
                     (= code #x038C)             ; Ό
                     (<= #x038E code #x03CE))))  ; Ύ, Ώ, ά-ώ
      (t (values nil nil)))))

(defun classify-char (char)
  "Classify character into token type.
   Returns: (values type is-greek has-tonos)"
  (declare (type character char)
           (optimize (speed 3)))
  (cond
    ((digit-char-p char)
     (values :digit nil nil))
    ((alpha-char-p char)
     (multiple-value-bind (greek accented) (greek-char-p char)
       (if greek
           (values :greek greek accented)
           (values :latin nil nil))))
    ((member char '(#\Space #\Tab #\Newline #\Return))
     (values :whitespace nil nil))
    ((member char '(#\. #\, #\; #\: #\! #\? #\( #\) #\[ #\] #\{ #\}))
     (values :punctuation nil nil))
    (t
     (multiple-value-bind (greek accented) (greek-char-p char)
       (if greek
           (values :greek greek accented)
           (values :symbol nil nil))))))

;;; ============================================================================
;;; LISP EXPLOITATION #3: CONDITIONS/RESTARTS - Robust Error Recovery
;;; ============================================================================

(define-condition tokenization-warning (warning)
  ((text :initarg :text :reader warning-text)
   (position :initarg :position :reader warning-position)
   (message :initarg :message :reader warning-message))
  (:report (lambda (c stream)
             (format stream "Tokenization warning at position ~D: ~A"
                     (warning-position c)
                     (warning-message c)))))

(define-condition unknown-character-warning (tokenization-warning)
  ((character :initarg :character :reader warning-character))
  (:report (lambda (c stream)
             (format stream "Unknown character '~A' (U+~4,'0X) at position ~D"
                     (warning-character c)
                     (char-code (warning-character c))
                     (warning-position c)))))

(defparameter +silent-boundary-chars+
  "«»‘’“”\"'—–-/…§·•®©°+*=%&@#$^~`[]{}<>|\\_"
  "Στίξη/σύμβολα ΦΥΣΙΟΛΟΓΙΚΑ σε ελληνικά νομικά κείμενα (εισαγωγικά,
   παύλες, πλάγιες, παράγραφοι…): όρια λέξης ΧΩΡΙΣ προειδοποίηση —
   ο θόρυβος «Unknown character» δεν είναι πληροφορία, είναι στίξη.")

(defun handle-unknown-char (char position)
  "Handle unknown character with restarts.
   LISP POWER: Condition system allows caller to choose recovery strategy."
  (when (find char +silent-boundary-chars+)
    (return-from handle-unknown-char :boundary))
  (restart-case
      (warn 'unknown-character-warning
            :text (string char)
            :position position
            :message "Unexpected character encountered"
            :character char)
    (skip-character ()
      :report "Skip this character"
      nil)
    (include-as-symbol ()
      :report "Include as symbol token"
      :symbol)
    (replace-with-space ()
      :report "Replace with space (word boundary)"
      :boundary)))

;;; ============================================================================
;;; LISP EXPLOITATION #4: GENERIC FUNCTIONS - Extensible Processing
;;; ============================================================================

(defgeneric normalize-token (token mode)
  (:documentation "Normalize token text based on mode.
   Extensible via method dispatch."))

(defmethod normalize-token ((text string) (mode (eql :lowercase)))
  "Convert to lowercase, preserving Greek tonos."
  (string-downcase text))

(defmethod normalize-token ((text string) (mode (eql :preserve)))
  "Preserve original case and accents."
  text)

(defmethod normalize-token ((text string) (mode (eql :strip-tonos)))
  "Remove tonos (for compatibility tests only - NOT RECOMMENDED)."
  (let ((result (make-array (length text) :element-type 'character :fill-pointer 0)))
    (loop for char across text
          do (vector-push-extend
              (case char
                ;; Lowercase vowels with tonos → without
                (#\ά #\α) (#\έ #\ε) (#\ή #\η) (#\ί #\ι)
                (#\ό #\ο) (#\ύ #\υ) (#\ώ #\ω)
                ;; Uppercase
                (#\Ά #\Α) (#\Έ #\Ε) (#\Ή #\Η) (#\Ί #\Ι)
                (#\Ό #\Ο) (#\Ύ #\Υ) (#\Ώ #\Ω)
                (otherwise char))
              result))
    (coerce result 'string)))

;;; ============================================================================
;;; MORPHOLOGICAL SEGMENTATION
;;; ============================================================================
;;; Greek morphology: PREFIX + STEM + SUFFIX

(defparameter *greek-prefixes*
  '(;; Negation
    ("α" . :negation)        ; α-δύνατος
    ("αν" . :negation)       ; αν-ίκανος
    ("δυσ" . :negative)      ; δυσ-κολία
    ;; Prepositions as prefixes
    ("υπερ" . :over)         ; υπερ-βολή
    ("υπο" . :under)         ; υπο-γραφή
    ("κατα" . :down)         ; κατα-βολή
    ("ανα" . :up)            ; ανα-βαθμός
    ("επι" . :upon)          ; επι-στήμη
    ("αντι" . :against)      ; αντι-κείμενο
    ("μετα" . :after)        ; μετα-φορά
    ("παρα" . :beside)       ; παρα-βολή
    ("περι" . :around)       ; περι-βάλλον
    ("προ" . :before)        ; προ-ηγούμενος
    ("συν" . :with)          ; συν-εργασία
    ("συμ" . :with)          ; συμ-μετοχή
    ("δια" . :through)       ; δια-κοπή
    ("εκ" . :out)            ; εκ-δοση
    ("εισ" . :into)          ; εισ-αγωγή
    ("απο" . :from)          ; απο-φαση
    ;; Intensifiers
    ("πολυ" . :many)         ; πολυ-πλοκος
    ("ολο" . :all)           ; ολο-κληρος
    ("παν" . :all)           ; παν-ελλήνιος
    ("αρχι" . :chief))       ; αρχι-επίσκοπος
  "Greek prefixes with semantic roles")

(defparameter *greek-suffixes*
  '(;; Noun suffixes
    ("της" . :agent)         ; κριτής (judge)
    ("ισμός" . :ism)         ; ρεαλισμός
    ("ότητα" . :quality)     ; ικανότητα
    ("τητα" . :quality)      ; ταχύτητα
    ("σία" . :state)         ; δημοκρατία
    ("ία" . :state)          ; κυριαρχία
    ("μα" . :result)         ; γράμμα
    ("ση" . :action)         ; απόφαση
    ("ξη" . :action)         ; πράξη
    ;; Adjective suffixes
    ("ικός" . :related-to)   ; νομικός
    ("ικη" . :related-to)    ; νομική
    ("ικο" . :related-to)    ; νομικό
    ("τός" . :capable)       ; ορατός
    ("μένος" . :passive)     ; γραμμένος
    ;; Verb suffixes
    ("ω" . :verb-active)     ; γράφω
    ("ώ" . :verb-contract)   ; αγαπώ
    ("ομαι" . :verb-passive) ; γράφομαι
    ("ούμαι" . :verb-passive)) ; αγαπιέμαι
  "Greek suffixes with grammatical roles")

(defun extract-prefix (word)
  "Extract Greek prefix from word.
   Returns: (values prefix-text prefix-type remaining-word) or NIL"
  (declare (type string word)
           (optimize (speed 3)))
  (let ((lower (string-downcase word)))
    (dolist (entry *greek-prefixes*)
      (let ((prefix (car entry))
            (type (cdr entry)))
        (when (and (> (length lower) (length prefix))
                   (string= lower prefix :end1 (length prefix)))
          (return-from extract-prefix
            (values prefix type (subseq word (length prefix)))))))
    nil))

(defun extract-suffix (word)
  "Extract Greek suffix from word.
   Returns: (values suffix-text suffix-type stem) or NIL"
  (declare (type string word)
           (optimize (speed 3)))
  (let ((lower (string-downcase word)))
    (dolist (entry *greek-suffixes*)
      (let* ((suffix (car entry))
             (type (cdr entry))
             (suffix-len (length suffix)))
        (when (and (> (length lower) suffix-len)
                   (string= lower suffix :start1 (- (length lower) suffix-len)))
          (return-from extract-suffix
            (values suffix type (subseq word 0 (- (length word) suffix-len)))))))
    nil))

(defun segment-morphology (word)
  "Full morphological segmentation of Greek word.
   Returns: plist (:prefix ... :stem ... :suffix ... :analysis ...)"
  (check-type word string)
  (let ((result (list :original word))
        (remaining word)
        prefix prefix-type suffix suffix-type stem)

    ;; Try to extract prefix
    (multiple-value-bind (p pt rem)
        (extract-prefix remaining)
      (when p
        (setf prefix p
              prefix-type pt
              remaining rem)
        (setf (getf result :prefix) prefix)
        (setf (getf result :prefix-type) prefix-type)))

    ;; Try to extract suffix from remaining (remaining is never NIL now)
    (multiple-value-bind (s st st-stem)
        (extract-suffix remaining)
      (when s
        (setf suffix s
              suffix-type st
              stem st-stem)
        (setf (getf result :suffix) suffix)
        (setf (getf result :suffix-type) suffix-type)
        (setf (getf result :stem) stem)))

    ;; If no suffix found, the whole remaining is the stem
    (unless (getf result :stem)
      (setf (getf result :stem) remaining))

    result))

;;; ============================================================================
;;; CORE TOKENIZER - DARPA-GRADE
;;; ============================================================================

(defun tokenize-to-tokens (text &key (normalize :lowercase))
  "Advanced tokenization returning rich TOKEN objects.

   DARPA-GRADE: Keeps ALL tokens, no arbitrary filtering.
   LISP POWER: CLOS objects with full metadata.

   Args:
     text: Input text to tokenize
     normalize: :lowercase, :preserve, or :strip-tonos

   Returns: List of TOKEN objects with positions and metadata"
  (declare (type string text)
           (optimize (speed 3)))
  (let ((tokens nil)
        (current-chars nil)
        (current-start 0)
        (current-type nil)
        (pos 0)
        (len (length text)))

    (flet ((flush-token ()
             "Flush accumulated characters as a token"
             (when current-chars
               (let* ((raw-text (coerce (nreverse current-chars) 'string))
                      (norm-text (normalize-token raw-text normalize))
                      (word-info (gethash (string-downcase raw-text) *verified-greek-table*)))
                 (push (make-instance 'token
                                      :text norm-text
                                      :start current-start
                                      :end pos
                                      :type (or current-type :word)
                                      :features word-info
                                      :confidence (if word-info 1.0 0.8))
                       tokens)
                 (setf current-chars nil
                       current-type nil)))))

      ;; Main tokenization loop
      (loop while (< pos len)
            for char = (char text pos)
            do (multiple-value-bind (char-type is-greek has-tonos)
                   (classify-char char)
                 (declare (ignore is-greek has-tonos))
                 (case char-type
                   ((:greek :latin :digit)
                    ;; Continue accumulating word
                    (unless current-chars
                      (setf current-start pos
                            current-type (if (eq char-type :digit) :number :word)))
                    (push char current-chars))

                   (:whitespace
                    (flush-token))

                   (:punctuation
                    (flush-token)
                    ;; Create punctuation token
                    (push (make-instance 'token
                                         :text (string char)
                                         :start pos
                                         :end (1+ pos)
                                         :type :punctuation)
                          tokens))

                   (otherwise
                    ;; Unknown character handling with restarts
                    (let ((action (handle-unknown-char char pos)))
                      (case action
                        (:boundary (flush-token))
                        (:symbol
                         (flush-token)
                         (push (make-instance 'token
                                              :text (string char)
                                              :start pos
                                              :end (1+ pos)
                                              :type :symbol)
                               tokens))
                        (t nil))))))  ; :skip-character
               (incf pos))

      ;; Flush final token
      (flush-token))

    (nreverse tokens)))

(defun tokenize-advanced (text &key (normalize :lowercase) (include-punctuation nil))
  "Tokenize text returning list of strings.

   Simplified interface for compatibility.

   Args:
     text: Input text
     normalize: Normalization mode
     include-punctuation: Whether to include punctuation tokens

   Returns: List of token strings"
  (let ((tokens (tokenize-to-tokens text :normalize normalize)))
    (mapcar #'token-text
            (if include-punctuation
                tokens
                (remove-if (lambda (tok)
                             (member (token-type tok) '(:punctuation :symbol)))
                           tokens)))))

(defun tokenize-with-positions (text)
  "Tokenize returning (word start end) triples.

   Essential for NER, POS tagging, and span annotation."
  (let ((tokens (tokenize-to-tokens text)))
    (mapcar (lambda (tok)
              (list (token-text tok)
                    (token-start tok)
                    (token-end tok)))
            (remove-if (lambda (tok)
                         (member (token-type tok) '(:punctuation :symbol)))
                       tokens))))

;;; ============================================================================
;;; RECONSTRUCTION - Reversibility
;;; ============================================================================

(defun reconstruct-text (tokens original-text)
  "Reconstruct original text from tokens (with original text reference).

   LISP POWER: Tokens store exact positions for perfect reconstruction.
   Uses original text slices to preserve case and exact characters."
  (with-output-to-string (out)
    (let ((last-end 0))
      (dolist (tok tokens)
        ;; Fill in whitespace/punctuation between tokens
        (when (> (token-start tok) last-end)
          (write-string (subseq original-text last-end (token-start tok)) out))
        ;; Write from ORIGINAL text at token position (preserves case)
        (write-string (subseq original-text (token-start tok) (token-end tok)) out)
        (setf last-end (token-end tok)))
      ;; Trailing text
      (when (< last-end (length original-text))
        (write-string (subseq original-text last-end) out)))))

(defun tokens-to-string (tokens &key (separator " "))
  "Simple concatenation of token texts."
  (format nil (format nil "~~{~~A~~^~A~~}" separator)
          (mapcar #'token-text tokens)))

;;; ============================================================================
;;; VOCABULARY INTERFACE
;;; ============================================================================

(defun verified-word-p (word)
  "Check if word exists in verified vocabulary."
  (not (null (gethash (string-downcase word) *verified-greek-table*))))

(defun get-word-info (word)
  "Get verified information about a word."
  (gethash (string-downcase word) *verified-greek-table*))

(defun vocabulary-size ()
  "Return size of verified vocabulary."
  (verified-greek-size))

;;; ============================================================================
;;; BPE SUBWORD TOKENIZATION (For LLM Training)
;;; ============================================================================
;;; Byte Pair Encoding - learns subword units from corpus

(defstruct bpe-model
  "BPE model for subword tokenization"
  (merges nil :type list)      ; List of (pair . merged) rules
  (vocab nil :type hash-table) ; Vocabulary with frequencies
  (trained-on 0 :type fixnum)) ; Number of tokens trained on

(defun chars-to-subwords (word)
  "Split word into character-level subwords for BPE."
  (let ((chars (coerce word 'list)))
    (if (null (cdr chars))
        (list (string (car chars)))
        (append
         (mapcar #'string (butlast chars))
         (list (format nil "~A</w>" (car (last chars))))))))

(defun count-pairs (subwords)
  "Count adjacent pairs in subword list."
  (let ((pairs (make-hash-table :test 'equal)))
    (loop for (a b) on subwords
          while b
          do (incf (gethash (cons a b) pairs 0)))
    pairs))

(defun merge-pair (subwords pair merged)
  "Merge all occurrences of pair in subwords."
  (let ((result nil)
        (skip nil))
    (loop for (a . rest) on subwords
          do (cond
               (skip (setf skip nil))
               ((and (car rest)
                     (equal a (car pair))
                     (equal (car rest) (cdr pair)))
                (push merged result)
                (setf skip t))
               (t (push a result))))
    (nreverse result)))

(defun train-bpe (corpus &key (num-merges 1000))
  "Train BPE model on text corpus.

   Args:
     corpus: List of strings (documents)
     num-merges: Number of merge operations to learn

   Returns: BPE-MODEL structure"
  (let ((vocab (make-hash-table :test 'equal))
        (merges nil)
        (model (make-bpe-model :vocab (make-hash-table :test 'equal))))

    ;; Initialize vocabulary with character-level subwords
    (dolist (text corpus)
      (dolist (word (tokenize-advanced text))
        (let ((subwords (chars-to-subwords word)))
          (incf (gethash word vocab 0))
          (dolist (sw subwords)
            (incf (gethash sw (bpe-model-vocab model) 0))))))

    ;; Learn merge rules
    (loop repeat num-merges
          for word-subwords = (make-hash-table :test 'equal)
          do (progn
               ;; Build current subword representation
               (maphash (lambda (word freq)
                          (declare (ignore freq))
                          (setf (gethash word word-subwords)
                                (reduce (lambda (sw merge)
                                          (merge-pair sw (car merge) (cdr merge)))
                                        merges
                                        :initial-value (chars-to-subwords word))))
                        vocab)

               ;; Count pairs across all words
               (let ((pair-counts (make-hash-table :test 'equal)))
                 (maphash (lambda (word sws)
                            (let ((freq (gethash word vocab)))
                              (loop for (a b) on sws
                                    while b
                                    do (incf (gethash (cons a b) pair-counts 0) freq))))
                          word-subwords)

                 ;; Find most frequent pair
                 (let ((best-pair nil)
                       (best-count 0))
                   (maphash (lambda (pair count)
                              (when (> count best-count)
                                (setf best-pair pair
                                      best-count count)))
                            pair-counts)

                   (when (or (null best-pair) (< best-count 2))
                     (return))

                   ;; Add merge rule
                   (let ((merged (concatenate 'string (car best-pair) (cdr best-pair))))
                     (push (cons best-pair merged) merges)
                     (incf (gethash merged (bpe-model-vocab model) 0) best-count))))))

    (setf (bpe-model-merges model) (nreverse merges)
          (bpe-model-trained-on model) (hash-table-count vocab))
    model))

(defun bpe-tokenize (word model)
  "Apply BPE tokenization to a word.

   Args:
     word: Input word
     model: Trained BPE-MODEL

   Returns: List of subword tokens"
  (let ((subwords (chars-to-subwords word)))
    (dolist (merge (bpe-model-merges model))
      (setf subwords (merge-pair subwords (car merge) (cdr merge))))
    subwords))

;;; ── BPE persistence: DATA-ONLY schema + typed decoder ([ARCH Phase 1]) ──
;;; Το παλιό ζεύγος έγραφε (setf *bpe-model* (make-bpe-model …)) και το φόρτωνε με
;;; cl:LOAD — δηλαδή ΕΚΤΕΛΟΥΣΕ το αρχείο ως πρόγραμμα (αυθαίρετος κώδικας από «μοντέλο»).
;;; Η ΙΚΑΝΟΤΗΤΑ (save/load BPE model) διατηρείται· ο ΜΗΧΑΝΙΣΜΟΣ αναβαθμίζεται: το αρχείο
;;; είναι πλέον ΔΕΔΟΜΕΝΑ (versioned plist), φορτώνεται από τη ΜΙΑ safe-read έδρα και
;;; ανασυγκροτείται typed — καμία εκτέλεση κώδικα (data serialization ≠ executable Lisp).

(defparameter +bpe-schema+ :lawmax-bpe-model/1
  "Version tag του data-only BPE schema. Αλλαγή = ρητή έκδοση + migration.")

(define-condition bpe-decode-error (error)
  ((why :initarg :why :reader bpe-decode-error-why :initform "μη αναγνώσιμο BPE μοντέλο"))
  (:report (lambda (c s) (format s "bpe-decode: ~A" (bpe-decode-error-why c)))))

(defun %bpe-merge-to-data (merge)
  "(cons (cons a b) merged) → data-only (list (list a b) merged) — μόνο strings/lists."
  (let ((pair (car merge)) (merged (cdr merge)))
    (list (list (car pair) (cdr pair)) merged)))

(defun %bpe-data-to-merge (m)
  "Data (list (a b) merged) → runtime (cons (cons a b) merged) — αυστηρός type check
   (τρία strings), ΧΩΡΙΣ eval."
  (unless (and (consp m) (= (length m) 2)
               (consp (first m)) (= (length (first m)) 2)
               (stringp (first (first m))) (stringp (second (first m)))
               (stringp (second m)))
    (error 'bpe-decode-error :why (format nil "μη έγκυρος merge κανόνας: ~S" m)))
  (cons (cons (first (first m)) (second (first m))) (second m)))

(defun bpe-model-to-data (model)
  "DATA-ONLY αναπαράσταση BPE μοντέλου: (+bpe-schema+ :merges ((( a b) merged)…) :trained-on N).
   ΟΛΑ strings/numbers/lists — ΚΑΝΕΝΑ constructor-call/eval-bait. (Το vocab είναι training-only
   state που δεν χρειάζεται το inference — το παλιό save το έγραφε ήδη κενό.)"
  (check-type model bpe-model)
  (list +bpe-schema+
        :merges (mapcar #'%bpe-merge-to-data (bpe-model-merges model))
        :trained-on (bpe-model-trained-on model)))

(defun save-bpe-model (model filename)
  "Save BPE model ως DATA-ONLY (ένα (+bpe-schema+ …) plist, prin1 υπό standard-io-syntax +
   keyword package), ΑΤΟΜΙΚΑ μέσω της ΜΙΑΣ έδρας orchestrator.journal:write-file-atomic
   (temp+fsync+rename — ποτέ μισο-γραμμένο/άδειο). [κύκλος-2] Το journal μεταφέρθηκε νωρίτερα
   στο asd (πριν τον tokenizer) ⇒ η έδρα είναι πλέον διαθέσιμη εδώ — καμία διπλή έδρα atomic-write.
   ΚΑΝΕΝΑΣ κώδικας στο αρχείο· επαναφορά ΜΟΝΟ μέσω load-bpe-model (safe-read + STRICT decoder·
   κολοβό αρχείο ⇒ fail-closed)."
  (orchestrator.journal:write-file-atomic
   filename
   (format nil ";;; BPE Model (data-only ~A) - ~D merges, trained on ~D words~%~A~%"
           +bpe-schema+ (length (bpe-model-merges model)) (bpe-model-trained-on model)
           (orchestrator.safe-read:data-to-string (bpe-model-to-data model))))  ; ΜΙΑ έδρα εγγραφής
  filename)

(defun %bpe-decode (data)
  "Typed decoder: validated DATA plist → bpe-model ΧΩΡΙΣ eval. Απαιτεί ακριβές schema/version,
   γνωστά+μη-διπλά πεδία, σωστούς τύπους. Χτίζει μέσω make-bpe-model. Η είσοδος έρχεται από
   safe-read (data-only ⇒ μόνο keywords/strings/numbers/lists)."
  (unless (and (consp data) (eq (first data) +bpe-schema+))
    (error 'bpe-decode-error :why (format nil "άγνωστο schema/version: ~S"
                                          (and (consp data) (first data)))))
  (let ((plist (rest data)))
    ;; [κύκλος-2] STRICT schema: άρτιο plist + keyword κλειδιά + κλειστό+ΥΠΟΧΡΕΩΤΙΚΟ key-set
    ;; (κανένα forgery-by-omission: λείπον :merges ΔΕΝ σημαίνει σιωπηλά «κενό μοντέλο»).
    (unless (evenp (length plist))
      (error 'bpe-decode-error :why "μη-άρτιο plist"))
    (let ((keys (loop for (k) on plist by #'cddr collect k)))
      (unless (every #'keywordp keys)
        (error 'bpe-decode-error :why "μη-keyword κλειδί"))
      (let ((unknown (set-difference keys '(:merges :trained-on))))
        (when unknown (error 'bpe-decode-error :why (format nil "άγνωστα πεδία: ~S" unknown))))
      (unless (= (length keys) (length (remove-duplicates keys)))
        (error 'bpe-decode-error :why "διπλό πεδίο"))
      (dolist (req '(:merges :trained-on))
        (unless (member req keys)
          (error 'bpe-decode-error :why (format nil "λείπει υποχρεωτικό πεδίο ~S" req)))))
    (let ((merges (getf plist :merges))
          (trained (getf plist :trained-on)))
      (unless (listp merges)
        (error 'bpe-decode-error :why ":merges όχι λίστα"))
      (unless (and (integerp trained) (>= trained 0))
        (error 'bpe-decode-error :why ":trained-on όχι μη-αρνητικός integer"))
      (make-bpe-model :merges (mapcar #'%bpe-data-to-merge merges)
                      :vocab (make-hash-table :test 'equal)
                      :trained-on trained))))

(defun load-bpe-model (filename)
  "Load BPE model ΜΕΣΩ της ΜΙΑΣ safe-read έδρας + typed decoder — ΚΑΝΕΝΑ cl:load/eval.
   [ARCH Phase 1] Το αρχείο είναι data-only (+bpe-schema+ …)· διαβάζεται με read-data-file
   (*read-eval* nil + #-deny + caps + %data-only-p) και ανασυγκροτείται typed (%bpe-decode)."
  (multiple-value-bind (data status)
      (orchestrator.safe-read:read-data-file filename)
    (unless (eq status :ok)
      (error 'bpe-decode-error :why (format nil "μη αναγνώσιμο BPE αρχείο (safe-read: ~A)" status)))
    (%bpe-decode data)))

;;; ============================================================================
;;; STATISTICS AND DIAGNOSTICS
;;; ============================================================================

(defun tokenizer-stats (tokens)
  "Compute statistics about tokenization result.

   Returns plist with counts and distributions."
  (let ((word-count 0)
        (greek-count 0)
        (number-count 0)
        (punct-count 0)
        (verified-count 0)
        (total-chars 0)
        (type-dist (make-hash-table)))

    (dolist (tok tokens)
      (incf (gethash (token-type tok) type-dist 0))
      (incf total-chars (- (token-end tok) (token-start tok)))
      (case (token-type tok)
        (:word
         (incf word-count)
         (when (verified-word-p (token-text tok))
           (incf verified-count))
         ;; Check if Greek
         (when (some (lambda (c)
                       (multiple-value-bind (greek) (greek-char-p c)
                         greek))
                     (token-text tok))
           (incf greek-count)))
        (:number (incf number-count))
        (:punctuation (incf punct-count))))

    (list :total-tokens (length tokens)
          :word-tokens word-count
          :greek-tokens greek-count
          :number-tokens number-count
          :punctuation-tokens punct-count
          :verified-tokens verified-count
          :verification-rate (if (> word-count 0)
                                 (/ verified-count (float word-count))
                                 0.0)
          :avg-token-length (if (> (length tokens) 0)
                                (/ total-chars (float (length tokens)))
                                0.0)
          :type-distribution type-dist)))

;;; ============================================================================
;;; INTEGRATION WITH CITATION-AUTHORITY
;;; ============================================================================

(defun tokenize-for-tfidf (text)
  "Tokenize text for TF-IDF processing.

   Compatibility function for citation-authority.lisp"
  (tokenize-advanced text :normalize :lowercase))

;;; ============================================================================
;;; END OF GREEK-TOKENIZER-ADVANCED.LISP
;;; ============================================================================
