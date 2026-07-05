;;;; systems/orchestrator-spec/protocols.lisp
;;;; Generic function protocols for Orchestrator

(in-package :orchestrator.spec)

;;; ============================================================================
;;; PIPELINE PROTOCOLS
;;; ============================================================================

(defgeneric run-pipeline (pipeline context)
  (:documentation "Execute a complete pipeline with given context
  
  Args:
    pipeline: Pipeline object or name
    context: Pipeline execution context
  
  Returns:
    Pipeline execution result with artifacts and metadata"))

(defgeneric run-stage (stage context)
  (:documentation "Execute a single pipeline stage
  
  Args:
    stage: Stage object or name
    context: Execution context
  
  Returns:
    Stage result with produced artifacts"))

(defgeneric validate-pipeline (pipeline)
  (:documentation "Validate pipeline structure and dependencies
  
  Args:
    pipeline: Pipeline to validate
  
  Returns:
    T if valid, signals error otherwise"))

(defgeneric introspect-pipeline (pipeline)
  (:documentation "Return introspection information about pipeline
  
  Args:
    pipeline: Pipeline to introspect
  
  Returns:
    Plist with pipeline metadata, stages, dependencies, etc."))

;;; ============================================================================
;;; ARTIFACT PROTOCOLS
;;; ============================================================================

(defgeneric build-artifact (artifact-type source context)
  (:documentation "Build an artifact from source material
  
  Args:
    artifact-type: Type of artifact to build (:rdf-turtle, :json-ld, etc.)
    source: Source object (article, corpus, etc.)
    context: Build context
  
  Returns:
    Built artifact object"))

(defgeneric serialize-artifact (artifact format)
  (:documentation "Serialize artifact to specified format
  
  Args:
    artifact: Artifact to serialize
    format: Output format (:string, :stream, :file)
  
  Returns:
    Serialized representation"))

(defgeneric deserialize-artifact (artifact-type data)
  (:documentation "Deserialize artifact from data
  
  Args:
    artifact-type: Type of artifact
    data: Serialized data
  
  Returns:
    Deserialized artifact object"))

(defgeneric anchor-artifact (artifact backend options)
  (:documentation "Anchor artifact to blockchain or permanent storage
  
  Args:
    artifact: Artifact to anchor
    backend: Backend type (:ethereum, :arweave, :ipfs)
    options: Backend-specific options
  
  Returns:
    Proof of anchoring (transaction hash, content ID, etc.)"))

(defgeneric artifact-dependencies (artifact)
  (:documentation "Return list of artifacts this artifact depends on
  
  Args:
    artifact: Artifact to analyze
  
  Returns:
    List of artifact dependencies"))

(defgeneric artifact-hash (artifact &optional algorithm)
  (:documentation "Compute cryptographic hash of artifact
  
  Args:
    artifact: Artifact to hash
    algorithm: Hash algorithm (:blake3, :sha256, etc.)
  
  Returns:
    Hexadecimal hash string"))

;;; ============================================================================
;;; STATE TRANSITION PROTOCOLS
;;; ============================================================================

(defgeneric valid-transition-p (from-state to-state)
  (:documentation "Check if state transition is valid
  
  Args:
    from-state: Current state
    to-state: Target state
  
  Returns:
    T if transition is valid, NIL otherwise"))

(defgeneric transition (object new-state &optional metadata)
  (:documentation "Transition object to new state
  
  Args:
    object: Object to transition (article, pipeline, etc.)
    new-state: Target state
    metadata: Optional metadata about transition
  
  Returns:
    New state"))

;;; ============================================================================
;;; CORPUS PROTOCOLS
;;; ============================================================================

(defgeneric add-article (corpus article)
  (:documentation "Add article to corpus
  
  Args:
    corpus: Corpus instance
    article: Article to add
  
  Returns:
    Article"))

(defgeneric get-article (corpus article-id)
  (:documentation "Retrieve article from corpus
  
  Args:
    corpus: Corpus instance
    article-id: Article identifier (number, URI, etc.)
  
  Returns:
    Article or NIL if not found"))

(defgeneric corpus-article-count (corpus)
  (:documentation "Return total number of articles in corpus
  
  Args:
    corpus: Corpus instance
  
  Returns:
    Integer count"))

;;; ============================================================================
;;; VALIDATION PROTOCOLS
;;; ============================================================================

(defgeneric validate-article (article validator-type)
  (:documentation "Validate article using specified validator
  
  Args:
    article: Article to validate
    validator-type: Type of validation (:shacl, :schema, etc.)
  
  Returns:
    Validation result (T/NIL or detailed report)"))

(defgeneric validate-artifact (artifact validator-type)
  (:documentation "Validate artifact
  
  Args:
    artifact: Artifact to validate
    validator-type: Validation type
  
  Returns:
    Validation result"))
