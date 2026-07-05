;;;; systems/orchestrator-epistemic/primary-anchor.lisp
;;;; ============================================================================
;;;; LEVEL 1 — PROVENANCE ANCHOR TO THE PRIMARY SOURCE (ΦΕΚ)
;;;; ============================================================================
;;;;
;;;; The corpus already carries an INTERNAL proof (per-article SHA-256 + a corpus
;;;; Merkle root, multi-TSA timestamped, JWS-signed). That proves "this text is what
;;;; WE published". It does NOT yet prove "this text is what the STATE published in
;;;; the ΦΕΚ". A PRIMARY-ANCHOR closes that gap with TWO bound digests:
;;;;   • SOURCE-DIGEST     — SHA-256 of the ΦΕΚ's own bytes (anyone hashes the gazette).
;;;;   • EXTRACTION-DIGEST — SHA-256 of the ordered SERVED article texts produced by a
;;;;     DETERMINISTIC extraction (EXTRACTION-METHOD) of those very bytes. The served
;;;;     law is provably the derivation of the primary, not an independent byte stream
;;;;     that merely cites it: a third party re-runs the named adapter over the ΦΕΚ file
;;;;     and MUST reproduce EXTRACTION-DIGEST, and because the served proofs' leaves ARE
;;;;     those same article texts the chain primary bytes -> adapter -> served text ->
;;;;     leaves -> Merkle root -> signature is recomputable end to end. Truth derivable
;;;;     from the primary source, not asserted. (The former model hashed only the source
;;;;     file and asserted it against its own hash — a tautology binding nothing to the
;;;;     served text. Removed.)
;;;;
;;;; NO DUPLICATION — reuses the module's existing primitives:
;;;;   • compute-sha256-file / compute-sha256-string  (merkle-tree.lisp, same package)
;;;;   • the ΦΕΚ reference is supplied as a parsed (:series :number :year) plist
;;;;     (the caller already has orchestrator.legal-id:parse-fek-ref), so this module
;;;;     stays dependency-clean and does not re-implement gazette parsing or hashing.
;;;;
;;;; CLOS / MOP:
;;;;   ✓ IMMUTABLE-CLASS metaclass (sb-mop) — a proof anchor is tamper-evident at the
;;;;     OBJECT level: once a slot is bound at construction it can never be re-set.
;;;;     This is the right CL mechanism (a class invariant, not a runtime flag), in the
;;;;     spirit of the raw-text adapter sealing its accumulator via CHANGE-CLASS.
;;;;   ✓ Reader-only protocol (no writers) — provenance is set once, read forever.
;;;;   ✓ Typed condition hierarchy (primary-anchor-error → anchor-digest-mismatch).
;;;;   ✓ PRINT-OBJECT — self-documenting REPL representation.

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; MOP — IMMUTABLE-CLASS: instances reject slot mutation after construction
;;;
;;; sb-mop is SBCL-native (the whole engine is SBCL-only), so no new dependency is
;;; pulled in. The :before method on (setf slot-value-using-class) lets the single
;;; construction-time binding through (slot still unbound) and rejects every later
;;; write — the canonical Common Lisp pattern for an immutable object.
;;; ============================================================================

(defclass immutable-class (standard-class) ()
  (:documentation "Metaclass for tamper-evident objects: a slot may be bound ONCE
   (at construction); any later mutation signals IMMUTABLE-SLOT-ERROR."))

(defmethod sb-mop:validate-superclass ((class immutable-class) (super standard-class))
  t)

(define-condition immutable-slot-error (error)
  ((slot :initarg :slot :reader immutable-slot-error-slot :initform nil))
  (:report (lambda (c s)
             (format s "primary-anchor: immutable slot ~A cannot be re-set after ~
                        construction (tamper attempt)"
                     (immutable-slot-error-slot c)))))

(defmethod (setf sb-mop:slot-value-using-class) :before
    (new-value (class immutable-class) object slotd)
  (declare (ignore new-value object))
  (when (sb-mop:slot-boundp-using-class class object slotd)
    (error 'immutable-slot-error :slot (sb-mop:slot-definition-name slotd))))

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition primary-anchor-error (error)
  ((message :initarg :message :reader primary-anchor-error-message :initform ""))
  (:report (lambda (c s) (format s "primary-anchor: ~A" (primary-anchor-error-message c)))))

(define-condition anchor-digest-mismatch (primary-anchor-error)
  ((expected :initarg :expected :reader mismatch-expected :initform nil)
   (actual   :initarg :actual   :reader mismatch-actual   :initform nil))
  (:report (lambda (c s)
             (format s "primary-anchor: source digest MISMATCH — the candidate bytes ~
                        are NOT the anchored primary source.~%  expected: ~A~%  actual:   ~A"
                     (mismatch-expected c) (mismatch-actual c)))))

;;; ============================================================================
;;; THE ANCHOR — immutable provenance object
;;; ============================================================================

(defclass primary-anchor ()
  ((fek-series   :initarg :fek-series   :reader anchor-fek-series   :initform nil)
   (fek-number   :initarg :fek-number   :reader anchor-fek-number   :initform nil)
   (fek-year     :initarg :fek-year     :reader anchor-fek-year     :initform nil)
   (source-uri   :initarg :source-uri   :reader anchor-source-uri   :initform nil)
   (source-digest :initarg :source-digest :reader anchor-source-digest :initform nil)
   ;; The DERIVATION binding (this is what makes the anchor honest): the SHA-256 over
   ;; the ordered served article texts that a DETERMINISTIC extraction of the primary
   ;; bytes produces. source-digest binds "these are the ΦΕΚ bytes"; extraction-digest
   ;; binds "the served text is exactly what running EXTRACTION-METHOD over those bytes
   ;; yields". A third party re-runs the documented adapter on the ΦΕΚ file and MUST
   ;; reproduce this — truth derivable from the primary source, not asserted.
   (extraction-digest :initarg :extraction-digest :reader anchor-extraction-digest :initform nil)
   (extraction-method :initarg :extraction-method :reader anchor-extraction-method :initform nil)
   (algorithm    :initarg :algorithm    :reader anchor-algorithm    :initform "sha-256")
   (locator      :initarg :locator      :reader anchor-locator      :initform nil)
   (retrieved-at :initarg :retrieved-at :reader anchor-retrieved-at :initform nil))
  (:metaclass immutable-class)
  (:documentation "A provision's verifiable link to the PRIMARY publication: the
   SHA-256 of the authentic ΦΕΚ bytes (SOURCE-DIGEST), the SHA-256 of the deterministic
   extraction of the served text from those bytes (EXTRACTION-DIGEST + EXTRACTION-METHOD),
   the public SOURCE-URI and an in-document LOCATOR. Immutable — once built it cannot be
   mutated (tamper-evident)."))

(defmethod print-object ((a primary-anchor) stream)
  (print-unreadable-object (a stream :type t)
    (format stream "~A~@[ @~A~] ~A"
            (anchor-fek-citation a)
            (anchor-locator a)
            (let ((d (anchor-source-digest a)))
              (if (and (stringp d) (> (length d) 23)) (subseq d 0 23) d)))))

;;; ============================================================================
;;; PROTOCOL
;;; ============================================================================

(defun anchor-fek-ref (anchor)
  "The primary gazette reference as a (:series :number :year) plist."
  (list :series (anchor-fek-series anchor)
        :number (anchor-fek-number anchor)
        :year   (anchor-fek-year anchor)))

(defun anchor-fek-citation (anchor)
  "Human-readable ΦΕΚ citation, e.g. \"ΦΕΚ Α' 182/1985\" (blanks omitted gracefully)."
  (let ((s (anchor-fek-series anchor)) (n (anchor-fek-number anchor)) (y (anchor-fek-year anchor)))
    (string-trim " " (format nil "ΦΕΚ~@[ ~A'~]~@[ ~A~]~@[/~A~]" s n y))))

(defun %articles-canonical-string (articles)
  "Deterministic, order-preserving serialization of ARTICLES — a list of (ID . TEXT)
   conses (ID a string/number, TEXT the served canonical text). Each record is
   ID US TEXT RS (ASCII Unit/Record separators, U+001F/U+001E — control chars that
   never occur in legal text), so distinct article boundaries can never collide. This
   is the exact byte-stream the extraction-digest is taken over; a verifier who runs
   the documented adapter over the primary bytes rebuilds the same list and hashes to
   the same value."
  (with-output-to-string (s)
    (dolist (a articles)
      (format s "~A~C~A~C"
              (car a) (code-char 31) (or (cdr a) "") (code-char 30)))))

(defun compute-extraction-digest (articles)
  "SHA-256 (hex) over the canonical serialization of the ordered served ARTICLES.
   Reuses compute-sha256-string — hashing is never re-implemented here."
  (compute-sha256-string (%articles-canonical-string articles)))

(defun make-primary-anchor (&key fek source-uri source-file source-string
                                 articles extraction-method locator retrieved-at)
  "Construct an immutable PRIMARY-ANCHOR.
   FEK          — (:series :number :year) plist of the gazette that published this text.
   SOURCE-FILE / SOURCE-STRING — the AUTHENTIC primary bytes the SOURCE-DIGEST is taken
                  over (reusing compute-sha256-*; hashing is never re-implemented here).
   ARTICLES     — the ordered served (ID . TEXT) list; when supplied, its
                  EXTRACTION-DIGEST is computed, binding the proof to the SERVED text
                  (the derivation from the primary), not merely to the source file.
   EXTRACTION-METHOD — identifier of the deterministic adapter that produced ARTICLES
                  from the primary bytes (e.g. \"docx-adapter+raw-text-fsm@1\").
   SOURCE-URI   — public locator of the primary (e.g. the ΦΕΚ blob URL).
   LOCATOR      — pins the provision inside the source (article id / byte range).
   Signals PRIMARY-ANCHOR-ERROR when no source bytes are given."
  (let ((digest (cond (source-file   (compute-sha256-file source-file))
                      (source-string (compute-sha256-string source-string))
                      (t (error 'primary-anchor-error
                                :message "make-primary-anchor: need :source-file or :source-string")))))
    (make-instance 'primary-anchor
                   :fek-series (getf fek :series)
                   :fek-number (getf fek :number)
                   :fek-year   (getf fek :year)
                   :source-uri source-uri
                   :source-digest digest
                   :extraction-digest (when articles (compute-extraction-digest articles))
                   :extraction-method extraction-method
                   :locator locator
                   :retrieved-at retrieved-at)))

(defun %candidate-digest (file string)
  (cond (file   (compute-sha256-file file))
        (string (compute-sha256-string string))
        (t (error 'primary-anchor-error :message "need :file or :string to verify"))))

(defun anchor-verified-p (anchor &key file string articles)
  "Level-1 verification primitive. With :FILE/:STRING, T iff the candidate bytes
   reproduce SOURCE-DIGEST (the primary is authentic). With :ARTICLES, T iff the
   candidate served (ID . TEXT) list reproduces EXTRACTION-DIGEST (the served text is
   the genuine derivation from the primary — the honest binding). Pure, no network."
  (cond (articles (and (anchor-extraction-digest anchor)
                       (string= (anchor-extraction-digest anchor)
                                (compute-extraction-digest articles))))
        (t (string= (anchor-source-digest anchor) (%candidate-digest file string)))))

(defun anchor-assert (anchor &key file string articles)
  "Like ANCHOR-VERIFIED-P but signals ANCHOR-DIGEST-MISMATCH on failure — the proof
   gate (a release must not publish a corpus whose served text does not reproduce the
   anchor's EXTRACTION-DIGEST, nor whose primary bytes do not reproduce SOURCE-DIGEST).
   Passing :ARTICLES checks the DERIVATION binding — the non-tautological check that
   the served law really is what the primary yields."
  (let* ((articlesp (and articles t))
         (expected  (if articlesp (anchor-extraction-digest anchor) (anchor-source-digest anchor)))
         (actual    (if articlesp (compute-extraction-digest articles) (%candidate-digest file string))))
    (when (and articlesp (null expected))
      (error 'primary-anchor-error
             :message "anchor-assert: no extraction-digest recorded (anchor was built without :articles)"))
    (if (string= expected actual)
        t
        (error 'anchor-digest-mismatch
               :message (if articlesp "served-text derivation verification failed"
                            "primary-source verification failed")
               :expected expected
               :actual actual))))

(defun anchor->plist (anchor)
  "Serialization-ready plist — the provenance the per-provision proof embeds. The
   JSON-LD / PROV-O projection of this is done by the proof-emission wiring, reusing
   the existing jonathan/RDF machinery (kept out of this pure data model)."
  (list :fek              (anchor-fek-citation anchor)
        :fek-series        (anchor-fek-series anchor)
        :fek-number        (anchor-fek-number anchor)
        :fek-year          (anchor-fek-year anchor)
        :source-uri        (anchor-source-uri anchor)
        :source-digest     (anchor-source-digest anchor)
        :extraction-digest (anchor-extraction-digest anchor)
        :extraction-method (anchor-extraction-method anchor)
        :algorithm         (anchor-algorithm anchor)
        :locator           (anchor-locator anchor)
        :retrieved-at      (anchor-retrieved-at anchor)))
