;;;; orchestrator-omega.asd
;;;; ΟΜΕΓΑ-LEVEL ASDF System Definition v1.3
;;;; DARPA-class FRBR generation modules
;;;;
;;;; Homoiconic power: This system leverages the full 
;;;; expressiveness of Common Lisp's macro system,
;;;; CLOS with MOP, conditions/restarts, and compiler declarations.

(in-package :asdf-user)

(defsystem "orchestrator-omega"
  :version "1.3.0"
  :description "ΟΜΕΓΑ-level FRBR generation modules - DARPA-class semantic web generation"
  :author "Spyridon Stavropoulos (Athens Bar Association) <spyridon@stavropouloslaw.com>"
  :license "All Rights Reserved"
  
  ;; ══════════════════════════════════════════════════════════
  ;; DEPENDENCIES - Core CL libraries for ΟΜΕΓΑ implementation
  ;; ══════════════════════════════════════════════════════════
  :depends-on (#:orchestrator-infrastructure ; FF1: orchestrator.paths (ρίζα Ιδρύματος)
               #:orchestrator-meta   ; Metrics package
               #:alexandria          ; Utilities
               #:serapeum            ; Extended utilities
               #:closer-mop          ; MOP portability
               #:bordeaux-threads    ; Threading primitives
               #:trivial-garbage     ; GC control
               #:ironclad            ; Cryptographic hashing (SHA-256)
               #:cl-ppcre            ; Advanced regex for paragraph parsing
               #:cl-yaml             ; YAML config parsing (LEVEL 300)
               #:babel               ; UTF-8 encoding
               #+sbcl #:sb-concurrency)
  
  ;; ══════════════════════════════════════════════════════════
  ;; COMPILER DECLARATIONS - Performance optimization
  ;; ══════════════════════════════════════════════════════════
  :perform (compile-op :before (op c)
             (proclaim '(optimize (speed 3) (safety 1) (debug 1) (compilation-speed 0))))
  
  ;; ══════════════════════════════════════════════════════════
  ;; PATHNAME - All modules in omega directory
  ;; ══════════════════════════════════════════════════════════
  :pathname "systems/orchestrator-omega-modules/"
  
  ;; ══════════════════════════════════════════════════════════
  ;; COMPONENTS - Layered architecture with explicit dependencies
  ;; Serial loading ensures correct initialization order
  ;; ══════════════════════════════════════════════════════════
  :serial t
  
  :components
  (;;; ────────────────────────────────────────────────────────
   ;;; LAYER 0: Foundation - Metrics interface & Config
   ;;; ────────────────────────────────────────────────────────
   (:file "metrics-stub")
   (:file "config-accessor")       ; LEVEL 300: YAML config loader
   (:file "greek-law-types")       ; ELI-compliant registry of all Greek law types

   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 1: CLOS Model - MOP metaclass + FRBR class hierarchy
   ;;; Uses: defclass, define-method-combination, validate-superclass
   ;;; ────────────────────────────────────────────────────────
   (:file "frbr-classes")
   (:file "frbr-article-root")   ; NEW: Article Root Node
   (:file "prov-activity")        ; NEW: PROV-O Activity
   
   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 2: DSL - Macro-based Turtle/RDF generation
   ;;; Uses: defmacro, macrolet, symbol-macrolet, gensym
   ;;; Provides: with-turtle-output, with-resource, with-frbr-context
   ;;; ────────────────────────────────────────────────────────
   (:file "turtle-dsl")
   
   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 3: Protocol - Generic function definitions
   ;;; Uses: defgeneric with :around/:before/:after combinations
   ;;; Provides: generate-rdf, emit-triples, validate-instance
   ;;; ────────────────────────────────────────────────────────
   (:file "frbr-protocol")
   
   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 4: Conditions & Restarts - Error handling hierarchy
   ;;; Uses: define-condition, restart-case, handler-bind
   ;;; Provides: frbr-generation-error, skip-article, retry, abort
   ;;; ────────────────────────────────────────────────────────
   (:file "frbr-conditions")
   
   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 4.5: FRBR Package - Package for generator functions
   ;;; Provides: orchestrator.frbr package with exports
   ;;; ────────────────────────────────────────────────────────
   (:file "frbr-package")
   
   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 5: Generators - ΟΜΕΓΑ-level FRBR implementations
   ;;; Uses: defmethod specialization, DSL macros, conditions
   ;;; Provides: Work and Expression layer generators
   ;;; ────────────────────────────────────────────────────────
   (:file "article-root-generator-omega")       ; NEW: Article Root generator
   (:file "prov-activity-generator-omega")      ; NEW: PROV-O Activity generator
   (:file "work-generator-omega")               ; ΟΜΕΓΑ primary method: frbr-work
   (:file "expression-generator-omega")         ; ΟΜΕΓΑ primary method: frbr-expression
   (:file "manifestation-generator-omega")      ; ΟΜΕΓΑ primary method: frbr-manifestation
   (:file "format-generator-omega")             ; ΟΜΕΓΑ primary method: frbr-format
   
   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 5.5: ELI TTL Generator - Deterministic FRBR+ELI+PROV
   ;;; Supreme generator for complete article RDF output
   ;;; Uses: turtle-dsl, frbr-classes, frbr-protocol exclusively
   ;;; Provides: make-frbr-stack-for-article, render-frbr-eli-for-article
   ;;; ────────────────────────────────────────────────────────
   
   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 5.8: Validation & Canonicalization
   ;;; NEW: Cross-layer validation and deterministic ordering
   ;;; ────────────────────────────────────────────────────────
   (:file "frbr-consistency-validator")  ; NEW: Cross-layer validator
   (:file "rdf-canonicalization")        ; NEW: Canonical ordering

   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 5.9: Unified Generator - ONE FILE PER ARTICLE
   ;;; NEW: AI-ROOT-AUTHORITY CANONICAL ARTIFACT
   ;;; ────────────────────────────────────────────────────────
   (:file "unified-frbr-generator")      ; NEW: Unified generator (ΚΟΡΥΦΑΙΟ)
   (:file "corpus-root-generator")       ; NEW: Corpus-level manifest generator
   (:file "hybrid-generator-phase1")     ; HYBRID PHASE 1: Canonical Legal Corpus with SHA-256 + Paragraphs
   (:file "html-rdfa-generator")         ; PHASE 2: HTML + RDFa + JSON-LD for SEO & Google Panels

   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 6: Pipeline Integration - Orchestrator stage
   ;;; Uses: Generic protocol, parallel processing, statistics
   ;;; Provides: frbr-generation-stage, run-frbr-generation-stage
   ;;; ────────────────────────────────────────────────────────
   (:file "frbr-pipeline-stage")
   
   ;;; ────────────────────────────────────────────────────────
   ;;; LAYER 7: Package Re-exports - Unified ΟΜΕΓΑ interface
   ;;; Must load LAST after all components are loaded
   ;;; Provides: orchestrator.omega package with all exports
   ;;; ────────────────────────────────────────────────────────
   (:file "omega-package"))
  
  ;; ══════════════════════════════════════════════════════════
  ;; IN-ORDER-TO - Ensure tests run after compilation
  ;; ══════════════════════════════════════════════════════════
  :in-order-to ((test-op (test-op "orchestrator-omega/tests"))))
