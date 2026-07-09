;;;; tests/escape-sequences-test.lisp
;;;; Unit tests for escape sequence logic
;;;;
;;;; FORENSIC NOTE: Tests extracted from rendering.lisp escape functions
;;;; Source of truth: If tests fail, runtime output is authoritative, NOT rendering.lisp
;;;;
;;;; Purpose: Lock escape behavior before rendering.lisp deletion
;;;; Created: 2025-12-22 (validation-first methodology)

(in-package :cl-user)

(defpackage :orchestrator.tests.escape
  (:use :cl :fiveam)
  (:export #:run-escape-tests))

(in-package :orchestrator.tests.escape)

;;; ============================================================================
;;; TEST SUITE DEFINITION
;;; ============================================================================

(def-suite escape-sequences
  :description "Tests for Turtle and HTML escape sequences")

(in-suite escape-sequences)

;;; ============================================================================
;;; TURTLE ESCAPE TESTS
;;; Extracted from: rendering.lisp lines 46-59
;;; Specification: RDF 1.1 Turtle (W3C Recommendation)
;;; ============================================================================

(test turtle-escape-backslash
  "Backslash must be escaped as double backslash"
  ;; Input: \ → Output: \\
  (is (string= "foo\\\\bar"
               (orchestrator.spec:escape-turtle-string "foo\\bar")))
  (is (string= "\\\\\\\\"
               (orchestrator.spec:escape-turtle-string "\\\\")))
  (is (string= "path\\\\to\\\\file"
               (orchestrator.spec:escape-turtle-string "path\\to\\file"))))

(test turtle-escape-quote
  "Double quote must be escaped with backslash"
  ;; Input: " → Output: \"
  (is (string= "foo\\\"bar"
               (orchestrator.spec:escape-turtle-string "foo\"bar")))
  (is (string= "\\\"quoted\\\""
               (orchestrator.spec:escape-turtle-string "\"quoted\"")))
  (is (string= "say \\\"hello\\\""
               (orchestrator.spec:escape-turtle-string "say \"hello\""))))

(test turtle-escape-newline
  "Newline must be escaped as backslash-n"
  ;; Input: \n → Output: \\n (literal backslash followed by n)
  (is (string= "line1\\nline2"
               (orchestrator.spec:escape-turtle-string (format nil "line1~%line2"))))
  (is (string= "\\n\\n"
               (orchestrator.spec:escape-turtle-string (format nil "~%~%"))))
  (is (string= "paragraph\\n\\nend"
               (orchestrator.spec:escape-turtle-string (format nil "paragraph~%~%end")))))

(test turtle-escape-carriage-return
  "Carriage return must be escaped as backslash-r"
  ;; Input: \r → Output: \\r
  (is (string= "foo\\rbar"
               (orchestrator.spec:escape-turtle-string (format nil "foo~Cbar" #\Return))))
  (is (string= "\\r"
               (orchestrator.spec:escape-turtle-string (format nil "~C" #\Return)))))

(test turtle-escape-combined
  "Multiple escape sequences must work together"
  ;; Complex input with backslash, quotes, and newlines
  (is (string= "\\\"quote\\\\slash\\nline\\\""
               (orchestrator.spec:escape-turtle-string
                (format nil "\"quote\\slash~%line\"")))))

(test turtle-escape-greek-utf8
  "Greek characters must pass through unchanged (UTF-8 transparency)"
  ;; Turtle supports UTF-8 natively
  (is (string= "Άρθρο 1"
               (orchestrator.spec:escape-turtle-string "Άρθρο 1")))
  (is (string= "Σύνταγμα της Ελλάδας"
               (orchestrator.spec:escape-turtle-string "Σύνταγμα της Ελλάδας"))))

;;; ============================================================================
;;; HTML ESCAPE TESTS
;;; Extracted from: rendering.lisp lines 157-171
;;; Specification: HTML5 character references
;;; ============================================================================

(test html-escape-ampersand
  "Ampersand must be escaped as &amp;"
  ;; Input: & → Output: &amp;
  (is (string= "foo&amp;bar"
               (orchestrator.spec:escape-html "foo&bar")))
  (is (string= "&amp;&amp;"
               (orchestrator.spec:escape-html "&&")))
  (is (string= "Q&amp;A"
               (orchestrator.spec:escape-html "Q&A"))))

(test html-escape-less-than
  "Less-than sign must be escaped as &lt;"
  ;; Input: < → Output: &lt;
  (is (string= "&lt;div&gt;"
               (orchestrator.spec:escape-html "<div>")))
  (is (string= "x &lt; y"
               (orchestrator.spec:escape-html "x < y")))
  (is (string= "&lt;&lt;shift"
               (orchestrator.spec:escape-html "<<shift"))))

(test html-escape-greater-than
  "Greater-than sign must be escaped as &gt;"
  ;; Input: > → Output: &gt;
  (is (string= "&lt;tag&gt;"
               (orchestrator.spec:escape-html "<tag>")))
  (is (string= "x &gt; y"
               (orchestrator.spec:escape-html "x > y")))
  (is (string= "shift&gt;&gt;"
               (orchestrator.spec:escape-html "shift>>"))))

(test html-escape-double-quote
  "Double quote must be escaped as &quot;"
  ;; Input: " → Output: &quot;
  (is (string= "&quot;quoted&quot;"
               (orchestrator.spec:escape-html "\"quoted\"")))
  (is (string= "say &quot;hello&quot;"
               (orchestrator.spec:escape-html "say \"hello\""))))

(test html-escape-single-quote
  "Single quote must be escaped as &#39;"
  ;; Input: ' → Output: &#39;
  (is (string= "it&#39;s"
               (orchestrator.spec:escape-html "it's")))
  (is (string= "&#39;quoted&#39;"
               (orchestrator.spec:escape-html "'quoted'"))))

(test html-escape-combined
  "Multiple HTML entities must escape correctly"
  ;; Complex input with multiple special characters
  (is (string= "&lt;a href=&quot;/&amp;test&quot;&gt;link&#39;s&lt;/a&gt;"
               (orchestrator.spec:escape-html "<a href=\"/&test\">link's</a>"))))

(test html-escape-xss-prevention
  "XSS attack vectors must be neutralized"
  ;; Common XSS patterns
  (is (string= "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
               (orchestrator.spec:escape-html "<script>alert('xss')</script>")))
  (is (string= "&lt;img src=x onerror=&quot;alert(1)&quot;&gt;"
               (orchestrator.spec:escape-html "<img src=x onerror=\"alert(1)\">"))))

(test html-escape-greek-utf8
  "Greek characters must pass through unchanged (UTF-8 transparency)"
  ;; HTML5 supports UTF-8 natively
  (is (string= "Άρθρο 1"
               (orchestrator.spec:escape-html "Άρθρο 1")))
  (is (string= "Σύνταγμα της Ελλάδας"
               (orchestrator.spec:escape-html "Σύνταγμα της Ελλάδας"))))

;;; ============================================================================
;;; EDGE CASES AND BOUNDARY CONDITIONS
;;; ============================================================================

(test escape-empty-string
  "Empty string must remain empty"
  (is (string= "" (orchestrator.spec:escape-turtle-string "")))
  (is (string= "" (orchestrator.spec:escape-html ""))))

(test escape-nil-handling
  "NIL input returns NIL (graceful handling)"
  ;; Runtime behavior: functions accept nil and return nil
  (is (null (orchestrator.spec:escape-turtle-string nil)))
  (is (null (orchestrator.spec:escape-html nil))))

(test escape-order-dependency
  "Escape order must prevent double-escaping"
  ;; Critical: Ampersand must be escaped FIRST in HTML
  ;; Otherwise & in &lt; becomes &amp;lt;
  (is (string= "&amp;lt;"
               (orchestrator.spec:escape-html "&lt;")))
  ;; Critical: Backslash must be escaped FIRST in Turtle
  (is (string= "\\\\\\\""
               (orchestrator.spec:escape-turtle-string "\\\""))))

;;; ============================================================================
;;; TEST RUNNER
;;; ============================================================================

(defun run-escape-tests ()
  "Run all escape sequence tests

  Returns:
    T if all tests pass, NIL if any fail"
  (format t "~%")
  (format t "=================================================================~%")
  (format t "ESCAPE SEQUENCE TESTS~%")
  (format t "Source: rendering.lisp (forensic extraction)~%")
  (format t "=================================================================~%")
  (format t "~%")

  (let* ((results (run 'escape-sequences))
         (passed (remove-if-not (lambda (r) (typep r 'fiveam::test-passed)) results))
         (failed (remove-if-not (lambda (r) (typep r 'fiveam::test-failure)) results)))
    (format t "~%")
    (format t "=================================================================~%")
    (format t "RESULTS~%")
    (format t "=================================================================~%")
    (format t "Tests run: ~D~%" (length results))
    (format t "Passed: ~D~%" (length passed))
    (format t "Failed: ~D~%" (length failed))
    (format t "~%")

    (if (zerop (length failed))
        (progn
          (format t "✓ ALL TESTS PASSED~%")
          (format t "Escape logic validated against runtime behavior~%")
          t)
        (progn
          (format t "✗ SOME TESTS FAILED~%")
          (format t "NOTE: Runtime output is authoritative, NOT rendering.lisp~%")
          (format t "Update tests to match actual runtime behavior~%")
          nil))))

;;; End of file

;;; ── FF3: absorbed into the gated standalone-test suite ──
;;; Runs under docker/run-standalone-test.lisp (same harness as every other
;;; tests/<name>-test.lisp): self-exit 0/1 so a single failing check fails the
;;; Docker build — no separate compose file, no wrapper (one gated path).
(sb-ext:exit :code (if (orchestrator.tests.escape:run-escape-tests) 0 1))
