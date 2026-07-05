;;;; systems/orchestrator-engine-sbcl/stages/validate-shacl.lisp
;;;; ============================================================================
;;;; SHACL VALIDATION STAGE (GATE-5)
;;;; ============================================================================
;;;;
;;;; Real SHACL Core validation (orchestrator.shacl): each article's emitted RDF
;;;; is parsed into a graph and validated against the shapes below. The pipeline
;;;; fails fast (signals validation-error) if any article does not conform.
;;;;
;;;; The article-root focus node is selected with sh:targetSubjectsOf
;;;; stavropouloslaw:hasWork — the property unique to the article root — and the
;;;; shape asserts the ELI/Dublin-Core/FRBR invariants the generator guarantees.
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

(defparameter +article-shacl-shapes+
  "@prefix sh: <http://www.w3.org/ns/shacl#> .
@prefix eli: <http://data.europa.eu/eli/ontology#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix slw: <https://stavropouloslaw.com/ontology#> .

slw:ArticleRootShape a sh:NodeShape ;
    sh:targetSubjectsOf slw:hasWork ;
    sh:property [ sh:path eli:number ; sh:minCount 1 ; sh:maxCount 1 ; sh:datatype xsd:integer ] ;
    sh:property [ sh:path dct:identifier ; sh:minCount 1 ; sh:maxCount 1 ; sh:datatype xsd:string ; sh:pattern \"^gr-\" ] ;
    sh:property [ sh:path dct:title ; sh:minCount 1 ] ;
    sh:property [ sh:path eli:jurisdiction ; sh:minCount 1 ; sh:nodeKind sh:IRI ] ;
    sh:property [ sh:path slw:hasWork ; sh:minCount 1 ; sh:maxCount 1 ; sh:nodeKind sh:IRI ] ;
    sh:property [ sh:path slw:hasExpression ; sh:minCount 1 ; sh:nodeKind sh:IRI ] ;
    sh:property [ sh:path slw:hasManifestation ; sh:minCount 1 ; sh:nodeKind sh:IRI ] ."
  "SHACL shapes (Turtle) for a generated article-root RDF resource.")

(defun validate-shacl-stage (context)
  "Validate every article's RDF against the SHACL shapes. Fail-fast on any
   non-conformance (GATE-5)."
  (let ((articles (orchestrator.core:get-context-value context :articles)))
    (unless articles
      (error 'orchestrator.spec:config-error
             :message "No articles in context"
             :config-key :articles))

    (log:info () "Validating ~D articles with SHACL (Core engine)" (length articles))

    (let ((shapes (orchestrator.shacl:graph-from-turtle +article-shacl-shapes+))
          (failed '()))
      (dolist (article articles)
        (let ((ttl (orchestrator.model:article-rdf-turtle article)))
          (cond
            ((null ttl)
             (push (format nil "article ~D: no RDF to validate"
                           (orchestrator.model:article-number article))
                   failed))
            (t
             (let ((report (orchestrator.shacl:validate
                            (orchestrator.shacl:graph-from-turtle ttl) shapes)))
               (cond
                 ((orchestrator.shacl:conforms-p report)
                  (orchestrator.spec:transition article :reviewing))
                 (t
                  (let ((n (length (orchestrator.shacl:validation-report-results report))))
                    (log:error () "SHACL: article ~D has ~D violation(s):~%~A"
                               (orchestrator.model:article-number article) n
                               (orchestrator.shacl:report->ttl report))
                    (push (format nil "article ~D: ~D SHACL violation(s)"
                                  (orchestrator.model:article-number article) n)
                          failed)))))))))

      (when failed
        (error 'orchestrator.spec:validation-error
               :validation-type :shacl
               :message (format nil "SHACL validation failed for ~D article(s)"
                                (length failed))
               :violations (nreverse failed)))

      (orchestrator.core:set-context-value
       context :validation-report
       (format nil "SHACL: ~D/~D articles conform" (length articles) (length articles)))
      (log:info () "SHACL validation passed: ~D/~D articles conform"
                (length articles) (length articles))
      context)))
