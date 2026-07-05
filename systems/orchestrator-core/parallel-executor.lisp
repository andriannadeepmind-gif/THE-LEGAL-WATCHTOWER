;;;; systems/orchestrator-core/parallel-executor.lisp
;;;; Parallel pipeline executor using lparallel

(in-package :orchestrator.core)

;;; ============================================================================
;;; PARALLEL EXECUTOR
;;; ============================================================================

(defclass parallel-executor ()
  ((max-retries
    :accessor executor-max-retries
    :initarg :max-retries
    :initform 3
    :type integer
    :documentation "Maximum retries per stage")
   (worker-count
    :accessor executor-worker-count
    :initarg :worker-count
    :initform 4
    :type integer
    :documentation "Number of parallel workers"))
  (:documentation "Parallel pipeline executor"))

(defmethod execute-pipeline ((executor parallel-executor) pipeline context)
  "Execute pipeline using parallel executor where possible
  
  Args:
    executor: Parallel executor instance
    pipeline: Pipeline to execute
    context: Execution context
  
  Returns:
    Context with results"
  (add-trace-entry context "Starting parallel pipeline execution" 
                  (list :pipeline (orchestrator.spec:pipeline-name pipeline)
                        :workers (executor-worker-count executor)))
  
  ;; Build dependency graph
  (let* ((graph (build-dependency-graph pipeline))
         (stages (orchestrator.spec:pipeline-stages pipeline))
         (executed (make-hash-table :test 'eq))
         (kernel (lparallel:make-kernel (executor-worker-count executor))))
    
    (unwind-protect
         (loop
           ;; Find stages ready to execute (all dependencies met)
           (let ((ready (stages-ready-to-execute 
                        (alexandria:hash-table-keys executed)
                        graph)))
             
             (when (null ready)
               ;; Check if we're done
               (if (= (hash-table-count executed) (length stages))
                   (return context)
                   ;; Otherwise we're stuck (circular dependency or error)
                   (error 'orchestrator.spec:dependency-error
                          :message "Pipeline execution stalled - possible circular dependency")))
             
             (add-trace-entry context "Executing stages in parallel" 
                            (list :stages ready))
             
             ;; Execute ready stages in parallel
             (let ((futures
                    (loop for stage-name in ready
                          for stage = (find stage-name stages
                                          :key #'orchestrator.spec:stage-name)
                          when stage
                          collect (cons stage-name
                                       (lparallel:future
                                         (handler-case
                                             (execute-stage executor stage context)
                                           (error (e)
                                             (record-error context
                                                         (list :stage stage-name
                                                               :error e
                                                               :timestamp (orchestrator.time:now :source :system)))
                                             (add-trace-entry context "Stage failed in parallel" 
                                                            (list :stage stage-name
                                                                  :error (princ-to-string e)))
                                             nil)))))))
               
               ;; Wait for all futures to complete
               (dolist (future-pair futures)
                 (let ((stage-name (car future-pair))
                       (future (cdr future-pair)))
                   (lparallel:force future)
                   (setf (gethash stage-name executed) t))))))
      
      ;; Cleanup
      (lparallel:end-kernel :wait t))
    
    (add-trace-entry context "Parallel pipeline execution completed")
    context))

;;; ============================================================================
;;; BATCH PROCESSING
;;; ============================================================================

(defun process-articles-parallel (articles stage-fn context &key (workers 4))
  "Process multiple articles in parallel using a stage function
  
  Args:
    articles: List of articles to process
    stage-fn: Function to apply to each article
    context: Pipeline context
    workers: Number of parallel workers
  
  Returns:
    List of results"
  (let ((kernel (lparallel:make-kernel workers)))
    (unwind-protect
         (let ((futures
                (mapcar (lambda (article)
                         (lparallel:future
                           (handler-case
                               (funcall stage-fn context article)
                             (error (e)
                               (record-error context
                                           (list :article (orchestrator.model:article-number article)
                                                 :error e))
                               nil))))
                       articles)))
           (mapcar #'lparallel:force futures))
      (lparallel:end-kernel :wait t))))

;;; ============================================================================
;;; PARALLEL UTILITIES
;;; ============================================================================

(defun parallel-map (function list &key (workers 4))
  "Parallel map operation
  
  Args:
    function: Function to apply
    list: List of items
    workers: Number of workers
  
  Returns:
    List of results"
  (let ((kernel (lparallel:make-kernel workers)))
    (unwind-protect
         (lparallel:pmapcar function list)
      (lparallel:end-kernel :wait t))))

(defun parallel-filter (predicate list &key (workers 4))
  "Parallel filter operation
  
  Args:
    predicate: Predicate function
    list: List of items
    workers: Number of workers
  
  Returns:
    Filtered list"
  (let ((kernel (lparallel:make-kernel workers)))
    (unwind-protect
         (remove-if-not predicate list)
      (lparallel:end-kernel :wait t))))
