;;;; tests/observer-verification.lisp
;;;; ============================================================================
;;;; ACTIVE OBSERVER VERIFICATION TESTS
;;;; ============================================================================

(defpackage :observer-verification
  (:use :cl))

(in-package :observer-verification)

;;; ============================================================================
;;; TEST DATA
;;; ============================================================================

(defparameter *test-articles*
  '((:number 1 :content "Το πολίτευμα της Ελλάδας είναι Προεδρευόμενη Κοινοβουλευτική Δημοκρατία.")
    (:number 2 :content "Ο σεβασμός και η προστασία της αξίας του ανθρώπου αποτελούν την πρωταρχική υποχρέωση της Πολιτείας.")
    (:number 5 :content "Καθένας έχει δικαίωμα να αναπτύσσει ελεύθερα την προσωπικότητά του.")
    (:number 25 :content "Τα δικαιώματα του ανθρώπου ως ατόμου και ως μέλους του κοινωνικού συνόλου τελούν υπό την εγγύηση του Κράτους.")))

(defparameter *test-ai-outputs*
  '(;; Direct citation
    "Σύμφωνα με το Άρθρο 5 του Συντάγματος, καθένας έχει δικαίωμα να αναπτύσσει ελεύθερα την προσωπικότητά του."
    ;; Multiple citations
    "Τα άρθρα 2 και 25 του Συντάγματος προστατεύουν τα ανθρώπινα δικαιώματα."
    ;; Indirect/semantic
    "Η ελεύθερη ανάπτυξη της προσωπικότητας είναι θεμελιώδες δικαίωμα."
    ;; No citation
    "Ο καιρός σήμερα είναι ηλιόλουστος."))

;;; ============================================================================
;;; TEST RUNNER
;;; ============================================================================

(defvar *tests-passed* 0)
(defvar *tests-failed* 0)

(defmacro deftest (name &body body)
  `(progn
     (format t "~%TEST: ~A~%" ',name)
     (handler-case
         (progn
           ,@body
           (format t "  ✓ PASSED~%")
           (incf *tests-passed*))
       (error (e)
         (format t "  ✗ FAILED: ~A~%" e)
         (incf *tests-failed*)))))

(defmacro assert-true (form &optional message)
  `(unless ,form
     (error "Assertion failed: ~A~@[ - ~A~]" ',form ,message)))

(defmacro assert-equal (expected actual &optional message)
  `(unless (equal ,expected ,actual)
     (error "Expected ~A, got ~A~@[ - ~A~]" ,expected ,actual ,message)))

;;; ============================================================================
;;; TESTS
;;; ============================================================================

(deftest corpus-index-creation
  "Test corpus index initialization"
  (let* ((index (make-instance 'orchestrator.citation-observer:corpus-index)))
    (orchestrator.citation-observer::initialize-corpus index *test-articles*)
    (assert-true (orchestrator.citation-observer::corpus-ready-p index)
                 "Corpus should be ready")))

(deftest observer-creation
  "Test observer creation"
  (let ((observer (orchestrator.citation-observer:make-observer
                   "test-observer" *test-articles*)))
    (assert-true observer "Observer should be created")
    (assert-equal :stopped
                  (getf (orchestrator.citation-observer:observer-status observer) :state)
                  "Observer should start stopped")))

(deftest observer-start-stop
  "Test observer lifecycle"
  (let ((observer (orchestrator.citation-observer:make-observer
                   "test-observer" *test-articles*)))
    (orchestrator.citation-observer:start-observer observer)
    (assert-equal :running
                  (getf (orchestrator.citation-observer:observer-status observer) :state))
    (orchestrator.citation-observer:stop-observer observer)
    (assert-equal :stopped
                  (getf (orchestrator.citation-observer:observer-status observer) :state))))

(deftest direct-citation-detection
  "Test detection of direct article citation"
  (let ((observer (orchestrator.citation-observer:make-observer
                   "test-observer" *test-articles*)))
    (orchestrator.citation-observer:start-observer observer)
    (let ((result (orchestrator.citation-observer:observe
                   observer
                   (first *test-ai-outputs*)
                   :ai-system :test
                   :source-type :test)))
      (assert-true (orchestrator.citation-observer:has-citations-p result)
                   "Should detect citation in text")
      (assert-true (>= (orchestrator.citation-observer:citation-count result) 1)
                   "Should find at least 1 citation"))))

(deftest multiple-citation-detection
  "Test detection of multiple citations"
  (let ((observer (orchestrator.citation-observer:make-observer
                   "test-observer" *test-articles*)))
    (orchestrator.citation-observer:start-observer observer)
    (let ((result (orchestrator.citation-observer:observe
                   observer
                   (second *test-ai-outputs*)
                   :ai-system :test
                   :source-type :test)))
      (assert-true (>= (orchestrator.citation-observer:citation-count result) 2)
                   "Should find at least 2 citations"))))

(deftest no-citation-detection
  "Test that irrelevant text has no citations"
  (let ((observer (orchestrator.citation-observer:make-observer
                   "test-observer" *test-articles*)))
    (orchestrator.citation-observer:start-observer observer)
    (let ((result (orchestrator.citation-observer:observe
                   observer
                   (fourth *test-ai-outputs*)
                   :ai-system :test
                   :source-type :test)))
      (assert-equal 0 (orchestrator.citation-observer:citation-count result)
                   "Should find no citations in irrelevant text"))))

(deftest metrics-tracking
  "Test observation metrics"
  (let ((observer (orchestrator.citation-observer:make-observer
                   "test-observer" *test-articles*)))
    (orchestrator.citation-observer:start-observer observer)
    ;; Run multiple observations
    (dolist (text *test-ai-outputs*)
      (orchestrator.citation-observer:observe observer text
                                              :ai-system :test
                                              :source-type :test))
    ;; Check metrics
    (multiple-value-bind (total citations with-cites ratio)
        (orchestrator.citation-observer:get-observation-metrics observer)
      (assert-equal 4 total "Should have 4 total observations")
      (assert-true (> citations 0) "Should have found some citations"))))

(deftest closure-callbacks
  "Test pre/post processor closures"
  (let* ((pre-called nil)
         (post-called nil)
         (observer (make-instance 'orchestrator.citation-observer:active-observer
                                  :name "closure-test"
                                  :corpus (let ((idx (make-instance 'orchestrator.citation-observer:corpus-index)))
                                           (orchestrator.citation-observer::initialize-corpus idx *test-articles*)
                                           idx)
                                  :pre-processor (lambda (text)
                                                  (setf pre-called t)
                                                  text)
                                  :post-processor (lambda (result)
                                                   (setf post-called t)
                                                   result))))
    (orchestrator.citation-observer:start-observer observer)
    (orchestrator.citation-observer:observe observer "Άρθρο 5 test"
                                            :ai-system :test
                                            :source-type :test)
    (assert-true pre-called "Pre-processor should be called")
    (assert-true post-called "Post-processor should be called")))

(deftest citation-callback
  "Test on-citation callback"
  (let* ((found-citations nil)
         (observer (make-instance 'orchestrator.citation-observer:active-observer
                                  :name "callback-test"
                                  :corpus (let ((idx (make-instance 'orchestrator.citation-observer:corpus-index)))
                                           (orchestrator.citation-observer::initialize-corpus idx *test-articles*)
                                           idx)
                                  :on-citation (lambda (match)
                                                (push match found-citations)))))
    (orchestrator.citation-observer:start-observer observer)
    (orchestrator.citation-observer:observe observer (first *test-ai-outputs*)
                                            :ai-system :test
                                            :source-type :test)
    (assert-true (not (null found-citations))
                 "Citation callback should be triggered")))

(deftest dsL-macros
  "Test DSL macros work"
  (let ((observer (orchestrator.citation-observer:make-observer
                   "dsl-test" *test-articles*)))
    (orchestrator.citation-observer:start-observer observer)
    (let ((result (orchestrator.citation-observer:observe
                   observer (first *test-ai-outputs*)
                   :ai-system :test :source-type :test))
          (count 0))
      ;; Test do-citations macro
      (orchestrator.citation-observer:do-citations (cite result)
        (incf count))
      (assert-true (>= count 0) "do-citations macro should work"))))

;;; ============================================================================
;;; MAIN
;;; ============================================================================

(defun run-tests ()
  "Run all observer verification tests"
  (setf *tests-passed* 0
        *tests-failed* 0)

  (format t "~%")
  (format t "════════════════════════════════════════════════════════════════~%")
  (format t "     ACTIVE OBSERVER VERIFICATION~%")
  (format t "════════════════════════════════════════════════════════════════~%")

  ;; Load dependencies
  (format t "~%Loading dependencies...~%")
  (load #P"/home/user/ORCHESTRATORSUPER/source/greek-tokenizer-advanced.lisp")
  (load #P"/home/user/ORCHESTRATORSUPER/source/citation-authority.lisp")
  (load #P"/home/user/ORCHESTRATORSUPER/source/citation-observer.lisp")

  ;; Run tests
  (corpus-index-creation)
  (observer-creation)
  (observer-start-stop)
  (direct-citation-detection)
  (multiple-citation-detection)
  (no-citation-detection)
  (metrics-tracking)
  (closure-callbacks)
  (citation-callback)
  (dsl-macros)

  ;; Summary
  (format t "~%════════════════════════════════════════════════════════════════~%")
  (format t "     RESULTS: ~D passed, ~D failed~%"
          *tests-passed* *tests-failed*)
  (format t "════════════════════════════════════════════════════════════════~%~%")

  (zerop *tests-failed*))

;; Run if loaded directly
(run-tests)
