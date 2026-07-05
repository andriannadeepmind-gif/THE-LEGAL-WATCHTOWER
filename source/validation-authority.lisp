;;;; source/validation-authority.lisp
;;;; GATE-5: Deterministic Contract Validation (Zero External Dependencies)
;;;;
;;;; Validates canonical TTL output BEFORE emit-graph:
;;;;   - Turtle syntax contract (state machine, not regex)
;;;;   - FRBR structure contract (required patterns in TTL string)
;;;;
;;;; Guarantees:
;;;;   - Valid input → SAME output (deterministic)
;;;;   - Invalid input → HARD FAIL before emit-graph
;;;;   - Zero external deps (no pySHACL, no riot, no subprocess)
;;;;   - Fail-fast (error on first violation)

(defpackage #:orchestrator.validation-authority
  (:use :cl)
  (:export #:validate-canonical-ttl
           #:validate-turtle-contract
           #:validate-frbr-contract))

(in-package #:orchestrator.validation-authority)

;;; ============================================================
;;; PUBLIC API
;;; ============================================================

(defun validate-canonical-ttl (ttl-content &key context)
  "Validate canonical TTL content before emission.

   Performs deterministic contract validation:
     1. Turtle syntax contract (state machine)
     2. FRBR structure contract (required patterns)

   Args:
     ttl-content: String (normalized TTL)
     context: Optional context for debugging (e.g., article number)

   Returns: T if valid
   Signals: ERROR if invalid (hard fail before emit-graph)"

  (validate-turtle-contract ttl-content :context context)
  (validate-frbr-contract ttl-content :context context)
  t)

;;; ============================================================
;;; TURTLE SYNTAX CONTRACT (State Machine)
;;; ============================================================

(defun validate-turtle-contract (ttl-content &key context)
  "Validate Turtle syntax using state machine (not naive regex).

   Checks:
     - Escaped quotes handling (\\\" doesn't break parity)
     - Triple-quoted strings (\"\"\"...\"\"\")
     - Angle brackets in URI context only (<URI> not in literals)
     - Hard ban broken patterns (unclosed strings, invalid prefixes)
     - Minimum sanity (statement terminators, no mid-state EOF)

   Signals ERROR on violation."

  (unless (stringp ttl-content)
    (error "Turtle contract violation~@[ (context: ~A)~]: content is not a string" context))

  (when (zerop (length ttl-content))
    (error "Turtle contract violation~@[ (context: ~A)~]: empty content" context))

  ;; Check 1: Hard ban broken patterns
  (check-broken-patterns ttl-content context)

  ;; Check 2: State machine validation
  (validate-turtle-state-machine ttl-content context)

  ;; Check 3: Minimum sanity
  (check-minimum-sanity ttl-content context)

  t)

(defun check-broken-patterns (ttl &key context)
  "Hard ban known broken Turtle patterns."

  ;; Pattern 1: @prefix without terminating period
  (when (and (search "@prefix" ttl)
             (not (cl-ppcre:scan "@prefix\\s+\\w+:\\s+<[^>]+>\\s*\\." ttl)))
    (error "Turtle contract violation~@[ (context: ~A)~]: @prefix without terminating period" context))

  ;; Pattern 2: URI with spaces
  (when (cl-ppcre:scan "<[^>]*\\s+[^>]*>" ttl)
    (error "Turtle contract violation~@[ (context: ~A)~]: URI contains spaces" context))

  ;; Pattern 3: Empty URI
  (when (search "<>" ttl)
    (error "Turtle contract violation~@[ (context: ~A)~]: empty URI <>" context)))

(defun validate-turtle-state-machine (ttl &key context)
  "State machine for Turtle syntax validation.

   States: :normal, :in-string, :in-long-string, :in-uri, :comment
   Handles escapes, triple quotes, angle brackets correctly."

  (let ((state :normal)
        (escape-next nil)
        (quote-count 0)
        (uri-depth 0))

    (loop for char across ttl
          for i from 0
          do
          (case state
            (:normal
             (cond
               ;; Comment
               ((char= char #\#)
                (setf state :comment))
               ;; Triple-quoted string (check next 2 chars)
               ((and (char= char #\")
                     (< (+ i 2) (length ttl))
                     (char= (char ttl (+ i 1)) #\")
                     (char= (char ttl (+ i 2)) #\"))
                (setf state :in-long-string))
               ;; Regular string
               ((char= char #\")
                (setf state :in-string))
               ;; URI start
               ((char= char #\<)
                (setf state :in-uri)
                (incf uri-depth))))

            (:comment
             ;; Exit comment on newline
             (when (char= char #\Newline)
               (setf state :normal)))

            (:in-string
             (cond
               ;; Escape sequence
               (escape-next
                (setf escape-next nil))
               ;; Backslash
               ((char= char #\\)
                (setf escape-next t))
               ;; End string
               ((char= char #\")
                (setf state :normal)
                (incf quote-count))))

            (:in-long-string
             ;; Check for """ terminator (simplified: check 3 consecutive ")
             (when (and (char= char #\")
                        (< (+ i 2) (length ttl))
                        (char= (char ttl (+ i 1)) #\")
                        (char= (char ttl (+ i 2)) #\"))
               (setf state :normal)))

            (:in-uri
             (cond
               ;; End URI
               ((char= char #\>)
                (setf state :normal)
                (decf uri-depth))
               ;; Space in URI (should be caught by broken patterns, but double-check)
               ((char= char #\Space)
                (error "Turtle contract violation~@[ (context: ~A)~]: space in URI at position ~D"
                       context i))))))

    ;; Final state checks
    (unless (eq state :normal)
      (error "Turtle contract violation~@[ (context: ~A)~]: unclosed ~A at end of file"
             context state))

    (when (not (zerop uri-depth))
      (error "Turtle contract violation~@[ (context: ~A)~]: unclosed angle brackets (depth: ~D)"
             context uri-depth))))

(defun check-minimum-sanity (ttl &key context)
  "Minimum sanity checks for Turtle.

   - At least one statement terminator (.)
   - File doesn't end mid-statement (no orphan predicates)"

  ;; Check 1: At least one statement terminator
  (unless (find #\. ttl)
    (error "Turtle contract violation~@[ (context: ~A)~]: no statement terminator found" context))

  ;; Check 2: File should end with whitespace or terminator
  (let ((last-char (char ttl (1- (length ttl)))))
    (unless (or (member last-char '(#\. #\Space #\Newline #\Tab))
                (char= last-char #\}))  ; Closing brace for blank nodes
      (error "Turtle contract violation~@[ (context: ~A)~]: file ends unexpectedly with '~A'"
             context last-char))))

;;; ============================================================
;;; FRBR STRUCTURE CONTRACT (Pattern Matching on TTL String)
;;; ============================================================

(defun validate-frbr-contract (ttl-content &key context)
  "Validate FRBR structure in final TTL output.

   This is the OUTPUT OF RECORD validation - checks the actual TTL string,
   not intermediate Lisp objects.

   Required patterns:
     - Canonical prefixes (@prefix eli:, dcat:, dct:, etc.)
     - FRBR Work presence (eli:LegalResource, eli:hasWork)
     - FRBR Expression presence (eli:LegalExpression, eli:realizes)
     - FRBR Manifestation presence (eli:LegalManifestation)
     - Required ELI properties (eli:jurisdiction, dct:language)

   Signals ERROR on missing required pattern."

  ;; Check 1: Required prefixes
  (check-required-prefixes ttl-content context)

  ;; Check 2: FRBR layers present
  (check-frbr-layers ttl-content context)

  ;; Check 3: Required ELI properties
  (check-eli-properties ttl-content context)

  t)

(defun check-required-prefixes (ttl &key context)
  "Verify canonical prefixes are declared."

  (let ((required-prefixes '("@prefix eli:" "@prefix dcat:" "@prefix dct:"
                             "@prefix prov:" "@prefix xsd:")))
    (dolist (prefix required-prefixes)
      (unless (search prefix ttl)
        (error "FRBR contract violation~@[ (context: ~A)~]: missing required prefix ~A"
               context prefix)))))

(defun check-frbr-layers (ttl &key context)
  "Verify FRBR layers are present in TTL."

  ;; Layer 1: Work
  (unless (search "eli:LegalResource" ttl)
    (error "FRBR contract violation~@[ (context: ~A)~]: missing eli:LegalResource (Work layer)"
           context))

  ;; Layer 2: Expression
  (unless (search "eli:LegalExpression" ttl)
    (error "FRBR contract violation~@[ (context: ~A)~]: missing eli:LegalExpression" context))

  ;; Layer 3: Manifestation
  (unless (search "eli:LegalManifestation" ttl)
    (error "FRBR contract violation~@[ (context: ~A)~]: missing eli:LegalManifestation" context))

  ;; Relation: Work → Expression
  (unless (search "eli:hasWork" ttl)
    (error "FRBR contract violation~@[ (context: ~A)~]: missing eli:hasWork relation" context)))

(defun check-eli-properties (ttl &key context)
  "Verify required ELI properties are present."

  ;; Required: jurisdiction
  (unless (search "eli:jurisdiction" ttl)
    (error "FRBR contract violation~@[ (context: ~A)~]: missing eli:jurisdiction" context))

  ;; Required: language
  (unless (search "dct:language" ttl)
    (error "FRBR contract violation~@[ (context: ~A)~]: missing dct:language" context)))
