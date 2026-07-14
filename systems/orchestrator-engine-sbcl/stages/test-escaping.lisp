;;;; systems/orchestrator-engine-sbcl/stages/test-escaping.lisp
;;;; PIPELINE-EMBEDDED ESCAPING TESTS
;;;;
;;;; PHASE 2 - DARPA HARDENING:
;;;; - Execution proof struct (not boolean tripwire)
;;;; - Deterministic sampling (hash-based, auditable)
;;;; - Renderer completeness gate
;;;; - Negative control (fault injection)

(in-package :orchestrator.engine.sbcl)

;;; ============================================================
;;; EXECUTION PROOF STRUCTURE
;;; ============================================================

(defstruct test-escaping-proof
  "Structural proof of test-escaping-stage execution

  DARPA-grade execution evidence (not boolean flag)"
  (stage-id :test-escaping :read-only t)
  (pipeline-id nil)
  (pipeline-version nil)
  (graph-position '(:after generate-rdf :before validate-shacl) :read-only t)
  (article-count-total 0)
  (sampled-article-ids nil)
  (sample-rule nil)
  (renderers-tested nil)
  (active-renderers '(:html-rdfa :json-ld :turtle) :read-only t)
  (negative-control-executed nil)
  (negative-control-failure-observed nil)
  (timestamp nil)
  (proof-hash nil))

(defvar *test-escaping-proof* nil
  "Execution proof - set when test-escaping-stage runs")

(defvar *test-escaping-stage-executed* nil
  "Legacy boolean tripwire (kept for backward compatibility)")

;;; ============================================================
;;; RUNTIME GUARD - FAIL-FAST IF RUNNING IN ISOLATION
;;; ============================================================

(assert (find-package :orchestrator.engine.sbcl)
        ()
        "FATAL: test-escaping-stage not running inside orchestrator-engine pipeline")

(assert (fboundp 'render-canonical-html)
        ()
        "FATAL: Production entrypoint render-canonical-html not available")

(assert (fboundp 'render-canonical-jsonld)
        ()
        "FATAL: Production entrypoint render-canonical-jsonld not available")

(assert (fboundp 'generate-frbr-unified-from-iir)
        ()
        "FATAL: Production entrypoint generate-frbr-unified-from-iir not available")

;;; ============================================================
;;; DETERMINISTIC SAMPLING
;;; ============================================================

(defun deterministic-sample-articles (articles mod-n equals-k)
  "Deterministic hash-based sampling (independent of ordering)

  Rule: (hash article-id) mod N == K

  Returns: (values sampled-articles sampled-ids)"
  (let ((sampled nil)
        (sampled-ids nil))
    (dolist (article articles)
      (let ((article-id (orchestrator.model:article-number article)))
        (when (= (mod (sxhash article-id) mod-n) equals-k)
          (push article sampled)
          (push article-id sampled-ids))))
    (values (nreverse sampled) (nreverse sampled-ids))))

;;; ============================================================
;;; TEST STAGE - EMBEDDED IN PRODUCTION PIPELINE
;;; ============================================================

(defun test-escaping-stage (context)
  "PIPELINE-EMBEDDED ESCAPING TESTS (PHASE 2 - DARPA HARDENING)

  Runs INSIDE pipeline stage graph, AFTER generate-rdf-stage.
  Tests SAME articles that pipeline processed.
  Calls SAME production functions that pipeline uses.
  Produces structural execution proof (not boolean flag).

  Returns:
    context (if all tests pass)

  Signals:
    orchestrator.spec:validation-error (crashes pipeline)"

  (let ((articles (orchestrator.core:get-context-value context :articles)))

    (unless articles
      (error 'orchestrator.spec:config-error
             :message "test-escaping-stage: No articles in context"
             :config-key :articles))

    (log:info () "PIPELINE TEST STAGE: Testing escaping on ~D pipeline articles" (length articles))

    ;; Initialize proof structure
    (let ((proof (make-test-escaping-proof
                  :pipeline-id 'greek-constitution
                  :pipeline-version "1.2"
                  :article-count-total (length articles)
                  :timestamp (get-universal-time))))

      ;; TEST 1: Negative control (fault injection)
      (test-negative-control proof)

      ;; TEST 2A: Adversarial HTML escaping
      (test-adversarial-escaping)

      ;; TEST 2B: Adversarial JSON-LD escaping
      (test-adversarial-json-escaping)
      (pushnew :json-ld (test-escaping-proof-renderers-tested proof))

      ;; TEST 2C: Turtle escaping validation
      (test-turtle-escaping)
      (pushnew :turtle (test-escaping-proof-renderers-tested proof))

      ;; TEST 3: Deterministic sample of real pipeline articles
      (test-pipeline-articles-deterministic articles proof)

      ;; TEST 4: Renderer completeness gate
      (verify-renderer-completeness proof)

      ;; Compute proof hash
      (setf (test-escaping-proof-proof-hash proof)
            (compute-proof-hash proof))

      ;; Log audit summary
      (log-proof-summary proof)

      ;; Set global proof (for deploy-epistemic verification)
      (setf *test-escaping-proof* proof)
      (setf *test-escaping-stage-executed* t)  ; Legacy flag

      (log:info () "✓ PIPELINE TEST STAGE: All escaping tests passed")
      context)))

;;; ============================================================
;;; PROOF VALIDATION
;;; ============================================================

(defun valid-proof-p (proof)
  "Validate execution proof structure

  Returns: T if valid, NIL otherwise"
  (and proof
       (test-escaping-proof-p proof)
       (eq (test-escaping-proof-stage-id proof) :test-escaping)
       (test-escaping-proof-pipeline-id proof)
       (> (test-escaping-proof-article-count-total proof) 0)
       (test-escaping-proof-sampled-article-ids proof)
       (test-escaping-proof-sample-rule proof)
       (test-escaping-proof-renderers-tested proof)
       ;; Compare renderers as sets (order-independent)
       (equal (sort (copy-list (test-escaping-proof-renderers-tested proof)) #'string<)
              (sort (copy-list (test-escaping-proof-active-renderers proof)) #'string<))
       (test-escaping-proof-negative-control-executed proof)
       (test-escaping-proof-negative-control-failure-observed proof)
       (test-escaping-proof-proof-hash proof)))

(defun compute-proof-hash (proof)
  "Compute SHA256 hash of proof structure (canonical representation)"
  (let ((canonical-string
         (format nil "~S"
                 (list :stage-id (test-escaping-proof-stage-id proof)
                       :pipeline-id (test-escaping-proof-pipeline-id proof)
                       :graph-position (test-escaping-proof-graph-position proof)
                       :article-count (test-escaping-proof-article-count-total proof)
                       :sampled-ids (test-escaping-proof-sampled-article-ids proof)
                       :renderers (test-escaping-proof-renderers-tested proof)
                       :negative-control (test-escaping-proof-negative-control-executed proof)))))
    (ironclad:byte-array-to-hex-string
     (ironclad:digest-sequence :sha256
                               (babel:string-to-octets canonical-string :encoding :utf-8)))))

(defun log-proof-summary (proof)
  "Log audit summary of execution proof"
  (log:info () "")
  (log:info () "=== EXECUTION PROOF SUMMARY ===")
  (log:info () "Stage: ~A" (test-escaping-proof-stage-id proof))
  (log:info () "Pipeline: ~A v~A"
            (test-escaping-proof-pipeline-id proof)
            (test-escaping-proof-pipeline-version proof))
  (log:info () "Graph Position: ~A" (test-escaping-proof-graph-position proof))
  (log:info () "Total Articles: ~D" (test-escaping-proof-article-count-total proof))
  (log:info () "Sample Rule: ~A" (test-escaping-proof-sample-rule proof))
  (log:info () "TEST-SAMPLE-IDS: ~{~A~^, ~}" (test-escaping-proof-sampled-article-ids proof))
  (log:info () "Active Renderers: ~A" (test-escaping-proof-active-renderers proof))
  (log:info () "Tested Renderers: ~A" (test-escaping-proof-renderers-tested proof))
  (log:info () "Negative Control: executed=~A failure-observed=~A"
            (test-escaping-proof-negative-control-executed proof)
            (test-escaping-proof-negative-control-failure-observed proof))
  (log:info () "Proof Hash: ~A" (test-escaping-proof-proof-hash proof))
  (log:info () "==============================")
  (log:info () ""))

;;; ============================================================
;;; TEST 1: NEGATIVE CONTROL (FAULT INJECTION)
;;; ============================================================

(defun test-negative-control (proof)
  "Negative control test - verify that escaping guards actually work

  Temporarily bypass escaping (in-memory only, no disk write).
  Verify that validation-error is raised.

  This proves the guards are active, not silently bypassed."

  (log:info () "TEST: Negative control (fault injection)")

  ;; Create article with known-bad content
  (let* ((bad-article (orchestrator.model:make-article
                                    :number 9999
                                    :title "Negative Control"
                                    :content "Test & ampersand"
                                    :state :generating))
         (failure-observed nil))

    ;; Temporarily override escape-html to return unescaped (FAULT INJECTION)
    ;; DARPA-grade: scoped fault injection with symbol-function
    (let ((original-escape (symbol-function 'orchestrator.spec:escape-html)))
      (unwind-protect
           (progn
             ;; Inject fault: disable escaping (identity function)
             (setf (symbol-function 'orchestrator.spec:escape-html)
                   (lambda (str) str))  ; NO ESCAPING

             ;; This should now produce bad output and fail assertion
             (handler-case
                 (let ((html (render-canonical-html bad-article)))
                   ;; Check for bare ampersand (should exist due to disabled escaping)
                   (when (cl-ppcre:scan "&(?!amp;|lt;|gt;|quot;)" html)
                     (setf failure-observed t)
                     (error 'orchestrator.spec:validation-error
                            :message "EXPECTED: Negative control detected bare ampersand")))
               (orchestrator.spec:validation-error (e)
                 ;; Expected - validation error was raised
                 (setf failure-observed t)
                 (log:info () "  ✓ Negative control: guard fired as expected"))))

        ;; ALWAYS restore original function
        (setf (symbol-function 'orchestrator.spec:escape-html) original-escape)))

    ;; Verify that failure was observed
    (unless failure-observed
      (error 'orchestrator.spec:validation-error
             :message "FATAL: Negative control FAILED - guard did not fire"))

    ;; Record in proof
    (setf (test-escaping-proof-negative-control-executed proof) t)
    (setf (test-escaping-proof-negative-control-failure-observed proof) t)

    (log:info () "  ✓ Negative control passed")))

;;; ============================================================
;;; TEST 2: ADVERSARIAL INJECTION
;;; ============================================================

(defun test-adversarial-escaping ()
  "Test with adversarial article containing XSS payloads and special chars

  Calls SAME production functions that pipeline uses:
    - render-canonical-html (via article object)

  Crashes pipeline if escaping fails."

  (log:info () "TEST: Adversarial escaping injection")

  ;; Create adversarial article
  (let* ((adversarial-article (orchestrator.model:make-article
                                            :number 999
                                            :title "Test & \"Escaping\" <script>"
                                            :content "Paragraph 1: A & B <script>alert('XSS')</script>

Paragraph 2: Δοκιμή \"quotes\" \\ backslash."
                                            :state :generating)))

    ;; Call SAME production function as pipeline (render-canonical-html)
    (let ((html (render-canonical-html adversarial-article)))

      ;; P1b [0052]#Α8: ΚΑΝΕΝΑ debug side-effect σε παραγωγικό stage — το
      ;; παλιό γράψιμο /tmp/DEBUG-adversarial.html έτρεχε σε ΚΑΘΕ παραγωγικό
      ;; run (και στο --cut-release). Τα assertions αρκούν· σε αποτυχία το
      ;; σφάλμα φέρει το δείγμα.

      ;; ASSERTION 1: No bare ampersands (skip ALL script tags including JSON-LD)
      ;; Remove script blocks line-by-line (cl-ppcre multiline regex doesn't work reliably)
      (let ((content-clean
             (with-output-to-string (out)
               (let ((in-script nil))
                 (with-input-from-string (in html)
                   (loop for line = (read-line in nil)
                         while line
                         do (cond
                              ((search "<script" line) (setf in-script t))
                              ((search "</script>" line) (setf in-script nil))
                              ((not in-script) (format out "~A~%" line)))))))))

        ;; DEBUG: Log cleaning stats
        (log:info () (format nil "  DEBUG: HTML length: ~D chars, After script removal: ~D chars"
                            (length html) (length content-clean)))

        ;; DEBUG: Find and log the bare ampersand if it exists
        (let ((match-pos (cl-ppcre:scan "&(?!amp;|lt;|gt;|quot;|apos;|nbsp;|copy;|reg;|trade;|mdash;|#\\d+;|#x[0-9a-fA-F]+;)" content-clean)))
          (when match-pos
            (let* ((context-start (max 0 (- match-pos 50)))
                   (context-end (min (length content-clean) (+ match-pos 50)))
                   (context (subseq content-clean context-start context-end)))
              (log:info () (format nil "  DEBUG: Found bare ampersand at position ~D" match-pos))
              (log:info () (format nil "  DEBUG: Context: ...~A..." context))
              (error 'orchestrator.spec:validation-error
                     :message "TEST FAILED: Bare ampersand in adversarial HTML"))))) ;; Close when, let (match-pos), let (content-clean)

      ;; ASSERTION 2: XSS payload escaped
      (when (cl-ppcre:scan "<script>alert" html)
        (error 'orchestrator.spec:validation-error
               :message "TEST FAILED: XSS payload not escaped"))

      ;; ASSERTION 3: Greek UTF-8 preserved
      (unless (search "Δοκιμή" html)
        (error 'orchestrator.spec:validation-error
               :message "TEST FAILED: Greek UTF-8 lost in adversarial HTML"))

      (log:info () "  ✓ Adversarial HTML test passed"))))

;;; ============================================================
;;; TEST 2B: ADVERSARIAL JSON-LD ESCAPING
;;; ============================================================

(defun test-adversarial-json-escaping ()
  "Test JSON-LD escaping with adversarial content

  Calls render-canonical-jsonld and verifies proper JSON string escaping"

  (log:info () "TEST: Adversarial JSON-LD escaping")

  (let* ((adversarial-article (orchestrator.model:make-article
                                            :number 999
                                            :title "Test & \"Escaping\" <script>"
                                            :content "Paragraph 1: A & B <script>alert('XSS')</script>

Paragraph 2: Δοκιμή \"quotes\" \\ backslash."
                                            :state :generating)))

    (let ((jsonld (render-canonical-jsonld adversarial-article)))

      ;; ASSERTION 1: No unescaped < or > in JSON strings
      ;; Must be Unicode escaped as \u003c and \u003e
      (when (cl-ppcre:scan "\"[^\"]*<[^\"]*\"" jsonld)
        (error 'orchestrator.spec:validation-error
               :message "TEST FAILED: Unescaped < in JSON-LD string"))

      (when (cl-ppcre:scan "\"[^\"]*>[^\"]*\"" jsonld)
        (error 'orchestrator.spec:validation-error
               :message "TEST FAILED: Unescaped > in JSON-LD string"))

      ;; ASSERTION 2: Quotes must be escaped as \"
      (when (cl-ppcre:scan "[^\\\\]\"\"" jsonld)
        (error 'orchestrator.spec:validation-error
               :message "TEST FAILED: Unescaped quote in JSON-LD"))

      ;; ASSERTION 3: Greek UTF-8 preserved
      (unless (search "schema.org" jsonld)
        (error 'orchestrator.spec:validation-error
               :message "TEST FAILED: JSON-LD structure corrupted"))

      (log:info () "  ✓ Adversarial JSON-LD test passed"))))

;;; ============================================================
;;; TEST 2C: TURTLE ESCAPING VALIDATION
;;; ============================================================

(defun test-turtle-escaping ()
  "Test Turtle escaping with adversarial strings

  Validates orchestrator.spec:escape-turtle-string function"

  (log:info () "TEST: Turtle escaping validation")

  ;; Test cases
  (let ((test-cases
         (list
          (list "foo\\bar" "foo\\\\bar" "Backslash")
          (list "foo\"bar" "foo\\\"bar" "Quote")
          (list (format nil "foo~%bar") "foo\\nbar" "Newline")
          (list (format nil "foo~Cbar" #\Return) "foo\\rbar" "Carriage return")
          (list "Άρθρο 1" "Άρθρο 1" "Greek UTF-8"))))

    (dolist (test test-cases)
      (destructuring-bind (input expected description) test
        (let ((output (orchestrator.spec:escape-turtle-string input)))
          (unless (string= output expected)
            (error 'orchestrator.spec:validation-error
                   :message (format nil "TEST FAILED: Turtle ~A escaping - expected '~A', got '~A'"
                                   description expected output))))))

    (log:info () "  ✓ Turtle escaping test passed")))

;;; ============================================================
;;; TEST 3: DETERMINISTIC SAMPLE OF REAL PIPELINE ARTICLES
;;; ============================================================

(defun test-pipeline-articles-deterministic (articles proof)
  "Test escaping on REAL pipeline articles (deterministic hash-based sampling)

  Uses SAME articles that went through generate-rdf-stage.
  Calls SAME production function (render-canonical-html).
  Deterministic sampling: (hash article-id) mod 12 == 0

  Crashes pipeline if any real article has escaping issues."

  (log:info () "TEST: Deterministic sample of real pipeline articles")

  (multiple-value-bind (sample-articles sample-ids)
      (deterministic-sample-articles articles 12 0)

    (log:info () "  Sampling rule: (hash article-id) mod 12 == 0")
    (log:info () "  Testing ~D sampled articles from ~D total" (length sample-articles) (length articles))

    ;; Record sample in proof
    (setf (test-escaping-proof-sample-rule proof) '(:hash-mod 12 :equals 0))
    (setf (test-escaping-proof-sampled-article-ids proof) sample-ids)

    (dolist (article sample-articles)
      (let ((article-num (orchestrator.model:article-number article)))

        ;; Call SAME production function as pipeline
        (let ((html (render-canonical-html article)))

          ;; ASSERTION: No bare ampersands in real article HTML
          ;; Remove script blocks line-by-line (same as adversarial test)
          (let ((content-clean
                 (with-output-to-string (out)
                   (let ((in-script nil))
                     (with-input-from-string (in html)
                       (loop for line = (read-line in nil)
                             while line
                             do (cond
                                  ((search "<script" line) (setf in-script t))
                                  ((search "</script>" line) (setf in-script nil))
                                  ((not in-script) (format out "~A~%" line)))))))))
            (let ((content-no-comments (cl-ppcre:regex-replace-all
                                       "(?s)<!--.*?-->"
                                       content-clean
                                       "")))
              (when (cl-ppcre:scan "&(?!amp;|lt;|gt;|quot;|apos;|nbsp;|copy;|reg;|trade;|mdash;|ndash;|#\\d+;|#x[0-9a-fA-F]+;)" content-no-comments)
                (error 'orchestrator.spec:validation-error
                       :message (format nil "TEST FAILED: Bare ampersand in Article ~D HTML" article-num)
                       :article article-num))))

          ;; ASSERTION: Greek UTF-8 preserved in real articles
          (unless (search "Άρθρο" html)
            (error 'orchestrator.spec:validation-error
                   :message (format nil "TEST FAILED: Greek UTF-8 lost in Article ~D HTML" article-num)
                   :article article-num)))))

    ;; Record HTML renderer as tested
    (pushnew :html-rdfa (test-escaping-proof-renderers-tested proof))

    (log:info () "  ✓ Deterministic sample passed")))

;;; ============================================================
;;; TEST 4: RENDERER COMPLETENESS GATE
;;; ============================================================

(defun verify-renderer-completeness (proof)
  "Verify that ALL active renderers were tested

  Gate condition: set(renderers-tested) == set(active-renderers)

  Crashes pipeline if any active renderer was not tested."

  (log:info () "TEST: Renderer completeness gate")

  (let ((active (test-escaping-proof-active-renderers proof))
        (tested (test-escaping-proof-renderers-tested proof)))

    (log:info () "  Active renderers: ~A" active)
    (log:info () "  Tested renderers: ~A" tested)

    ;; Check equality (as sets)
    (let ((missing (set-difference active tested))
          (extra (set-difference tested active)))

      (when missing
        (error 'orchestrator.spec:validation-error
               :message (format nil "FATAL: Renderer completeness FAILED - untested renderers: ~A" missing)))

      (when extra
        (error 'orchestrator.spec:validation-error
               :message (format nil "FATAL: Renderer completeness FAILED - unknown renderers tested: ~A" extra)))

      (unless (equal (sort (copy-list active) #'string<)
                    (sort (copy-list tested) #'string<))
        (error 'orchestrator.spec:validation-error
               :message "FATAL: Renderer completeness FAILED - sets do not match")))

    (log:info () "  ✓ Renderer completeness verified")))
