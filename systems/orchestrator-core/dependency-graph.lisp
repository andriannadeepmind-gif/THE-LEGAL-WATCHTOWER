;;;; systems/orchestrator-core/dependency-graph.lisp
;;;; Dependency analysis and topological sorting

(in-package :orchestrator.core)

;;; ============================================================================
;;; DEPENDENCY GRAPH CONSTRUCTION
;;; ============================================================================

(defun build-dependency-graph (pipeline)
  "Build dependency graph for pipeline stages
  
  Args:
    pipeline: Pipeline object
  
  Returns:
    Alist of (stage-name . dependencies)"
  (loop for stage in (orchestrator.spec:pipeline-stages pipeline)
        collect (cons (orchestrator.spec:stage-name stage)
                     (orchestrator.spec:stage-dependencies stage))))

;;; ============================================================================
;;; TOPOLOGICAL SORT
;;; ============================================================================

(defun topological-sort (graph)
  "Perform topological sort on dependency graph
  
  Args:
    graph: Alist of (node . dependencies)
  
  Returns:
    List of nodes in topological order
  
  Signals:
    dependency-error if graph has cycles"
  (let ((sorted nil)
        (visited (make-hash-table :test 'eq))
        (visiting (make-hash-table :test 'eq)))
    
    (labels ((visit (node)
               ;; Check for cycles
               (when (gethash node visiting)
                 (error 'orchestrator.spec:dependency-error
                        :message (format nil "Circular dependency detected involving ~A" node)))
               
               ;; Skip if already visited
               (when (gethash node visited)
                 (return-from visit))
               
               ;; Mark as visiting
               (setf (gethash node visiting) t)
               
               ;; Visit dependencies first
               (let ((deps (cdr (assoc node graph))))
                 (dolist (dep deps)
                   (visit dep)))
               
               ;; Mark as visited and add to sorted list
               (setf (gethash node visited) t)
               (setf (gethash node visiting) nil)
               (push node sorted)))
      
      ;; Visit all nodes
      (dolist (entry graph)
        (visit (car entry)))
      
      ;; Return sorted list (reverse to get correct order)
      (nreverse sorted))))

;;; ============================================================================
;;; CIRCULAR DEPENDENCY DETECTION
;;; ============================================================================

(defun detect-circular-dependencies (graph)
  "Detect circular dependencies in graph
  
  Args:
    graph: Alist of (node . dependencies)
  
  Returns:
    List of nodes involved in cycles, or NIL if no cycles"
  (let ((cycles nil)
        (visited (make-hash-table :test 'eq))
        (rec-stack (make-hash-table :test 'eq)))
    
    (labels ((visit-node (node path)
               ;; Cycle detected
               (when (gethash node rec-stack)
                 (let ((cycle (member node (reverse path))))
                   (pushnew cycle cycles :test #'equal))
                 (return-from visit-node))
               
               ;; Already visited in another path
               (when (gethash node visited)
                 (return-from visit-node))
               
               ;; Mark as being visited
               (setf (gethash node rec-stack) t)
               
               ;; Visit dependencies
               (let ((deps (cdr (assoc node graph))))
                 (dolist (dep deps)
                   (visit-node dep (cons node path))))
               
               ;; Mark as fully visited
               (setf (gethash node visited) t)
               (setf (gethash node rec-stack) nil)))
      
      ;; Visit all nodes
      (dolist (entry graph)
        (visit-node (car entry) nil))
      
      cycles)))

;;; ============================================================================
;;; DEPENDENCY UTILITIES
;;; ============================================================================

(defun get-stage-dependencies (stage-name graph)
  "Get all dependencies (direct and transitive) for a stage
  
  Args:
    stage-name: Name of stage
    graph: Dependency graph
  
  Returns:
    List of all dependencies"
  (let ((deps (make-hash-table :test 'eq)))
    (labels ((collect-deps (node)
               (unless (gethash node deps)
                 (setf (gethash node deps) t)
                 (let ((direct-deps (cdr (assoc node graph))))
                   (dolist (dep direct-deps)
                     (collect-deps dep))))))
      (collect-deps stage-name)
      (remhash stage-name deps)
      (alexandria:hash-table-keys deps))))

(defun stages-ready-to-execute (executed-stages graph)
  "Get list of stages ready to execute based on what's been executed
  
  Args:
    executed-stages: Set of already executed stage names
    graph: Dependency graph
  
  Returns:
    List of stage names ready to execute"
  (let ((ready nil))
    (dolist (entry graph)
      (let ((stage-name (car entry))
            (deps (cdr entry)))
        (unless (member stage-name executed-stages)
          (when (every (lambda (dep) (member dep executed-stages)) deps)
            (push stage-name ready)))))
    ready))

(defun execution-order (graph)
  "Determine execution order for stages
  
  Args:
    graph: Dependency graph
  
  Returns:
    List of stages in execution order"
  (topological-sort graph))

;;; ============================================================================
;;; GRAPH QUERIES
;;; ============================================================================

(defun find-leaf-stages (graph)
  "Find stages with no dependencies (leaf nodes)
  
  Args:
    graph: Dependency graph
  
  Returns:
    List of leaf stage names"
  (loop for (stage . deps) in graph
        when (null deps)
        collect stage))

(defun find-root-stages (graph)
  "Find stages that no other stage depends on (root nodes)
  
  Args:
    graph: Dependency graph
  
  Returns:
    List of root stage names"
  (let ((all-stages (mapcar #'car graph))
        (depended-on (make-hash-table :test 'eq)))
    ;; Mark all stages that are depended on
    (dolist (entry graph)
      (dolist (dep (cdr entry))
        (setf (gethash dep depended-on) t)))
    ;; Return stages not depended on
    (remove-if (lambda (stage) (gethash stage depended-on))
               all-stages)))

(defun dependency-depth (stage-name graph)
  "Calculate dependency depth for a stage
  
  Args:
    stage-name: Name of stage
    graph: Dependency graph
  
  Returns:
    Maximum depth (0 for leaves, increases with dependencies)"
  (let ((memo (make-hash-table :test 'eq)))
    (labels ((calc-depth (node)
               (or (gethash node memo)
                   (let ((deps (cdr (assoc node graph))))
                     (setf (gethash node memo)
                           (if (null deps)
                               0
                               (1+ (reduce #'max (mapcar #'calc-depth deps)
                                          :initial-value 0))))))))
      (calc-depth stage-name))))
