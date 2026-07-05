#!/usr/bin/env -S sbcl --script
;;;; scripts/verify-gate-5-validation.lisp
;;;; GATE-5 Validation Verification Harness
;;;;
;;;; Scriptable proof that validation is HARD FAIL for invalid input.
;;;;
;;;; This script:
;;;;   1. Loads validation-authority
;;;;   2. Tests with known broken TTL
;;;;   3. Verifies ERROR is signaled (not silent pass)
;;;;
;;;; Exit codes:
;;;;   0 = PASS (validation correctly fails on invalid input)
;;;;   1 = FAIL (validation did not fail, or other error)

(require :asdf)

;; Load validation authority
(handler-case
    (asdf:load-system :orchestrator-infrastructure :verbose nil)
  (error (e)
    (format t "ERROR: Failed to load orchestrator-infrastructure: ~A~%" e)
    (sb-ext:exit :code 1)))

(defpackage #:gate-5-verification
  (:use :cl))

(in-package #:gate-5-verification)

(defun test-broken-ttl-unclosed-string ()
  "Test that unclosed string triggers error"
  (let ((broken-ttl "@prefix ex: <http://example.com/> .
<http://example.com/test> ex:prop \"unclosed string
"))
    (handler-case
        (progn
          (orchestrator.validation-authority:validate-turtle-contract broken-ttl)
          (format t "FAIL: Unclosed string did not trigger error~%")
          nil)
      (error (e)
        (format t "PASS: Unclosed string correctly triggered error: ~A~%" e)
        t))))

(defun test-broken-ttl-missing-prefix ()
  "Test that missing required prefix triggers error"
  (let ((broken-ttl "<http://example.com/test> a <http://example.com/Thing> ."))
    (handler-case
        (progn
          (orchestrator.validation-authority:validate-frbr-contract broken-ttl)
          (format t "FAIL: Missing ELI prefix did not trigger error~%")
          nil)
      (error (e)
        (format t "PASS: Missing ELI prefix correctly triggered error: ~A~%" e)
        t))))

(defun test-broken-ttl-uri-with-space ()
  "Test that URI with space triggers error"
  (let ((broken-ttl "@prefix ex: <http://example.com/> .
<http://example.com/broken uri> ex:prop \"value\" ."))
    (handler-case
        (progn
          (orchestrator.validation-authority:validate-turtle-contract broken-ttl)
          (format t "FAIL: URI with space did not trigger error~%")
          nil)
      (error (e)
        (format t "PASS: URI with space correctly triggered error: ~A~%" e)
        t))))

(defun test-valid-ttl ()
  "Test that valid TTL passes (sanity check)"
  (let ((valid-ttl "@prefix eli: <http://data.europa.eu/eli/ontology#> .
@prefix dcat: <http://www.w3.org/ns/dcat#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<http://example.com/article1> a eli:LegalResource .
<http://example.com/work1> a eli:LegalExpression .
<http://example.com/article1> eli:hasWork <http://example.com/work1> .
<http://example.com/expr1> a eli:LegalExpression .
<http://example.com/manif1> a eli:LegalManifestation .
<http://example.com/article1> eli:jurisdiction \"GRC\" .
<http://example.com/article1> dct:language \"el\" .
"))
    (handler-case
        (progn
          (orchestrator.validation-authority:validate-canonical-ttl valid-ttl)
          (format t "PASS: Valid TTL correctly passed validation~%")
          t)
      (error (e)
        (format t "FAIL: Valid TTL triggered error: ~A~%" e)
        nil))))

(defun run-all-tests ()
  "Run all verification tests"
  (format t "~%======================================================================~%")
  (format t "GATE-5 VALIDATION VERIFICATION HARNESS~%")
  (format t "======================================================================~%~%")

  (let ((results '()))
    (format t "Test 1: Unclosed string...~%")
    (push (test-broken-ttl-unclosed-string) results)
    (terpri)

    (format t "Test 2: Missing required prefix...~%")
    (push (test-broken-ttl-missing-prefix) results)
    (terpri)

    (format t "Test 3: URI with space...~%")
    (push (test-broken-ttl-uri-with-space) results)
    (terpri)

    (format t "Test 4: Valid TTL (sanity check)...~%")
    (push (test-valid-ttl) results)
    (terpri)

    (format t "======================================================================~%")
    (format t "SUMMARY~%")
    (format t "======================================================================~%")

    (let ((passed (count t results))
          (total (length results)))
      (format t "Passed: ~D/~D~%" passed total)
      (if (= passed total)
          (progn
            (format t "~%✓ VERIFICATION PASS: All tests passed~%")
            (format t "Validation correctly fails on invalid input~%")
            (format t "Validation correctly passes on valid input~%~%")
            0)
          (progn
            (format t "~%✗ VERIFICATION FAIL: Some tests failed~%~%")
            1)))))

;; Run tests and exit with appropriate code
(let ((exit-code (run-all-tests)))
  (sb-ext:exit :code exit-code))
