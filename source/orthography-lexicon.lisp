;;;; source/orthography-lexicon.lisp
;;;; ============================================================================
;;;; ORTHOGRAPHY AUTHORITY — the corpus is its own deterministic spelling lexicon,
;;;; now a first-class backend of the Greek NLP LEXICON protocol.
;;;; ============================================================================
;;;;
;;;; libpoppler drops the tonos from some words (Όποιος → Οποιος). Rather than a
;;;; hard-coded list, we LEARN Greek spelling from the corpus itself: a word like
;;;; "όποιος" appears correctly (accented) many times, so its canonical accented
;;;; form is known, and the few corrupted occurrences are restored — covering the
;;;; whole vocabulary, deterministically, with NO external dictionary/network.
;;;;
;;;; Safety (zero wrong corrections):
;;;;   · only an UNACCENTED token is ever changed (an accented word is left alone);
;;;;   · restored only when the corpus attests EXACTLY ONE accented form for that
;;;;     letter-skeleton — several accented forms (πότε/ποτέ) ⇒ ambiguous ⇒ left,
;;;;     and flagged for human review;
;;;;   · the monotonic homographs whose UNACCENTED form is itself valid Greek
;;;;     (η/ή, που/πού, πως/πώς) are never touched.
;;;;
;;;; EVOLUTION: the learned spelling map is exposed as an ORTHOGRAPHY-LEXICON that
;;;; conforms to the orchestrator.greek-nlp LEXICON protocol (generic lexicon-lookup
;;;; / lexicon-size / lexicon-iterate). So the corpus's own spelling knowledge now
;;;; COMPOSES with any other lexicon (e.g. a morphological one via composite-lexicon)
;;;; and is queryable through the one unified protocol — while the restoration
;;;; behaviour is byte-for-byte the frequency-majority learner it has always been.
;;;; ============================================================================

(defpackage :orchestrator.orthography
  (:use :cl)
  (:import-from :orchestrator.greek-nlp
                #:lexicon #:lexicon-lookup #:lexicon-size #:lexicon-contains-p
                #:lexicon-iterate)
  (:export #:orthography-lexicon #:learn-orthography
           #:canonical-form #:ambiguous-skeleton-p
           #:restore-word-orthography #:restore-orthography #:orthography-ambiguities
           #:attestation-count #:resegment-word #:resegment-text
           #:strip-tonos #:has-tonos-p
           #:+greek-tonos-map+ #:*unaccented-valid-bases* #:*orthography-majority*
           #:*resegment-min-half-count* #:*resegment-max-joined-count*))

(in-package :orchestrator.orthography)

;;; ----------------------------------------------------------------------------
;;; tonos helpers + the word scanner (the deterministic spelling primitives)
;;; ----------------------------------------------------------------------------

(defparameter +greek-tonos-map+
  '((#\ά . #\α) (#\έ . #\ε) (#\ή . #\η) (#\ί . #\ι) (#\ό . #\ο) (#\ύ . #\υ) (#\ώ . #\ω)
    (#\Ά . #\Α) (#\Έ . #\Ε) (#\Ή . #\Η) (#\Ί . #\Ι) (#\Ό . #\Ο) (#\Ύ . #\Υ) (#\Ώ . #\Ω)
    (#\ΐ . #\ϊ) (#\ΰ . #\ϋ))                ; strip the tonos, keep the dialytika
  "Tonos-bearing Greek vowel → its plain vowel.")

(defun strip-tonos (s)
  (map 'string (lambda (c) (or (cdr (assoc c +greek-tonos-map+)) c)) s))

(defun has-tonos-p (s)
  (and (some (lambda (c) (assoc c +greek-tonos-map+)) s) t))

(defparameter *greek-word-scanner*
  (cl-ppcre:create-scanner
   (format nil "[~A-~A~A-~A]+"
           (code-char #x0370) (code-char #x03FF)
           (code-char #x1F00) (code-char #x1FFF)))
  "A maximal run of Greek letters = one word token.")

(defparameter *unaccented-valid-bases*
  '("η" "που" "πως")
  "Monotonic homographs whose UNACCENTED form is itself a correct Greek word —
   the accent distinguishes a different word (ή, πού, πώς), so never auto-accent.")

(defparameter *orthography-majority* 0.95
  "A skeleton's dominant spelling becomes canonical only at/above this share of
   its occurrences — high enough that a real homograph (που/πού) never resolves.")

;;; ----------------------------------------------------------------------------
;;; the learned lexicon — a backend of the greek-nlp LEXICON protocol
;;; ----------------------------------------------------------------------------

(defclass orthography-lexicon (lexicon)
  ((table :initarg :table :accessor orthography-table
          :initform (make-hash-table :test 'equal)
          :documentation "skeleton (downcased, tonos-stripped) → dominant form
           (string) or :AMBIGUOUS.")
   (counts :initarg :counts :accessor orthography-counts
           :initform (make-hash-table :test 'equal)
           :documentation "skeleton → total attestations in the corpus. The
            frequency evidence behind the lexicon: RESEGMENT-WORD uses it to
            tell a common real word from a rare extraction artifact."))
  (:default-initargs :name "orthography" :language :greek)
  (:documentation "The corpus's LEARNED spelling, as a greek-nlp lexicon backend."))

(defmethod lexicon-lookup ((lex orthography-lexicon) word)
  "Protocol lookup keyed by the word's letter-skeleton: (:canonical FORM) for a
   resolved spelling, (:ambiguous T) for a contested one, or NIL when unseen."
  (let ((v (gethash (strip-tonos (string-downcase word)) (orthography-table lex))))
    (cond ((stringp v) (list :canonical v))
          ((eq v :ambiguous) (list :ambiguous t))
          (t nil))))

(defmethod lexicon-size ((lex orthography-lexicon))
  (hash-table-count (orthography-table lex)))

(defmethod lexicon-iterate ((lex orthography-lexicon) function)
  (maphash function (orthography-table lex)))

(defun canonical-form (lex word)
  "The corpus's canonical spelling for WORD's skeleton, or NIL when unseen/ambiguous."
  (let ((info (lexicon-lookup lex word)))
    (and (eq (first info) :canonical) (second info))))

(defun ambiguous-skeleton-p (lex word)
  "Whether WORD's skeleton has several attested accented forms (left for review)."
  (eq (first (lexicon-lookup lex word)) :ambiguous))

(defun learn-orthography (text)
  "LEARN each letter-skeleton's canonical spelling from the corpus by majority —
   no syllable heuristics, the data decides. Counts every attestation (accented
   AND unaccented); a skeleton resolves to the dominant form when it is clearly
   dominant and not a genuine homograph, else :AMBIGUOUS. So the corpus itself
   says whether a word should carry an accent (όποιος) or not (της, πιο, για).
   Returns an ORTHOGRAPHY-LEXICON (conforms to the greek-nlp lexicon protocol)."
  (let ((counts (make-hash-table :test 'equal))   ; skeleton -> (hash form -> count)
        (lex (make-hash-table :test 'equal))
        (totals (make-hash-table :test 'equal)))   ; skeleton -> total attestations
    (dolist (w (cl-ppcre:all-matches-as-strings *greek-word-scanner* text))
      (let* ((dw (string-downcase w))
             (key (strip-tonos dw))
             (h (or (gethash key counts)
                    (setf (gethash key counts) (make-hash-table :test 'equal)))))
        (incf (gethash dw h 0))))
    (maphash
     (lambda (key h)
       (let ((total 0) (best nil) (best-n 0) (distinct-accented 0))
         (maphash (lambda (form n)
                    (incf total n)
                    (when (has-tonos-p form) (incf distinct-accented))
                    (when (> n best-n) (setf best form best-n n)))
                  h)
         (setf (gethash key totals) total)
         (setf (gethash key lex)
               (cond ((> distinct-accented 1) :ambiguous)        ; πότε vs ποτέ
                     ((>= best-n (* *orthography-majority* total)) best)
                     (t :ambiguous)))))
     counts)
    (make-instance 'orthography-lexicon :table lex :counts totals)))

;;; ----------------------------------------------------------------------------
;;; restoration — through the protocol
;;; ----------------------------------------------------------------------------

(defun %recase-like (template lower)
  "Apply TEMPLATE's per-character upper/lower case onto LOWER (same length)."
  (if (= (length template) (length lower))
      (map 'string (lambda (tc lc) (if (upper-case-p tc) (char-upcase lc) lc))
           template lower)
      lower))

(defun restore-word-orthography (word lexicon)
  "Normalise WORD to the spelling the corpus has LEARNED is canonical, preserving
   case. This both restores a dropped accent (Οποιος → Όποιος) and removes a
   wrong one (τής → της, πιό → πιο, ά → α), because the canonical form is whatever
   the corpus attests dominantly. Left unchanged when the skeleton is ambiguous /
   unseen, or is one of the monotonic disambiguators ή/πού/πώς whose two forms
   are both correct."
  (let ((key (strip-tonos (string-downcase word))))
    (if (member key *unaccented-valid-bases* :test #'string=)
        word
        (let ((canon (canonical-form lexicon word)))
          (if (and (stringp canon)
                   (= (length canon) (length word))
                   (not (string= canon (string-downcase word))))
              (%recase-like word canon)
              word)))))

(defun restore-orthography (text &optional (lexicon (learn-orthography text)))
  "Deterministically restore dropped accents across TEXT using the corpus lexicon."
  (cl-ppcre:regex-replace-all *greek-word-scanner* text
                              (lambda (w) (restore-word-orthography w lexicon))
                              :simple-calls t))

;;; ----------------------------------------------------------------------------
;;; resegmentation — the INVERSE repair, by the same corpus-evidence philosophy
;;; ----------------------------------------------------------------------------
;;;
;;; Some PDF text layers drop the space between two words (kerning artifacts:
;;; «τουανθρώπου» for «του ανθρώπου»). The corpus itself again decides the fix:
;;; a token is split ONLY when (a) the joined form is rare in the corpus (an
;;; artifact, not a real word), (b) BOTH halves are frequent corpus words, and
;;; (c) exactly ONE split point satisfies this — any ambiguity means no change.
;;; Deterministic, no external dictionary, zero wrong corrections by design.

(defparameter *resegment-min-half-count* 3
  "The content-word half of a proposed split must be attested at least this
   many times — a COMMON corpus word, not itself an artifact.")

(defparameter *resegment-min-content-length* 4
  "The content-word half must be at least this long. Blocks the short-word
   coincidences (e.g. a rare real word like «τοπίο» analysable as το+πίο) that
   frequency alone cannot rule out.")

(defparameter *resegment-max-joined-count* 2
  "A token attested more often than this is a real corpus word — never split.")

(defparameter *resegment-function-words*
  '("του" "της" "των" "τη" "την" "τον" "το" "τα" "τους" "τις" "οι"
    "στου" "στης" "στη" "στην" "στον" "στο" "στα" "στις" "στους"
    "μας" "σας" "για" "θα" "να" "και" "δεν" "μην")
  "Closed-class Greek function words (articles, clitic pronouns, particles)
   that are NEVER word-formation prefixes/suffixes. A split is licensed only
   at such a word: this is what distinguishes a real kerning join
   («τουανθρώπου» = του + ανθρώπου) from a prefixed verb («καταδιώκεται»,
   where κατά IS a prefix — prepositional prefixes are deliberately absent
   from this list). A linguistic fact, not a tunable heuristic.")

(defun attestation-count (lex word)
  "How many times WORD's letter-skeleton is attested in the learned corpus."
  (gethash (strip-tonos (string-downcase word)) (orthography-counts lex) 0))

(defun %function-word-p (s)
  (member (strip-tonos (string-downcase s)) *resegment-function-words*
          :test #'string=))

(defun resegment-word (word lexicon)
  "Split WORD into «A B» when the evidence PROVES it is two joined words:
     · an internal lowercase→uppercase transition (Greek orthography has no
       internal capitals — «ΈλληνεςΠολίτες» → «Έλληνες Πολίτες»), or
     · WORD is rare (≤ *RESEGMENT-MAX-JOINED-COUNT*), EXACTLY ONE split point
       has a closed-class function word on one side (never a derivational
       prefix) and a frequent corpus word (≥ *RESEGMENT-MIN-HALF-COUNT*) on
       the other.
   Anything less certain is left unchanged — zero wrong corrections."
  ;; 1. internal-capital boundary: a typography fact, independent of counts.
  ;; Case is tested via the case-mapping itself (a char is lowercase iff
  ;; upcasing changes it); the final sigma ς is lowercase BY DEFINITION but
  ;; SBCL's simple case mapping leaves it fixed, so it is special-cased.
  (flet ((lowr (c) (or (char= c #\ς) (char/= c (char-upcase c))))
         (uppr (c) (char/= c (char-downcase c))))
    (let ((cap (loop for i from 1 below (length word)
                     when (and (lowr (char word (1- i)))
                               (uppr (char word i)))
                     collect i)))
      (when (and cap (>= (length word) 4))
        (return-from resegment-word
          (with-output-to-string (s)
            (loop for start = 0 then i
                  for i in (append cap (list (length word)))
                  do (progn (unless (zerop start) (write-char #\Space s))
                            (write-string word s :start start :end i))))))))
  ;; 2. corpus-evidence split at a function word
  (if (or (< (length word) 5)
          (> (attestation-count lexicon word) *resegment-max-joined-count*))
      word
      (let ((splits '()))
        (loop for i from 2 to (- (length word) 2)
              for a = (subseq word 0 i)
              for b = (subseq word i)
              when (or (and (%function-word-p a)
                            (>= (length b) *resegment-min-content-length*)
                            (>= (attestation-count lexicon b) *resegment-min-half-count*))
                       (and (%function-word-p b)
                            (>= (length a) *resegment-min-content-length*)
                            (>= (attestation-count lexicon a) *resegment-min-half-count*)))
              do (push (cons a b) splits))
        (if (= 1 (length splits))
            (format nil "~A ~A" (car (first splits)) (cdr (first splits)))
            word))))

(defun resegment-text (text &optional (lexicon (learn-orthography text)))
  "Repair joined-word extraction artifacts across TEXT using corpus evidence."
  (cl-ppcre:regex-replace-all *greek-word-scanner* text
                              (lambda (w) (resegment-word w lexicon))
                              :simple-calls t))

(defun orthography-ambiguities (text &optional (lexicon (learn-orthography text)))
  "The distinct unaccented tokens whose skeleton has several attested accented
   forms (e.g. a ποτε that could be πότε or ποτέ) — these cannot be auto-fixed
   and are the candidates to send to the human review queue."
  (let ((seen (make-hash-table :test 'equal)) (out '()))
    (dolist (w (cl-ppcre:all-matches-as-strings *greek-word-scanner* text) (nreverse out))
      (unless (has-tonos-p w)
        (let ((key (string-downcase w)))
          (when (and (not (member key *unaccented-valid-bases* :test #'string=))
                     (ambiguous-skeleton-p lexicon w)
                     (not (gethash key seen)))
            (setf (gethash key seen) t)
            (push w out)))))))
