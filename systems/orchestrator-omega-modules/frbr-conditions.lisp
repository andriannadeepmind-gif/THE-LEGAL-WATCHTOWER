;;;; systems/orchestrator-spec/frbr-conditions.lisp
;;;; FRBR Conditions & Restarts - DARPA-level error handling
;;;; ΟΜΕΓΑ-LEVEL: Full Common Lisp condition system

(in-package :orchestrator.spec)

;;; ============================================================
;;; BASE CONDITION - FRBR GENERATION ERROR
;;; ============================================================

(define-condition frbr-generation-error (error)
  ((message :initarg :message
            :accessor error-message
            :initform "FRBR generation error"
            :documentation "Human-readable error message")
   
   (instance :initarg :instance
             :accessor error-instance
             :initform nil
             :documentation "FRBR instance that caused the error")
   
   (layer :initarg :layer
          :accessor error-layer
          :initform nil
          :documentation "FRBR layer where error occurred")
   
   (article-number :initarg :article-number
                   :accessor error-article-number
                   :initform nil
                   :documentation "Article number being processed")
   
   (timestamp :initform (orchestrator.model:get-iso8601-timestamp)
              :accessor error-timestamp
              :documentation "When the error occurred"))
  
  (:documentation "Base condition for all FRBR generation errors")
  
  (:report (lambda (condition stream)
             (format stream "FRBR Generation Error [~A]~%  Layer: ~A~%  Article: ~A~%  Message: ~A"
                     (error-timestamp condition)
                     (error-layer condition)
                     (error-article-number condition)
                     (error-message condition)))))

;;; ============================================================
;;; SPECIFIC CONDITIONS
;;; ============================================================

(define-condition invalid-frbr-instance (frbr-generation-error)
  ((missing-slot :initarg :missing-slot
                 :accessor error-missing-slot
                 :initform nil
                 :documentation "Name of missing required slot"))
  
  (:documentation "Signaled when FRBR instance is invalid")
  
  (:report (lambda (condition stream)
             (format stream "Invalid FRBR Instance~%  Missing slot: ~A~%  Instance: ~A"
                     (error-missing-slot condition)
                     (type-of (error-instance condition))))))

(define-condition article-data-missing (frbr-generation-error)
  ((data-key :initarg :data-key
             :accessor error-data-key
             :documentation "Missing data key"))
  
  (:documentation "Signaled when required article data is missing")
  
  (:report (lambda (condition stream)
             (format stream "Article Data Missing~%  Article: ~A~%  Missing: ~A"
                     (error-article-number condition)
                     (error-data-key condition)))))

(define-condition rdf-output-invalid (frbr-generation-error)
  ((output :initarg :output
           :accessor error-output
           :documentation "Invalid RDF output"))
  
  (:documentation "Signaled when generated RDF is invalid")
  
  (:report (lambda (condition stream)
             (format stream "Invalid RDF Output~%  Layer: ~A~%  Output length: ~A bytes"
                     (error-layer condition)
                     (length (error-output condition))))))

(define-condition file-write-error (frbr-generation-error)
  ((filepath :initarg :filepath
             :accessor error-filepath
             :documentation "File path that failed"))

  (:documentation "Signaled when file write fails")

  (:report (lambda (condition stream)
             (format stream "File Write Error~%  Path: ~A~%  Message: ~A"
                     (error-filepath condition)
                     (error-message condition)))))

(define-condition unified-generation-error (frbr-generation-error)
  ((cause :initarg :cause
          :accessor error-cause
          :initform nil
          :documentation "Originating condition that caused unified generation failure")

   (output-path :initarg :output-path
                :accessor error-output-path
                :initform nil
                :documentation "Intended output file path (not written due to failure)"))

  (:documentation "Signaled when unified article file generation fails completely.

   This condition is NOT catchable silently: callers must explicitly handle it
   via with-frbr-error-handling or a handler-case/handler-bind. Returning NIL
   without signaling this condition is forbidden — silent data loss is prohibited.

   The :cause slot carries the originating condition for full diagnostic chain.")

  (:report (lambda (condition stream)
             (format stream "Unified Generation FAILED~%~
                             ~&  Article:     ~A~%~
                             ~&  Output path: ~A~%~
                             ~&  Cause type:  ~S~%~
                             ~&  Cause:       ~A~%~
                             ~&  Message:     ~A"
                     (error-article-number condition)
                     (or (error-output-path condition) "<not determined>")
                     (type-of (error-cause condition))
                     (error-cause condition)
                     (error-message condition)))))

;;; ============================================================
;;; RESTART DEFINITIONS
;;; ============================================================

(defun skip-article-restart (article-number)
  "Restart: Skip the problematic article and continue"
  :skipped)

(defun use-default-value-restart (default-value)
  "Restart: Use a default value and continue"
  default-value)

(defun retry-generation-restart ()
  "Restart: Retry the generation with same data"
  :retry)

(defun abort-pipeline-restart ()
  "Restart: Abort entire pipeline cleanly"
  (throw 'abort-pipeline :aborted))

;;; ============================================================
;;; ERROR HANDLING WRAPPERS
;;; ============================================================

(defmacro with-frbr-error-handling ((&key article-number layer) &body body)
  "Execute body with FRBR error handling and restarts

   Usage:
     (with-frbr-error-handling (:article-number 1 :layer 'work)
       (generate-work-layer article-1-data))"

  (alexandria:with-gensyms (retry-tag block-name)
    `(block ,block-name
       (tagbody ,retry-tag
         (return-from ,block-name
           (restart-case
               (handler-bind
                   ((frbr-generation-error
                      (lambda (condition)
                        ;; Record in metrics
                        (orchestrator.meta:record-error-event
                          :article-number ,article-number
                          :layer ,layer
                          :condition condition)

                        ;; Don't handle here - let restarts handle it
                        nil)))

                 ;; Execute body
                 (progn ,@body))

             ;; RESTART: Skip this article
             (skip-article ()
               :report (lambda (stream)
                         (format stream "Skip article ~A and continue pipeline"
                                 ,article-number))
               (skip-article-restart ,article-number))

             ;; RESTART: Use default/empty output
             (use-default ()
               :report "Use default empty output and continue"
               (use-default-value-restart ""))

             ;; RESTART: Retry generation
             (retry ()
               :report "Retry generation with same data"
               (go ,retry-tag))

             ;; RESTART: Abort pipeline
             (abort-pipeline ()
               :report "Abort entire pipeline cleanly"
               (abort-pipeline-restart))))))))

;;; ============================================================
;;; VALIDATION WITH RESTARTS
;;; ============================================================

(defun validate-article-data (article-data article-number)
  "Validate article data with restart options
   
   Returns: T if valid
   Signals: article-data-missing with restarts"
  
  (restart-case
      (progn
        ;; Check required fields
        (unless (gethash :title article-data)
          (error 'article-data-missing
                 :article-number article-number
                 :data-key :title
                 :message "Article title is missing"))
        
        (unless (gethash :content article-data)
          (error 'article-data-missing
                 :article-number article-number
                 :data-key :content
                 :message "Article content is missing"))
        
        t)
    
    ;; RESTART: Provide default title
    (use-default-title ()
      :report "Use default title 'Άρθρο N' and continue"
      (setf (gethash :title article-data) 
            (format nil "Άρθρο ~A" article-number))
      t)
    
    ;; RESTART: Provide default content
    (use-default-content ()
      :report "Use empty content and continue"
      (setf (gethash :content article-data) "")
      t)))

;;; ============================================================
;;; FILE OPERATIONS WITH RESTARTS
;;; ============================================================

(defun write-rdf-file-safe (filepath content &key (article-number nil) authority)
  "Write RDF file with error handling and restarts

   Args:
     filepath: Output file path
     content: RDF/TTL string content
     article-number: Optional article number for error messages
     authority: REQUIRED - :canonical or :provenance

   Returns: Pathname if successful
   Signals: file-write-error with restarts"

  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :canonical or :authority :provenance"))

  (restart-case
      (handler-case
          (progn
            ;; Write file via unified authority
            (orchestrator.write-authority:emit-graph content filepath :authority authority)

            ;; Verify write
            (unless (probe-file filepath)
              (error 'file-write-error
                     :filepath filepath
                     :article-number article-number
                     :message "File not found after write"))

            ;; Return pathname
            (truename filepath))

        ;; Handle OS-level errors
        (file-error (e)
          (error 'file-write-error
                 :filepath filepath
                 :article-number article-number
                 :message (format nil "File error: ~A" e))))

    ;; RESTART: Skip this file
    (skip-file ()
      :report (lambda (stream)
                (format stream "Skip writing file ~A and continue" filepath))
      nil)

    ;; RESTART: Retry write
    (retry-write ()
      :report "Retry writing the file"
      (write-rdf-file-safe filepath content :article-number article-number :authority authority))

    ;; RESTART: Write to alternate location
    (use-alternate-path (alternate)
      :report "Write to alternate file path"
      :interactive (lambda ()
                     (format t "Enter alternate path: ")
                     (list (read-line)))
      (write-rdf-file-safe alternate content :article-number article-number :authority authority))))

;;; ============================================================
;;; PIPELINE ABORT MECHANISM
;;; ============================================================

(defmacro with-abortable-pipeline (&body body)
  "Execute body with ability to abort entire pipeline cleanly
   
   Usage:
     (with-abortable-pipeline
       (process-all-articles articles))"
  
  `(catch 'abort-pipeline
     (handler-bind
         ((frbr-generation-error
            (lambda (condition)
              ;; On critical errors, offer to abort
              (when (typep condition 'file-write-error)
                (cerror "Continue anyway" condition)))))
       
       ,@body)))

;;; ============================================================
;;; EXAMPLE USAGE
;;; ============================================================

#|

EXAMPLE 1: Article processing with restarts

(with-frbr-error-handling (:article-number 1 :layer 'work)
  (let* ((data (get-article-data 1))
         (work (make-frbr-work :article-number 1))
         (rdf (generate-rdf work)))
    
    (write-rdf-file-safe 
      "/output/article-001.work.ttl" 
      rdf 
      :article-number 1)))

If error occurs:
1. User sees: "Article Data Missing - Article: 1 - Missing: :title"
2. Available restarts:
   - Skip article 1 and continue pipeline
   - Use default title 'Άρθρο 1' and continue
   - Retry generation with same data
   - Abort entire pipeline cleanly

EXAMPLE 2: Batch processing with abort

(with-abortable-pipeline
  (loop for article-num from 1 to 120
        do (with-frbr-error-handling (:article-number article-num)
             (process-article article-num))))

EXAMPLE 3: Interactive debugging

CL-USER> (generate-frbr-layers context)
;; Error: Article Data Missing - Article: 5 - Missing: :content
;; Available restarts:
;;   0: [SKIP-ARTICLE] Skip article 5 and continue pipeline
;;   1: [USE-DEFAULT] Use default empty output and continue
;;   2: [RETRY] Retry generation with same data
;;   3: [ABORT-PIPELINE] Abort entire pipeline cleanly
;;   4: [ABORT] Abort to debugger

CL-USER> :0  ; Choose restart 0 (skip article)
;; => :SKIPPED
;; Pipeline continues with article 6...

|#

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(frbr-generation-error
          invalid-frbr-instance
          article-data-missing
          rdf-output-invalid
          file-write-error
          unified-generation-error
          with-frbr-error-handling
          with-abortable-pipeline
          validate-article-data
          write-rdf-file-safe
          skip-article-restart
          use-default-value-restart
          retry-generation-restart
          abort-pipeline-restart))
