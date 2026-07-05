;;;; systems/orchestrator-spec/introspection.lisp
;;;; Introspection API for pipelines and stages

(in-package :orchestrator.spec)

;;; ============================================================================
;;; PIPELINE INTROSPECTION
;;; ============================================================================

(defmethod describe-pipeline ((pipeline-name symbol))
  "Describe a pipeline by name"
  (let ((pipeline (find-pipeline pipeline-name)))
    (if pipeline
        (describe-pipeline pipeline)
        (error "Pipeline not found: ~A" pipeline-name))))

(defmethod describe-pipeline ((pipeline pipeline))
  "Describe a pipeline object"
  (list :name (pipeline-name pipeline)
        :stages (mapcar #'stage-name (pipeline-stages pipeline))
        :corpus (pipeline-corpus pipeline)
        :config (pipeline-config pipeline)
        :metadata (pipeline-metadata pipeline)
        :stage-count (length (pipeline-stages pipeline))))

;;; ============================================================================
;;; STAGE INTROSPECTION
;;; ============================================================================

(defmethod describe-stage ((stage-name symbol))
  "Describe a stage by name"
  (let ((stage (find-stage stage-name)))
    (if stage
        (describe-stage stage)
        (error "Stage not found: ~A" stage-name))))

(defmethod describe-stage ((stage stage))
  "Describe a stage object"
  (list :name (stage-name stage)
        :function (stage-function stage)
        :dependencies (stage-dependencies stage)
        :produces (stage-produces stage)
        :handlers (mapcar #'car (stage-condition-handlers stage))))

;;; ============================================================================
;;; DEPENDENCY ANALYSIS
;;; ============================================================================

(defun pipeline-dependency-graph (pipeline)
  "Build dependency graph for pipeline stages
  
  Returns: Alist of (stage-name . dependencies)"
  (loop for stage in (pipeline-stages pipeline)
        collect (cons (stage-name stage)
                     (stage-dependencies stage))))

(defun stage-artifact-flow (pipeline)
  "Analyze artifact flow through pipeline stages
  
  Returns: Alist of (stage-name . (consumes . produces))"
  (loop for stage in (pipeline-stages pipeline)
        collect (cons (stage-name stage)
                     (cons (compute-stage-consumes stage pipeline)
                           (stage-produces stage)))))

(defun compute-stage-consumes (stage pipeline)
  "Compute what artifacts a stage consumes based on dependencies"
  (let ((deps (stage-dependencies stage)))
    (when deps
      (reduce #'append
              (mapcar (lambda (dep-name)
                       (let ((dep-stage (find dep-name (pipeline-stages pipeline)
                                             :key #'stage-name)))
                         (when dep-stage
                           (stage-produces dep-stage))))
                     deps)))))

;;; ============================================================================
;;; VALIDATION
;;; ============================================================================

(defmethod validate-pipeline ((pipeline-name symbol))
  "Validate a pipeline by name"
  (let ((pipeline (find-pipeline pipeline-name)))
    (if pipeline
        (validate-pipeline pipeline)
        (error "Pipeline not found: ~A" pipeline-name))))

(defmethod validate-pipeline ((pipeline pipeline))
  "Validate pipeline structure and dependencies
  
  Checks:
  - No circular dependencies
  - All stage dependencies exist
  - All stages have valid functions
  "
  ;; Check for circular dependencies
  (let ((graph (pipeline-dependency-graph pipeline)))
    (when (has-circular-dependencies-p graph)
      (error 'dependency-error
             :message "Pipeline has circular dependencies"
             :component (pipeline-name pipeline))))
  
  ;; Check all dependencies exist
  (let ((stage-names (mapcar #'stage-name (pipeline-stages pipeline))))
    (dolist (stage (pipeline-stages pipeline))
      (dolist (dep (stage-dependencies stage))
        (unless (member dep stage-names)
          (error 'dependency-error
                 :message (format nil "Stage ~A depends on non-existent stage ~A"
                                (stage-name stage) dep)
                 :missing-artifact dep
                 :required-by (stage-name stage))))))
  
  ;; Check all stages have functions
  (dolist (stage (pipeline-stages pipeline))
    (unless (stage-function stage)
      (error 'stage-error
             :message (format nil "Stage ~A has no function" (stage-name stage))
             :stage-name (stage-name stage))))
  
  t)

(defun has-circular-dependencies-p (graph)
  "Check if dependency graph has cycles using DFS
  
  Args:
    graph: Alist of (node . dependencies)
  
  Returns:
    T if graph has cycles, NIL otherwise"
  (let ((visited (make-hash-table :test 'eq))
        (rec-stack (make-hash-table :test 'eq)))
    (labels ((visit-node (node)
               (when (gethash node rec-stack)
                 (return-from has-circular-dependencies-p t))
               (when (gethash node visited)
                 (return-from visit-node nil))
               
               (setf (gethash node rec-stack) t)
               (setf (gethash node visited) t)
               
               (let ((deps (cdr (assoc node graph))))
                 (dolist (dep deps)
                   (visit-node dep)))
               
               (setf (gethash node rec-stack) nil)))
      
      (dolist (entry graph)
        (visit-node (car entry))))
    
    nil))
