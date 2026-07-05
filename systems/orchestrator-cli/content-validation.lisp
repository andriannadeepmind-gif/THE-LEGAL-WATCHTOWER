;;;; systems/orchestrator-cli/content-validation.lisp
;;;; ============================================================================
;;;; LEVEL 2 — CONTENT-SANITY GATE
;;;; ============================================================================
;;;;
;;;; The cryptographic proof certifies the BOX (Merkle root, multi-TSA timestamps,
;;;; JWS, SHACL) — it NEVER inspects whether the legal TEXT is correct. That is how a
;;;; Penal Code carrying the abolished death-penalty wording, empty article bodies and
;;;; extraction artifacts could pass every gate "green". This module closes that gap:
;;;; a content gate that runs BEFORE certification and REFUSES to publish a corpus
;;;; whose text is broken. The box must never again wrap garbage.
;;;;
;;;; CLOS / MOP:
;;;;   ✓ Rules are CLOS classes under CONTENT-RULE; the active set is DISCOVERED from
;;;;     the MOP class graph (sb-mop:class-direct-subclasses) — adding a rule is just
;;;;     `defclass … (content-rule)`, with NO registry to maintain and no edit here.
;;;;   ✓ RULE-VIOLATIONS is a generic dispatched on the rule class.
;;;;   ✓ Severity :block (fails the gate) vs :warn (reported, non-blocking).
;;;;
;;;; Operates on the corpus TRIPLES the CLI already builds — (article-id heading
;;;; content) — so it is decoupled from the internal article CLOS classes and needs
;;;; no new parsing (zero duplication).

(in-package :orchestrator.cli)

;;; ============================================================================
;;; FINDING
;;; ============================================================================

(defstruct (content-finding (:conc-name finding-))
  (article  nil)
  (rule     :rule)
  (severity :warn)          ; :block | :warn
  (message  ""))

;;; ============================================================================
;;; RULE PROTOCOL (CLOS)
;;; ============================================================================

(defclass content-rule ()
  ((id       :initarg :id       :reader rule-id       :initform :rule)
   (severity :initarg :severity :reader rule-severity :initform :warn))
  (:documentation "Base for content-sanity rules. Concrete rules subclass this and
   specialise RULE-VIOLATIONS; they are auto-discovered via the MOP class graph."))

(defgeneric rule-violations (rule article-id heading text)
  (:documentation "Return a list of CONTENT-FINDINGs raised by RULE for one article
   (its ID, HEADING and full TEXT), or NIL when the article satisfies the rule."))

(defmethod rule-violations ((rule content-rule) article-id heading text)
  (declare (ignore rule article-id heading text))
  nil)

(defun %finding (rule id message)
  (make-content-finding :article id :rule (rule-id rule)
                        :severity (rule-severity rule) :message message))

(defun all-content-rules ()
  "Every CONCRETE content rule, discovered from the MOP class graph. Define a new rule
   by subclassing CONTENT-RULE — it is picked up here automatically, no registry."
  (labels ((leaves (class)
             (let ((subs (sb-mop:class-direct-subclasses class)))
               (if subs (mapcan #'leaves subs) (list (make-instance class))))))
    (mapcan #'leaves (sb-mop:class-direct-subclasses (find-class 'content-rule)))))

;;; ============================================================================
;;; CONCRETE RULES — each a class; severity drives whether it BLOCKS a release
;;; ============================================================================

;;; ----------------------------------------------------------------------------
;;; Greek text normalization — the antidote to accent/spacing/case regex bypasses.
;;; Rules that must not be evaded normalize FIRST, then match on the canonical form.
;;; ----------------------------------------------------------------------------

(defparameter *greek-accent-map*
  '((#\ά . #\α) (#\έ . #\ε) (#\ή . #\η) (#\ί . #\ι) (#\ό . #\ο) (#\ύ . #\υ) (#\ώ . #\ω)
    (#\ϊ . #\ι) (#\ϋ . #\υ) (#\ΐ . #\ι) (#\ΰ . #\υ) (#\ς . #\σ))
  "Fold accented/final Greek letters to their base form (accent- and final-sigma
   insensitive matching). Applied after CHAR-DOWNCASE, so uppercase accents (Ά…) fold too.")

(defun %normalize-greek (text)
  "Canonicalize TEXT for evasion-resistant matching: strip diacritics + final sigma,
   downcase, replace NBSP/zero-width with plain space, and collapse whitespace runs
   to one space. Defeats the accent/case/double-space/NBSP bypass class."
  (let ((out (make-string-output-stream))
        (pending-space nil) (started nil))
    (loop for raw across (or text "")
          for dc = (char-downcase raw)
          for ch = (or (cdr (assoc dc *greek-accent-map*)) dc)
          do (cond
               ;; whitespace, NBSP (U+00A0), narrow-NBSP, zero-width → a single space
               ((or (member ch '(#\Space #\Tab #\Newline #\Return))
                    (member (char-code ch) '(#xA0 #x202F #x200B #x200C #x200D #xFEFF)))
                (when started (setf pending-space t)))
               (t (when pending-space (write-char #\Space out) (setf pending-space nil))
                  (write-char ch out) (setf started t))))
    (get-output-stream-string out)))

(defclass empty-body-rule (content-rule) ()
  (:default-initargs :id :empty-body :severity :block))
(defmethod rule-violations ((rule empty-body-rule) id heading text)
  ;; Substance check, not a whitespace check: after normalization (which folds NBSP /
  ;; zero-width to spaces) a body needs ≥1 letter-or-digit. This blocks the
  ;; NBSP-only / «.» / «[…]» artifact bodies that a bare STRING-TRIM lets through.
  (let* ((norm (%normalize-greek text))
         (letters (count-if #'alphanumericp norm)))
    (when (zerop letters)
      (list (%finding rule id (format nil "Άρθρο ~A: ΚΕΝΟ σώμα σε ουσία (τίτλος «~A», μηδέν αλφαριθμητικά)"
                                      id (or heading "")))))))

(defparameter *death-penalty-patterns*
  '("ποιν(?:η|ησ|ην)\\s+(?:του\\s+)?θανατου"                    ; «ποινη [του] θανατου»
    "θανατικ(?:η|ησ|ην|ο|ου|ε|ων|εσ)\\s+ποιν(?:η|ησ|ην|εσ|ων)"  ; «θανατικη ποινη» + κλίσεις
    "εσχατη\\s+των\\s+ποινων")                                   ; ευφημισμός
  "Every attested death-penalty phrasing (matched on NORMALIZED text: accent/case/
   spacing/NBSP-insensitive). Bare «θάνατος» is deliberately excluded (lawful in
   homicide articles).")

(defparameter *death-penalty-abolition-cues*
  '(;; abolition / negation — the mention is being repealed or forbidden
    "δεν" "καταργ" "απαγορ" "ουδεποτε" "ουτε" "μη επιβ"
    ;; EXTRADITION / foreign-law context — the current codes refer to a foreign
    ;; state's death penalty as a GROUND TO REFUSE extradition (ΚΠοινΔ art. 438:
    ;; «αν στο κράτος που ζητά την έκδοση προβλέπεται … η ποινή του θανάτου»), never
    ;; as a penalty Greek law imposes. These markers identify that protective context.
    "εκδο" "εκζητ" "διωχθ" "αλλοδαπ")
  "Cues that, near a death-penalty phrase (or in the article heading), mark it as
   CURRENT law — an abolition clause or a foreign-law extradition safeguard — not
   stale prescriptive Greek law. Their presence suppresses the finding.")

(defclass abolished-penalty-rule (content-rule) ()
  (:default-initargs :id :abolished-death-penalty :severity :block))
(defmethod rule-violations ((rule abolished-penalty-rule) id heading text)
  ;; Fires only on PRESCRIPTIVE death-penalty text (Greek law imposing it). A match
  ;; whose article heading or surrounding window carries an abolition/extradition cue
  ;; is current law and is skipped — so the rule does not false-positive on the
  ;; Constitution's abolition clause or the ΚΠοινΔ extradition safeguard.
  (let* ((norm (%normalize-greek text))
         (nhead (%normalize-greek (or heading "")))
         ;; an extradition/abolition heading (e.g. «απαγορευση της εκδοσης») clears
         ;; the whole article — every death-penalty mention in it is protective.
         (head-clears (some (lambda (cue) (search cue nhead)) *death-penalty-abolition-cues*)))
    (when (and (not head-clears)
               (plusp (length norm))
               (loop for pat in *death-penalty-patterns*
                     thereis
                     (loop for (start end) on (cl-ppcre:all-matches pat norm) by #'cddr
                           for wlo = (max 0 (- start 60))
                           for whi = (min (length norm) (+ (or end start) 45))
                           for window = (subseq norm wlo whi)
                           ;; prescriptive iff NO abolition/extradition cue nearby
                           thereis (notany (lambda (cue) (search cue window))
                                           *death-penalty-abolition-cues*))))
      (list (%finding rule id (format nil "Άρθρο ~A: φρασεολογία ΘΑΝΑΤΙΚΗΣ ΠΟΙΝΗΣ (καταργημένη) — παλιό κείμενο, όχι το ισχύον" id))))))

(defclass editorial-bracket-rule (content-rule) ()
  (:default-initargs :id :editorial-brackets :severity :warn))
(defmethod rule-violations ((rule editorial-bracket-rule) id heading text)
  (declare (ignore heading))
  (when (and text (cl-ppcre:scan "\\[[^\\]]{3,}\\]" text))
    (list (%finding rule id (format nil "Άρθρο ~A: αφημένες συντακτικές αγκύλες [ … ]" id)))))

(defclass unbalanced-quote-rule (content-rule) ()
  (:default-initargs :id :unbalanced-quotes :severity :warn))
(defmethod rule-violations ((rule unbalanced-quote-rule) id heading text)
  (declare (ignore heading))
  (when (and text (/= (count #\« text) (count #\» text)))
    (list (%finding rule id (format nil "Άρθρο ~A: ασύμμετρα εισαγωγικά « » (artifact ενσωμάτωσης τροποποίησης)" id)))))

(defclass punctuation-artifact-rule (content-rule) ()
  (:default-initargs :id :punctuation-artifacts :severity :warn))
(defmethod rule-violations ((rule punctuation-artifact-rule) id heading text)
  (declare (ignore heading))
  (when (and text (or (cl-ppcre:scan "\\.\\s*\\." text)        ; «. .» / «..»
                      (cl-ppcre:scan "\"\\d+\"\\." text)))     ; «"1".» αντί «1.»
    (list (%finding rule id (format nil "Άρθρο ~A: artifact στίξης (διπλή τελεία ή «\"N\".»)" id)))))

;;; ============================================================================
;;; THE GATE
;;; ============================================================================

(defun %content->text (content)
  "Normalise an article's content (a string, or a list of paragraph strings) to one
   string for rule matching."
  (cond ((stringp content) content)
        ((listp content)   (format nil "~{~A~^~%~}" content))
        ((null content)    "")
        (t (princ-to-string content))))

(defun validate-corpus-content (triples)
  "Run every content rule over TRIPLES (each (article-id heading content)). Returns the
   flat list of CONTENT-FINDINGs, most blocking issues first (stable per article)."
  (let ((rules (all-content-rules)) (out '()))
    (dolist (tr triples)
      (destructuring-bind (id heading content) tr
        (let ((text (%content->text content)))
          (dolist (rule rules)
            (dolist (f (rule-violations rule id heading text))
              (push f out))))))
    (let ((findings (nreverse out)))
      (stable-sort findings (lambda (a b) (and (eq a :block) (not (eq b :block))))
                   :key #'finding-severity))))

(defun content-gate (triples &key (label ""))
  "Validate the corpus content and print a per-article report. Returns
   (values blocking-count warning-count) — a positive blocking-count must fail the
   release (the box must not certify broken legal text)."
  (let* ((findings (validate-corpus-content triples))
         (blocks (count :block findings :key #'finding-severity))
         (warns  (count :warn  findings :key #'finding-severity)))
    (if findings
        (progn
          (format t "~%── CONTENT GATE: ~A — ~D blocking, ~D προειδοποιήσεις ──~%"
                  label blocks warns)
          (dolist (f findings)
            (format t "  ~A [~A] ~A~%"
                    (if (eq (finding-severity f) :block) "✗" "⚠")
                    (finding-rule f) (finding-message f))))
        (format t "~%── CONTENT GATE: ~A ✓ καθαρό περιεχόμενο ──~%" label))
    (values blocks warns)))
