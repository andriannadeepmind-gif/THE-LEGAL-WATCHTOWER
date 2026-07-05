;;;; systems/orchestrator-omega-modules/frbr-consistency-validator.lisp
;;;; Cross-Layer FRBR Consistency Validator - ZERO TOLERANCE
;;;; ΟΜΕΓΑ-LEVEL: Military-grade validation
;;;;
;;;; Validates complete FRBR stack consistency across all layers.
;;;; FAILS FAST - Any inconsistency = immediate error, no output.
;;;;
;;;; Checks:
;;;;   - URI pattern consistency across all layers
;;;;   - Article number consistency
;;;;   - Language tag consistency
;;;;   - FRBR chain integrity (Work → Expression → Manifestation → Format)
;;;;   - Article Root linkage (all layers point to same Article)
;;;;   - Required slots populated
;;;;   - ELI identifier format compliance

(in-package :orchestrator.spec)

;;; ============================================================
;;; MAIN VALIDATION ENTRY POINT
;;; ============================================================

(defun validate-frbr-stack (article-root work expression manifestation formats)
  "Validate complete FRBR stack for consistency

   Arguments:
     article-root:  frbr-article-root instance
     work:          frbr-work instance
     expression:    frbr-expression instance
     manifestation: frbr-manifestation instance
     formats:       List of frbr-format instances

   Returns:
     T if valid, signals error if any inconsistency found

   Validation Strategy:
     - FAIL FAST: First error stops validation
     - COMPREHENSIVE: Checks all critical properties
     - DETERMINISTIC: Same input always produces same result"

  (validate-article-root article-root)
  (validate-work work article-root)
  (validate-expression expression work article-root)
  (validate-manifestation manifestation expression article-root)
  (validate-formats formats manifestation article-root)
  (validate-uri-chain article-root work expression manifestation formats)
  (validate-article-number-consistency article-root work expression manifestation formats)

  t)

;;; ============================================================
;;; ARTICLE ROOT VALIDATION
;;; ============================================================

(defun validate-article-root (article)
  "Validate Article Root instance"

  ;; Required slots
  (assert (slot-boundp article 'orchestrator.model::article-number)
          () "Article Root missing article-number")

  (assert (slot-boundp article 'orchestrator.model::article-title)
          () "Article Root missing article-title")

  (assert (slot-boundp article 'orchestrator.model::work-uri)
          () "Article Root missing work-uri")

  ;; URI pattern validation
  (let ((uri (orchestrator.model:resource-uri article))
        (num (orchestrator.model:article-number article)))

    (assert (search (format nil "~A/art/" (orchestrator.uris:get-eli-const-prefix)) uri)
            () "Article Root URI doesn't match ELI pattern: ~A" uri)

    (assert (search (format nil "/art/~D" num) uri)
            () "Article Root URI inconsistent with number ~D: ~A" num uri)

    ;; Must NOT have /work suffix (that's Work URI)
    (assert (not (search "/work" uri))
            () "Article Root URI should not contain /work: ~A" uri))

  ;; Article number range — upper bound read from corpus config, no hardcoded limit
  (let* ((num (orchestrator.model:article-number article))
         (max-articles (or (ignore-errors
                             (parse-integer
                               (or (orchestrator.spec:config-get "corpus.article_count") "")
                               :junk-allowed t))
                           most-positive-fixnum)))
    (assert (and (>= num 1) (<= num max-articles))
            () "Article number out of range (1-~D): ~D" max-articles num))

  t)

;;; ============================================================
;;; WORK VALIDATION
;;; ============================================================

(defun validate-work (work article-root)
  "Validate Work instance against Article Root"

  ;; Required slots
  (assert (slot-boundp work 'orchestrator.model::article-number)
          () "Work missing article-number")

  (assert (slot-boundp work 'orchestrator.model::article-root-uri)
          () "Work missing article-root-uri")

  ;; URI pattern validation
  (let ((work-uri (orchestrator.model:resource-uri work))
        (expected-work-uri (orchestrator.model:work-uri article-root)))

    (assert (string= work-uri expected-work-uri)
            () "Work URI mismatch. Expected: ~A, Got: ~A"
            expected-work-uri work-uri)

    (assert (search "/work" work-uri)
            () "Work URI must contain /work: ~A" work-uri))

  ;; Article Root linkage
  (let ((work-article-root (orchestrator.model:article-root-uri work))
        (article-uri (orchestrator.model:resource-uri article-root)))

    (assert (string= work-article-root article-uri)
            () "Work article-root-uri doesn't match Article URI. Expected: ~A, Got: ~A"
            article-uri work-article-root))

  t)

;;; ============================================================
;;; EXPRESSION VALIDATION
;;; ============================================================

(defun validate-expression (expression work article-root)
  "Validate Expression instance against Work and Article Root"

  ;; Required slots
  (assert (slot-boundp expression 'orchestrator.model::title)
          () "Expression missing title")

  (assert (slot-boundp expression 'orchestrator.model::content)
          () "Expression missing content")

  (assert (slot-boundp expression 'orchestrator.model::language)
          () "Expression missing language")

  (assert (slot-boundp expression 'orchestrator.model::article-root-uri)
          () "Expression missing article-root-uri")

  ;; Language validation
  (let ((lang (orchestrator.model:expression-language expression)))
    (assert (member lang '("el" "en") :test #'string=)
            () "Invalid language code: ~A (expected 'el' or 'en')" lang))

  ;; URI pattern validation
  (let ((expr-uri (orchestrator.model:resource-uri expression))
        (work-uri (orchestrator.model:resource-uri work)))

    (assert (search work-uri expr-uri)
            () "Expression URI doesn't start with Work URI. Work: ~A, Expression: ~A"
            work-uri expr-uri)

    (assert (search "/exp/" expr-uri)
            () "Expression URI must contain /exp/: ~A" expr-uri))

  ;; Work linkage
  (let ((expr-work (orchestrator.model:expression-work expression)))
    (assert (eq expr-work work)
            () "Expression work slot doesn't reference correct Work instance"))

  ;; Article Root linkage
  (let ((expr-article-root (orchestrator.model:article-root-uri expression))
        (article-uri (orchestrator.model:resource-uri article-root)))

    (assert (string= expr-article-root article-uri)
            () "Expression article-root-uri doesn't match Article URI"))

  t)

;;; ============================================================
;;; MANIFESTATION VALIDATION
;;; ============================================================

(defun validate-manifestation (manifestation expression article-root)
  "Validate Manifestation instance against Expression and Article Root"

  ;; Required slots
  (assert (slot-boundp manifestation 'orchestrator.model::expression)
          () "Manifestation missing expression")

  (assert (slot-boundp manifestation 'orchestrator.model::article-root-uri)
          () "Manifestation missing article-root-uri")

  ;; URI pattern validation
  (let ((man-uri (orchestrator.model:resource-uri manifestation))
        (expr-uri (orchestrator.model:resource-uri expression)))

    (assert (search expr-uri man-uri)
            () "Manifestation URI doesn't start with Expression URI")

    (assert (search "/man" man-uri)
            () "Manifestation URI must contain /man: ~A" man-uri))

  ;; Expression linkage
  (let ((man-expression (orchestrator.model:manifestation-expression manifestation)))
    (assert (eq man-expression expression)
            () "Manifestation expression slot doesn't reference correct Expression"))

  ;; Article Root linkage
  (let ((man-article-root (orchestrator.model:article-root-uri manifestation))
        (article-uri (orchestrator.model:resource-uri article-root)))

    (assert (string= man-article-root article-uri)
            () "Manifestation article-root-uri doesn't match Article URI"))

  t)

;;; ============================================================
;;; FORMATS VALIDATION
;;; ============================================================

(defun validate-formats (formats manifestation article-root)
  "Validate Format instances against Manifestation and Article Root"

  ;; Must have at least one format
  (assert (>= (length formats) 1)
          () "No formats provided (must have at least 1)")

  ;; Validate each format
  (dolist (format formats)

    ;; Required slots
    (assert (slot-boundp format 'orchestrator.model::format-type)
            () "Format missing format-type")

    (assert (slot-boundp format 'orchestrator.model::article-root-uri)
            () "Format missing article-root-uri")

    ;; URI pattern validation
    (let ((fmt-uri (orchestrator.model:resource-uri format))
          (man-uri (orchestrator.model:resource-uri manifestation)))

      (assert (search man-uri fmt-uri)
              () "Format URI doesn't start with Manifestation URI")

      (assert (search "/format/" fmt-uri)
              () "Format URI must contain /format/: ~A" fmt-uri))

    ;; Manifestation linkage
    (let ((fmt-manifestation (orchestrator.model:format-manifestation format)))
      (assert (eq fmt-manifestation manifestation)
              () "Format manifestation slot doesn't reference correct Manifestation"))

    ;; Article Root linkage
    (let ((fmt-article-root (orchestrator.model:article-root-uri format))
          (article-uri (orchestrator.model:resource-uri article-root)))

      (assert (string= fmt-article-root article-uri)
              () "Format article-root-uri doesn't match Article URI")))

  ;; Check for expected format types
  (let ((format-types (mapcar #'orchestrator.model:format-type formats)))
    (assert (member :html format-types)
            () "Missing HTML format")
    (assert (member :turtle format-types)
            () "Missing Turtle format")
    (assert (member :jsonld format-types)
            () "Missing JSON-LD format"))

  t)

;;; ============================================================
;;; URI CHAIN VALIDATION
;;; ============================================================

(defun validate-uri-chain (article-root work expression manifestation formats)
  "Validate complete URI chain follows consistent pattern"

  (let ((article-uri (orchestrator.model:resource-uri article-root))
        (work-uri (orchestrator.model:resource-uri work))
        (expr-uri (orchestrator.model:resource-uri expression))
        (man-uri (orchestrator.model:resource-uri manifestation)))

    ;; Work must be Article + "/work"
    (assert (string= work-uri (format nil "~A/work" article-uri))
            () "Work URI doesn't follow pattern. Expected: ~A/work, Got: ~A"
            article-uri work-uri)

    ;; Expression must be Work + "/exp/ell"
    (assert (string= expr-uri (format nil "~A/exp/ell" work-uri))
            () "Expression URI doesn't follow pattern")

    ;; Manifestation must be Expression + "/man"
    (assert (string= man-uri (format nil "~A/man" expr-uri))
            () "Manifestation URI doesn't follow pattern")

    ;; Each format must be Manifestation + "/format/{type}"
    (dolist (format formats)
      (let ((fmt-uri (orchestrator.model:resource-uri format))
            (fmt-type (string-downcase
                        (symbol-name (orchestrator.model:format-type format)))))
        (assert (string= fmt-uri (format nil "~A/format/~A" man-uri fmt-type))
                () "Format URI doesn't follow pattern"))))

  t)

;;; ============================================================
;;; ARTICLE NUMBER CONSISTENCY
;;; ============================================================

(defun validate-article-number-consistency (article-root work expression manifestation formats)
  "Validate article number is consistent across all layers.

   Format article numbers are not checked here directly: validate-formats
   asserts each format's manifestation slot is eq to the validated
   manifestation, which transitively guarantees number consistency through
   the manifestation → expression → work → article-number chain."
  (declare (ignore formats))

  (let ((article-num (orchestrator.model:article-number article-root))
        (work-num (orchestrator.model:article-number work)))

    (assert (= article-num work-num)
            () "Article number mismatch between Article Root (~D) and Work (~D)"
            article-num work-num)

    ;; Extract from Expression's Work
    (let* ((expr-work (orchestrator.model:expression-work expression))
           (expr-num (orchestrator.model:article-number expr-work)))
      (assert (= article-num expr-num)
              () "Article number mismatch with Expression's Work"))

    ;; Extract from Manifestation's Expression's Work
    (let* ((man-expr (orchestrator.model:manifestation-expression manifestation))
           (man-work (orchestrator.model:expression-work man-expr))
           (man-num (orchestrator.model:article-number man-work)))
      (assert (= article-num man-num)
              () "Article number mismatch with Manifestation chain")))

  t)

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(validate-frbr-stack
          validate-article-root
          validate-work
          validate-expression
          validate-manifestation
          validate-formats
          validate-uri-chain
          validate-article-number-consistency))
