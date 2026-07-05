;;;; systems/orchestrator-gr-syntagma/package.lisp
;;;; Package for Greek Constitution domain with DARPA-grade parsing
;;;;
;;;; BINDING COMMITMENT: Full Common Lisp utilization ≥90%
;;;; HOMOICONICITY: Code as Data - Maximum exploitation

(in-package :cl-user)

(defpackage #:orchestrator.gr-syntagma
  (:use :cl)
  (:export
   ;; Pipeline
   #:*greek-constitution-corpus*
   #:make-greek-constitution-corpus  ; kept for backward compat
   #:make-active-corpus
   #:register-greek-constitution     ; backward-compat alias
   #:register-active-corpus
   #:greek-constitution-pipeline

   ;; === DARPA-GRADE PARSING API ===

   ;; Core parsing
   #:parse-constitution-article
   #:parse-articles-batch
   #:parse-paragraph
   #:parse-clause
   #:parse-node

   ;; CLOS Classes
   #:parsed-article
   #:parsed-paragraph
   #:parsed-clause
   #:parse-result

   ;; Mixins
   #:traceable-node
   #:semantic-node

   ;; Article accessors
   #:article-number
   #:article-title
   #:article-paragraphs
   #:article-tokens
   #:article-metadata
   #:article-source-text
   #:article-parse-trace
   #:article-references-to
   #:article-referenced-by

   ;; Paragraph accessors
   #:paragraph-number
   #:paragraph-text
   #:paragraph-tokens
   #:paragraph-clauses
   #:paragraph-parent

   ;; Clause accessors
   #:clause-number
   #:clause-text
   #:clause-type
   #:clause-parent

   ;; Traceable-node accessors
   #:node-trace-id
   #:node-parent-trace-id
   #:node-source-info
   #:node-source-blocks
   #:node-page
   #:node-span-bbox
   #:node-created-at
   #:node-provenance-chain

   ;; Semantic-node accessors
   #:node-semantics
   #:node-norm-refs
   #:node-ontology-links
   #:node-legal-effect
   #:node-temporal-scope

   ;; Trace protocol
   #:make-trace
   #:extend-trace
   #:merge-traces
   #:trace-to-plist
   #:validate-trace
   #:generate-trace-id
   #:trace-to-tree

   ;; Parse result accessors
   #:parse-success-p
   #:parse-value
   #:parse-position
   #:parse-remainder
   #:parse-trace
   #:parse-result-successful-p
   #:parse-result-value
   #:parse-result-combine
   #:make-parse-success
   #:make-parse-failure

   ;; Parser combinators (functional parsing)
   #:run-parser
   #:char-parser
   #:string-parser
   #:predicate-parser
   #:regex-parser
   #:sequence-parser
   #:choice-parser
   #:many-parser
   #:optional-parser
   #:map-parser
   #:bind-parser
   #:lookahead-parser
   #:not-parser
   #:integer-parser
   #:greek-word-parser

   ;; Condition system (error handling with restarts)
   #:parse-error-condition
   #:invalid-article-form
   #:missing-paragraph
   #:semantic-annotation-error
   #:parse-error-text
   #:parse-error-position
   #:parse-error-expected
   #:parse-error-trace-id

   ;; DSL Macros
   #:with-parse-trace
   #:with-restarts-for-parsing
   #:define-article-parser
   #:match-article-header
   #:match-paragraph-number
   #:match-legal-pattern

   ;; Reader macro support
   #:enable-legal-syntax
   #:disable-legal-syntax
   #:*legal-readtable*
   #:article-reference
   #:legal-form
   #:legal-concept-ref

   ;; Semantic hooks (Level 4)
   #:add-semantics
   #:add-norm-reference
   #:add-ontology-link

   ;; Serialization
   #:serialize-node
   #:node-to-rdf

   ;; === HOMOICONICITY - Code as Data ===

   ;; Homoiconic structures
   #:homoiconic-article
   #:homoiconic-paragraph
   #:homoiconic-clause
   #:make-h-article
   #:make-h-paragraph
   #:make-h-clause

   ;; Conversion protocol
   #:node-to-sexp
   #:sexp-to-node
   #:node-to-code

   ;; Quote/Unquote macros
   #:quote-node
   #:unquote-node
   #:with-homoiconic-form
   #:transform-article

   ;; Self-modifying parsers
   #:define-self-modifying-parser

   ;; Code generation
   #:generate-validator
   #:generate-transformer
   #:embed-lisp-in-text
   #:evaluate-embedded-forms
   #:defspecification

   ;; Utilities
   #:greek-letter-p
   #:whitespace-char-p
   #:split-into-paragraphs
   #:split-into-clauses
   #:tokenize-paragraph
   #:detect-clause-type))
