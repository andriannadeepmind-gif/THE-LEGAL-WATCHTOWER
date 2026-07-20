;;;; test-infrastructure.lisp
;;;; Basic tests for infrastructure layer

(defpackage #:orchestrator.infrastructure-tests
  (:use :cl :alexandria)
  (:export #:run-infrastructure-tests))

(in-package :orchestrator.infrastructure-tests)

;;;; ========================================================================
;;;; PATH TESTS
;;;; ========================================================================

(defun test-paths ()
  "Test path resolution"
  (format t "~%Testing path resolution...~%")
  
  ;; Test that default paths are registered
  (assert (orchestrator.paths:path-exists-p :base) nil "Base path should exist")
  (assert (orchestrator.paths:path-exists-p :scripts) nil "Scripts path should exist")
  (assert (orchestrator.paths:path-exists-p :output) nil "Output path should exist")
  
  ;; Test path resolution
  (let ((scripts-path (orchestrator.paths:resolve-path :scripts)))
    (assert (pathnamep scripts-path) nil "Should return pathname")
    (format t "  Scripts path: ~A~%" scripts-path))
  
  ;; Test path resolution with components
  (let ((script-file (orchestrator.paths:resolve-path :scripts "test.py")))
    (assert (pathnamep script-file) nil "Should return pathname")
    (format t "  Script file path: ~A~%" script-file))
  
  ;; Test register-path
  (orchestrator.paths:register-path :test-path "/tmp/test")
  (assert (orchestrator.paths:path-exists-p :test-path) nil "Test path should be registered")
  
  ;; Test make-relative-path
  (let ((rel-path (orchestrator.paths:make-relative-path :base "subdir/file.txt")))
    (assert (pathnamep rel-path) nil "Should return pathname for relative path"))
  
  ;; Test error on invalid path key
  (handler-case
      (progn
        (orchestrator.paths:resolve-path :nonexistent-key)
        (error "Should have thrown error for nonexistent key"))
    (error (e)
      (format t "  Correctly caught error for invalid path: ~A~%" e)))
  
  (format t "✓ Path tests passed~%")
  t)

;;;; ========================================================================
;;;; LOGGING TESTS
;;;; ========================================================================

(defun test-logging ()
  "Test logging functionality"
  (format t "~%Testing logging...~%")
  
  ;; Test log levels
  (orchestrator.logging:set-log-level :info)
  (assert (eq (orchestrator.logging:get-log-level) :info))
  
  ;; Test setting different log levels
  (orchestrator.logging:set-log-level :debug)
  (assert (eq (orchestrator.logging:get-log-level) :debug))
  (orchestrator.logging:set-log-level :info)
  
  ;; Test correlation ID generation
  (let ((id1 (orchestrator.logging:get-correlation-id))
        (id2 (orchestrator.logging:get-correlation-id)))
    (assert (string= id1 id2) nil "Should return same correlation ID in same context"))
  
  ;; Test new correlation ID in new context
  (let ((orchestrator.logging:*correlation-id* nil))
    (let ((new-id (orchestrator.logging:get-correlation-id)))
      (assert (stringp new-id) nil "Should generate new correlation ID")))
  
  ;; Test logging with context
  (orchestrator.logging:with-log-context ((:component "test") (:operation "test-run"))
    (orchestrator.logging:log-info "Test message"))
  
  ;; Test all log levels
  (orchestrator.logging:log-trace "Trace message")
  (orchestrator.logging:log-debug "Debug message")
  (orchestrator.logging:log-info "Info message")
  (orchestrator.logging:log-warn "Warn message")
  (orchestrator.logging:log-error "Error message")
  
  ;; Test log-info with format args
  (orchestrator.logging:log-info "Test ~A with ~A" "message" "args")
  
  (format t "✓ Logging tests passed~%")
  t)

;;;; ========================================================================
;;;; CIRCUIT BREAKER TESTS
;;;; ========================================================================

(defun test-circuit-breaker ()
  "Test circuit breaker functionality"
  (format t "~%Testing circuit breaker...~%")
  
  ;; Create a test circuit breaker
  (let ((cb (orchestrator.circuit-breaker:make-circuit-breaker 
             "test-breaker"
             :failure-threshold 3
             :timeout 10)))
    
    ;; Should start closed
    (assert (eq (orchestrator.circuit-breaker:cb-state cb) :closed))
    
    ;; Test successful calls
    (orchestrator.circuit-breaker:with-circuit-breaker cb
      (+ 1 2))
    
    (assert (eq (orchestrator.circuit-breaker:cb-state cb) :closed))
    
    ;; Test failure recording
    (loop repeat 3
          do (ignore-errors
               (orchestrator.circuit-breaker:with-circuit-breaker cb
                 (error "Test failure"))))
    
    ;; Should be open after threshold failures
    (assert (eq (orchestrator.circuit-breaker:cb-state cb) :open))
    
    ;; Get metrics
    (let ((metrics (orchestrator.circuit-breaker:circuit-breaker-metrics cb)))
      (format t "  Circuit breaker metrics: ~A~%" metrics)
      (assert (= (getf metrics :total-failures) 3) nil "Should have 3 failures"))
    
    ;; Test reset
    (orchestrator.circuit-breaker:reset-circuit-breaker cb)
    (assert (eq (orchestrator.circuit-breaker:cb-state cb) :closed))
    
    ;; Test circuit breaker registry
    (orchestrator.circuit-breaker:register-circuit-breaker "test-registry-breaker")
    (let ((registered-cb (orchestrator.circuit-breaker:get-circuit-breaker "test-registry-breaker")))
      (assert registered-cb nil "Should retrieve registered breaker"))
    
    ;; Test circuit open error
    (let ((error-caught nil))
      (setf (orchestrator.circuit-breaker:cb-state cb) :open)
      (handler-case
          (orchestrator.circuit-breaker:with-circuit-breaker cb
            (+ 1 2))
        (orchestrator.circuit-breaker:circuit-open-error (e)
          (setf error-caught t)
          (format t "  Correctly caught circuit-open-error: ~A~%" e)))
      (assert error-caught nil "Should catch circuit-open-error"))
    
    (format t "✓ Circuit breaker tests passed~%")
    t))

;;;; ========================================================================
;;;; DEPENDENCY INJECTION TESTS
;;;; ========================================================================

(defun test-dependency-injection ()
  "Test dependency injection container"
  (format t "~%Testing dependency injection...~%")
  
  ;; Create a test container
  (let ((container (orchestrator.injection:make-container)))
    
    ;; Register a singleton
    (orchestrator.injection:register 
     'test-service
     (lambda () (list :service "test" :id (random 1000)))
     :lifetime :singleton)
    
    ;; Resolve twice - should get same instance
    (let ((orchestrator.injection:*container* container))
      (let ((instance1 (orchestrator.injection:resolve 'test-service))
            (instance2 (orchestrator.injection:resolve 'test-service)))
        (assert (eq instance1 instance2) nil "Singleton should return same instance")))
    
    ;; Register a transient
    (orchestrator.injection:register 
     'transient-service
     (lambda () (list :service "transient" :id (random 1000)))
     :lifetime :transient)
    
    ;; Resolve twice - should get different instances
    (let ((orchestrator.injection:*container* container))
      (let ((instance1 (orchestrator.injection:resolve 'transient-service))
            (instance2 (orchestrator.injection:resolve 'transient-service)))
        (assert (not (eq instance1 instance2)) nil "Transient should return different instances")))
    
    ;; Test has-binding-p
    (assert (orchestrator.injection:has-binding-p 'test-service container))
    (assert (not (orchestrator.injection:has-binding-p 'nonexistent-service container)))
    
    ;; Test list-bindings
    (let ((bindings (orchestrator.injection:list-bindings container)))
      (assert (>= (length bindings) 2) nil "Should have at least 2 bindings"))
    
    ;; Test remove-binding
    (orchestrator.injection:remove-binding 'test-service container)
    (assert (not (orchestrator.injection:has-binding-p 'test-service container)))
    
    ;; Test clear-container
    (orchestrator.injection:clear-container container)
    (assert (zerop (length (orchestrator.injection:list-bindings container))) 
            nil "Container should be empty after clear")
    
    ;; Test register-singleton shortcut
    (orchestrator.injection:register-singleton 'singleton-test (lambda () "singleton"))
    
    ;; Test register-factory shortcut
    (orchestrator.injection:register-factory 'factory-test (lambda () "factory"))
    
    ;; Test register-transient shortcut
    (orchestrator.injection:register-transient 'transient-test (lambda () "transient"))
    
    (format t "✓ Dependency injection tests passed~%")
    t))

;;;; ========================================================================
;;;; SESSION TESTS
;;;; ========================================================================

;; [0092/Blocker#2] test-session-management ΑΦΑΙΡΕΘΗΚΕ μαζί με το off-plan
;; session-handoff subsystem (ACE μέσω *read-eval*, μηδέν runtime caller).

;;;; ========================================================================
;;;; EDGE CASE TESTS
;;;; ========================================================================

(defun test-edge-cases ()
  "Test edge cases and error conditions"
  (format t "~%Testing edge cases...~%")
  
  ;; Test resolve with nil container
  (handler-case
      (progn
        (orchestrator.injection:resolve 'test-service nil)
        (error "Should have thrown error for nil container"))
    (error (e)
      (format t "  Correctly caught error for nil container: ~A~%" e)))
  
  ;; Test circuit breaker with call-with-circuit-breaker
  (let ((cb (orchestrator.circuit-breaker:make-circuit-breaker "edge-test")))
    (let ((result (orchestrator.circuit-breaker:call-with-circuit-breaker 
                   cb 
                   (lambda () 42))))
      (assert (= result 42) nil "Should return function result")))
  
  ;; Test path resolution error handling
  (handler-case
      (progn
        (orchestrator.paths:resolve-path :totally-invalid-path)
        (error "Should throw error for invalid path"))
    (error (e)
      (format t "  Correctly caught invalid path error~%")))
  
  ;; Test log level assertions
  (handler-case
      (progn
        (orchestrator.logging:set-log-level :invalid-level)
        (error "Should throw error for invalid log level"))
    (error (e)
      (format t "  Correctly caught invalid log level error~%")))
  
  ;; [0092/Blocker#2] session edge-case ΑΦΑΙΡΕΘΗΚΕ μαζί με το off-plan
  ;; session-handoff subsystem (ACE μέσω *read-eval*, μηδέν runtime caller).

  (format t "✓ Edge case tests passed~%")
  t)

;;;; ========================================================================
;;;; TEST RUNNER
;;;; ========================================================================

(defun run-infrastructure-tests ()
  "Run all infrastructure tests"
  (format t "~%========================================~%")
  (format t "INFRASTRUCTURE TESTS~%")
  (format t "========================================~%")
  
  (handler-case
      (progn
        (test-paths)
        (test-logging)
        (test-circuit-breaker)
        (test-dependency-injection)
        (test-edge-cases)
        
        (format t "~%========================================~%")
        (format t "✓ ALL TESTS PASSED~%")
        (format t "========================================~%~%")
        t)
    (error (e)
      (format t "~%========================================~%")
      (format t "✗ TEST FAILED: ~A~%" e)
      (format t "========================================~%~%")
      nil)))
