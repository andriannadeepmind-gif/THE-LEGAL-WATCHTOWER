;;;; systems/orchestrator-omega-modules/prov-activity-generator-omega.lisp
;;;; PROV-O Activity RDF Generator
;;;; ΟΜΕΓΑ-LEVEL: Research-grade provenance
;;;;
;;;; Generates complete PROV-O Activity RDF for article generation process.
;;;;
;;;; Output includes:
;;;;   - Activity type declarations
;;;;   - Temporal bounds (startedAtTime, endedAtTime)
;;;;   - Agent associations (software + human)
;;;;   - Input usage (source text)
;;;;   - Custom properties (articleNumber, corpusShortName)

(in-package :orchestrator.spec)

;;; ============================================================
;;; PROV-O ACTIVITY RDF GENERATION
;;; ============================================================

(defmethod generate-rdf ((activity orchestrator.model:prov-activity))
  "Generate RDF for PROV-O Activity - DETERMINISTIC

   Property Order (DETERMINISTIC):
     1. Type declarations
     2. PROV-O temporal properties (alphabetical)
     3. PROV-O relationship properties (alphabetical)
     4. Custom properties (alphabetical)"

  (with-output-to-string (*standard-output*)
    (let ((uri (orchestrator.model:resource-uri activity))
          (article-num (orchestrator.model:activity-article-number activity))
          (corpus (orchestrator.model:activity-corpus-name activity))
          (start (orchestrator.model:activity-start-time activity))
          (end (orchestrator.model:activity-end-time activity))
          (software (orchestrator.model:activity-software-agent activity))
          (human (orchestrator.model:activity-human-agent activity))
          (source (orchestrator.model:activity-source-text-uri activity)))

      ;; Resource opening
      (format t "<~A>~%" uri)

      ;; 1. TYPE DECLARATIONS
      (format t "    a prov:Activity ,~%")
      (format t "      stavropouloslaw:FRBRGenerationActivity ;~%")
      (format t "~%")

      ;; 2. PROV-O TEMPORAL PROPERTIES (alphabetical)
      (format t "    # Temporal Bounds~%")
      (format t "    prov:endedAtTime ~S^^xsd:dateTime ;~%" end)
      (format t "    prov:startedAtTime ~S^^xsd:dateTime ;~%" start)
      (format t "~%")

      ;; 3. PROV-O RELATIONSHIP PROPERTIES (alphabetical)
      (format t "    # Agent Associations~%")
      (format t "    prov:wasAssociatedWith <~A> ,~%" software)
      (format t "                           <~A> ;~%" human)
      (format t "~%")

      ;; Source text (if provided)
      (when source
        (format t "    # Input Sources~%")
        (format t "    prov:used <~A> ;~%" source)
        (format t "~%"))

      ;; 4. CUSTOM PROPERTIES (alphabetical)
      (format t "    # Custom Properties~%")
      (format t "    stavropouloslaw:articleNumber ~D ;~%" article-num)
      (format t "    stavropouloslaw:corpusShortName ~S~%" corpus)

      ;; Resource closing
      (format t " .~%")
      (format t "~%"))))

;;; ============================================================
;;; VALIDATION
;;; ============================================================

(defmethod validate-instance ((activity orchestrator.model:prov-activity))
  "Validate PROV-O Activity instance (primary method)"

  (unless (slot-boundp activity 'orchestrator.model::article-number)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Activity missing article-number"
           :instance activity))

  (unless (slot-boundp activity 'orchestrator.model::start-time)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Activity missing start-time"
           :instance activity))

  (unless (slot-boundp activity 'orchestrator.model::end-time)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Activity missing end-time"
           :instance activity))

  (unless (slot-boundp activity 'orchestrator.model::uri)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Activity missing URI"
           :instance activity))

  t)

;;; ============================================================
;;; UTILITY - WRITE ACTIVITY TO FILE
;;; ============================================================

(defun write-prov-activity-layer (activity output-dir &key authority)
  "Write PROV-O Activity RDF to file

   Generates: article-NNN.activity.ttl

   Arguments:
     activity:   prov-activity instance
     output-dir: Output directory path
     authority:  REQUIRED - :canonical or :provenance

   Returns:
     File path if successful, NIL if failed"

  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :canonical or :authority :provenance"))

  (handler-case
      (let* ((article-num (orchestrator.model:activity-article-number activity))
             (filename (format nil "article-~3,'0D.activity.ttl" article-num))
             (filepath (merge-pathnames filename output-dir))
             (rdf-content (generate-rdf activity)))

        ;; Validate RDF content
        (unless (search "prov:Activity" rdf-content)
          (error "Generated RDF missing prov:Activity type"))

        (unless (search "prov:startedAtTime" rdf-content)
          (error "Generated RDF missing prov:startedAtTime"))

        ;; Write file via unified authority
        (orchestrator.write-authority:emit-graph rdf-content filepath :authority authority)

        filepath)

    (error (e)
      nil)))

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(write-prov-activity-layer))
