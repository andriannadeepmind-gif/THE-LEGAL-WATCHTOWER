;;;; systems/orchestrator-model/artifact.lisp
;;;; ARTIFACT protocol and base class

(in-package :orchestrator.model)

;;; ============================================================================
;;; ARTIFACT CLASS
;;; ============================================================================

(defclass artifact ()
  ((name
    :accessor artifact-name
    :initarg :name
    :type symbol
    :documentation "Artifact name/identifier")
   
   (type
    :accessor artifact-output-type
    :initarg :type
    :type orchestrator.spec:artifact-type
    :documentation "Type of artifact")
   
   (content
    :accessor artifact-content
    :initarg :content
    :initform nil
    :documentation "Artifact content")
   
   (hash
    :accessor artifact-hash-value
    :initarg :hash
    :type (or null string)
    :initform nil
    :documentation "Cryptographic hash of content")
   
   (dependencies
    :accessor artifact-dependency-list
    :initarg :dependencies
    :initform nil
    :type list
    :documentation "List of artifact names this depends on")
   
   (metadata
    :accessor artifact-metadata
    :initarg :metadata
    :initform nil
    :type list
    :documentation "Additional metadata as plist")
   
   (created-at
    :accessor artifact-created-at
    :initform (orchestrator.time:now :source :system)
    :type integer
    :documentation "Creation timestamp"))
  (:metaclass artifact-class)
  (:documentation "Base artifact class"))

(defmethod print-object ((artifact artifact) stream)
  "Print artifact in readable format"
  (print-unreadable-object (artifact stream :type t :identity t)
    (format stream "~A (~A)~@[ hash:~A~]"
            (if (slot-boundp artifact 'name)
                (artifact-name artifact)
                "?")
            (if (slot-boundp artifact 'type)
                (artifact-output-type artifact)
                "?")
            (when (and (slot-boundp artifact 'hash)
                      (artifact-hash-value artifact))
              (subseq (artifact-hash-value artifact) 0 (min 8 (length (artifact-hash-value artifact))))))))

;;; ============================================================================
;;; PROTOCOL IMPLEMENTATIONS
;;; ============================================================================

(defmethod orchestrator.spec:artifact-dependencies ((artifact artifact))
  "Return list of artifact dependencies"
  (artifact-dependency-list artifact))

(defmethod orchestrator.spec:artifact-hash ((artifact artifact) &optional (algorithm :blake3))
  "Compute cryptographic hash of artifact content"
  (declare (ignore algorithm)) ; Blake3 is default
  (or (artifact-hash-value artifact)
      (when (artifact-content artifact)
        (setf (artifact-hash-value artifact)
              (compute-content-hash (artifact-content artifact))))))

(defun compute-content-hash (content)
  "Compute SHA-512 hash of content"
  (let ((text (if (stringp content)
                 content
                 (babel:octets-to-string content :encoding :utf-8))))
    (orchestrator.hash-authority:compute-hash text :algorithm :sha512)))

;;; ============================================================================
;;; SPECIFIC ARTIFACT TYPES
;;; ============================================================================

(defclass rdf-turtle-artifact (artifact)
  ()
  (:metaclass artifact-class)
  (:default-initargs :type :rdf-turtle)
  (:documentation "RDF Turtle format artifact"))

(defclass json-ld-artifact (artifact)
  ()
  (:metaclass artifact-class)
  (:default-initargs :type :json-ld)
  (:documentation "JSON-LD format artifact"))

(defclass html-rdfa-artifact (artifact)
  ()
  (:metaclass artifact-class)
  (:default-initargs :type :html-rdfa)
  (:documentation "HTML with RDFa markup artifact"))

(defclass blockchain-proof-artifact (artifact)
  ((backend
    :accessor artifact-backend
    :initarg :backend
    :type orchestrator.spec:backend-type
    :documentation "Blockchain backend"))
  (:metaclass artifact-class)
  (:default-initargs :type :blockchain-proof)
  (:documentation "Blockchain anchoring proof artifact"))

(defclass manifest-artifact (artifact)
  ()
  (:metaclass artifact-class)
  (:default-initargs :type :manifest)
  (:documentation "Corpus manifest artifact"))

;;; ============================================================================
;;; ARTIFACT BUILDERS
;;; ============================================================================

(defmethod orchestrator.spec:build-artifact ((artifact-type (eql :rdf-turtle)) source context)
  "Build RDF Turtle artifact"
  (declare (ignore context))
  (make-instance 'rdf-turtle-artifact
                 :name (intern (format nil "~A-TURTLE" (article-number source)) :keyword)
                 :content (article-rdf-turtle source)
                 :metadata (list :source-article (article-number source))))

(defmethod orchestrator.spec:build-artifact ((artifact-type (eql :json-ld)) source context)
  "Build JSON-LD artifact"
  (declare (ignore context))
  (make-instance 'json-ld-artifact
                 :name (intern (format nil "~A-JSONLD" (article-number source)) :keyword)
                 :content (article-json-ld source)
                 :metadata (list :source-article (article-number source))))

(defmethod orchestrator.spec:build-artifact ((artifact-type (eql :html-rdfa)) source context)
  "Build HTML RDFa artifact"
  (declare (ignore context))
  (make-instance 'html-rdfa-artifact
                 :name (intern (format nil "~A-HTML" (article-number source)) :keyword)
                 :content (article-html source)
                 :metadata (list :source-article (article-number source))))

;;; ============================================================================
;;; SERIALIZATION
;;; ============================================================================

(defmethod orchestrator.spec:serialize-artifact ((artifact artifact) (format (eql :string)))
  "Serialize artifact to string"
  (let ((content (artifact-content artifact)))
    (if (stringp content)
        content
        (format nil "~A" content))))

(defmethod orchestrator.spec:serialize-artifact ((artifact artifact) (format (eql :stream)))
  "Serialize artifact to stream"
  (make-string-input-stream (orchestrator.spec:serialize-artifact artifact :string)))

(defmethod orchestrator.spec:serialize-artifact ((artifact artifact) (format (eql :file)))
  "Return file path for artifact (for writing)"
  (format nil "/tmp/artifact-~A-~A.dat"
          (artifact-name artifact)
          (orchestrator.time:now :source :system)))

;;; ============================================================================
;;; DESERIALIZATION
;;; ============================================================================

(defmethod orchestrator.spec:deserialize-artifact ((artifact-type symbol) data)
  "Deserialize artifact from data"
  (make-instance 'artifact
                 :type artifact-type
                 :content data))
