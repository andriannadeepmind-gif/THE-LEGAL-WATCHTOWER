;;;; source/signed-embedding-manifest.lisp
;;;; ============================================================================
;;;; SIGNED EMBEDDING MANIFEST - Cryptographically Provable AI Artifacts
;;;; ============================================================================
;;;;
;;;; Creates exportable, signed embedding bundles with full provenance:
;;;; - Dense vector embeddings (OpenAI text-embedding-3-large)
;;;; - Rich metadata (ELI URI, ORCID, jurisdiction, timestamps)
;;;; - Multiple export formats (.jsonld, .ttl, .embedding)
;;;; - JWS cryptographic signatures for provenance proof
;;;;
;;;; ARCHITECTURE:
;;;; ┌─────────────────────────────────────────────────────────────────────┐
;;;; │                    SIGNED EMBEDDING MANIFEST                        │
;;;; ├─────────────────────────────────────────────────────────────────────┤
;;;; │  Article Text ──▶ OpenAI API ──▶ 3072-dim Vector                   │
;;;; │                        │                                            │
;;;; │  Metadata ─────────────┼──▶ EmbeddingManifest                      │
;;;; │  (ELI, ORCID, etc)     │         │                                 │
;;;; │                        │         ▼                                 │
;;;; │                        │    ┌─────────────┐                        │
;;;; │                        │    │  Export As  │                        │
;;;; │                        │    ├─────────────┤                        │
;;;; │                        │    │  .jsonld    │ ◀── AI/LLM consumption │
;;;; │                        │    │  .ttl       │ ◀── Linked Data        │
;;;; │                        │    │  .embedding │ ◀── Binary + signature │
;;;; │                        │    └─────────────┘                        │
;;;; │                        │           │                               │
;;;; │  Private Key ──────────┼───────────▼                               │
;;;; │                        │    JWS Signature                          │
;;;; │                        │    (RSA-SHA256)                           │
;;;; └─────────────────────────────────────────────────────────────────────┘
;;;;
;;;; DARPA-GRADE: Pure Lisp, cryptographic provenance, AI-optimized output.
;;;; ============================================================================

(defpackage :orchestrator.signed-embedding-manifest
  (:use :cl)
  (:local-nicknames
   (:jws :orchestrator.jws-authority)
   (:emb :orchestrator.embeddings-authority)
   (:hash :orchestrator.hash-authority)
   (:canon :orchestrator.canonical-representation))
  (:export
   ;; Manifest creation
   #:create-embedding-manifest
   #:create-corpus-manifests
   ;; Export formats
   #:export-manifest-jsonld
   #:export-manifest-ttl
   #:export-manifest-binary
   ;; Signing
   #:sign-manifest
   #:verify-manifest-signature
   ;; Loading
   #:load-signed-manifest
   ;; Configuration
   #:*default-author*
   #:*default-jurisdiction*
   #:*default-license*))

(in-package :orchestrator.signed-embedding-manifest)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *default-author*
  '(:name "Spyridon Stavropoulos"
    :orcid "0009-0005-2832-2153"
    :webid "https://stavropouloslaw.com/#spyridon"
    :affiliation "Athens Bar Association")
  "Default author metadata")

(defvar *default-jurisdiction* "GR"
  "Default jurisdiction code (ISO 3166-1 alpha-2)")

(defvar *default-license* "https://creativecommons.org/licenses/by/4.0/"
  "Default license URI")

(defvar *embedding-format-version* "1.0"
  "Version of signed embedding format")

;;; ============================================================================
;;; EMBEDDING MANIFEST STRUCTURE
;;; ============================================================================

(defstruct embedding-manifest
  "Complete embedding with metadata and provenance"
  ;; Identity
  (id nil :type (or null string))           ; Unique manifest ID (UUID)
  (eli-uri nil :type (or null string))      ; ELI URI (European Legislation Identifier)
  (canonical-url nil :type (or null string)) ; Canonical URL

  ;; Content
  (title nil :type (or null string))        ; Article/document title
  (title-el nil :type (or null string))     ; Greek title
  (text-hash nil :type (or null string))    ; SHA-256 of source text
  (text-length nil :type (or null integer)) ; Character count

  ;; Embedding
  (vector nil :type (or null vector))       ; Dense vector (3072-dim)
  (model nil :type (or null string))        ; Model used (e.g., text-embedding-3-large)
  (dimensions nil :type (or null integer))  ; Vector dimension
  (vector-hash nil :type (or null string))  ; SHA-256 of vector bytes

  ;; Provenance
  (author nil :type (or null list))         ; Author plist (:name :orcid :webid)
  (created nil :type (or null integer))     ; Creation timestamp (universal time)
  (jurisdiction nil :type (or null string)) ; Jurisdiction code
  (language nil :type (or null string))     ; Content language (ISO 639-1)
  (license nil :type (or null string))      ; License URI

  ;; Trust indicators
  (blockchain-anchor nil :type (or null string)) ; Blockchain tx hash
  (timestamp-tsr nil :type (or null vector))     ; RFC 3161 timestamp

  ;; Signature
  (jws-signature nil :type (or null string))     ; JWS compact signature
  (signature-alg nil :type (or null string))     ; Signature algorithm
  (signed-at nil :type (or null integer)))       ; Signature timestamp

;;; ============================================================================
;;; MANIFEST CREATION
;;; ============================================================================

(defun create-embedding-manifest (text &key
                                         eli-uri
                                         canonical-url
                                         title
                                         title-el
                                         (author *default-author*)
                                         (jurisdiction *default-jurisdiction*)
                                         (language "el")
                                         (license *default-license*)
                                         (model emb:*openai-model*)
                                         pre-computed-vector
                                         blockchain-anchor)
  "Create embedding manifest with full provenance metadata

   Args:
     text: Source text to embed
     eli-uri: European Legislation Identifier URI
     canonical-url: Canonical web URL
     title: English title
     title-el: Greek title
     author: Author plist (:name :orcid :webid :affiliation)
     jurisdiction: ISO 3166-1 country code
     language: ISO 639-1 language code
     license: License URI
     model: Embedding model name
     pre-computed-vector: Use existing vector instead of calling API
     blockchain-anchor: Blockchain transaction hash

   Returns:
     embedding-manifest structure"

  (let* (;; Generate or use pre-computed embedding
         (vector (or pre-computed-vector
                     (emb:embed-via-openai text :model model)))

         ;; Canonicalize vector for consistent hashing
         (canonical-vector (canon:canonicalize-vector vector))

         ;; Compute hashes for integrity (using canonical representation)
         (text-bytes (babel:string-to-octets text :encoding :utf-8))
         (text-hash (hash:compute-hash text-bytes :algorithm :sha256))
         (vector-hash (canon:canonical-vector-hash canonical-vector))

         ;; Generate deterministic manifest ID (using canonical module)
         (manifest-id (canon:generate-manifest-id eli-uri text-hash)))

    (make-embedding-manifest
     :id manifest-id
     :eli-uri eli-uri
     :canonical-url canonical-url
     :title title
     :title-el title-el
     :text-hash text-hash
     :text-length (length text)
     :vector vector
     :model model
     :dimensions (length vector)
     :vector-hash vector-hash
     :author author
     :created (get-universal-time)
     :jurisdiction jurisdiction
     :language language
     :license license
     :blockchain-anchor blockchain-anchor)))

;;; Local functions now delegate to canonical-representation module
;;; for consistent, deterministic behavior across the codebase

(defun generate-manifest-id (eli-uri text-hash)
  "Generate unique manifest ID - delegates to canonical module"
  (canon:generate-manifest-id eli-uri text-hash))

(defun compute-vector-hash (vector)
  "Compute canonical hash of vector - delegates to canonical module"
  (canon:canonical-vector-hash (canon:canonicalize-vector vector)))

;;; ============================================================================
;;; SIGNING
;;; ============================================================================

(defun sign-manifest (manifest private-key-path &key (algorithm :rs256))
  "Sign embedding manifest with JWS

   Uses canonical JSON serialization (RFC 8785) for deterministic signing.
   Same manifest always produces same signature.

   Args:
     manifest: embedding-manifest structure
     private-key-path: Path to RSA private key (PEM)
     algorithm: JWS algorithm (:rs256, :rs384, :rs512)

   Returns:
     manifest with jws-signature populated"

  (let* (;; Create signable payload (excludes vector for size)
         (payload (manifest-to-signing-payload manifest))

         ;; CRITICAL: Use canonical JSON for deterministic serialization
         ;; This ensures same content → same hash → same signature
         (payload-json (canon:canonicalize-json payload))

         ;; Sign with JWS
         (jws (jws:sign-jws payload-json
                           private-key-path
                           :algorithm algorithm
                           :detached nil)))

    ;; Update manifest with signature
    (setf (embedding-manifest-jws-signature manifest) jws)
    (setf (embedding-manifest-signature-alg manifest) (symbol-name algorithm))
    (setf (embedding-manifest-signed-at manifest) (get-universal-time))

    manifest))

(defun manifest-to-signing-payload (manifest)
  "Convert manifest to signable payload (JSON-compatible plist)"
  `(:|@context| ("https://schema.org/"
                 "https://w3id.org/security/v1"
                 ("eli" . "http://data.europa.eu/eli/ontology#")
                 ("emb" . "https://stavropouloslaw.com/vocab/embedding#"))
    :|@type| "emb:SignedEmbedding"
    :|@id| ,(embedding-manifest-id manifest)
    :|eli:id_local| ,(embedding-manifest-eli-uri manifest)
    :|url| ,(embedding-manifest-canonical-url manifest)
    :|name| ,(embedding-manifest-title manifest)
    :|name@el| ,(embedding-manifest-title-el manifest)
    :|emb:textHash| ,(embedding-manifest-text-hash manifest)
    :|emb:textLength| ,(embedding-manifest-text-length manifest)
    :|emb:model| ,(embedding-manifest-model manifest)
    :|emb:dimensions| ,(embedding-manifest-dimensions manifest)
    :|emb:vectorHash| ,(embedding-manifest-vector-hash manifest)
    :|author| (:|@type| "Person"
               :|name| ,(getf (embedding-manifest-author manifest) :name)
               :|identifier| ,(format nil "https://orcid.org/~A"
                                      (getf (embedding-manifest-author manifest) :orcid)))
    :|dateCreated| ,(format-iso8601 (embedding-manifest-created manifest))
    :|inLanguage| ,(embedding-manifest-language manifest)
    :|spatialCoverage| ,(embedding-manifest-jurisdiction manifest)
    :|license| ,(embedding-manifest-license manifest)
    :|emb:blockchainAnchor| ,(embedding-manifest-blockchain-anchor manifest)))

(define-condition signature-verification-error (error)
  ((manifest-id :initarg :manifest-id :reader error-manifest-id)
   (reason :initarg :reason :reader error-reason))
  (:report (lambda (c s)
             (format s "Signature verification failed for manifest ~A: ~A"
                     (error-manifest-id c) (error-reason c)))))

(defun verify-manifest-signature (manifest public-key-path &key (error-on-failure t))
  "Verify JWS signature on manifest

   DARPA-GRADE: Fail-safe verification. Signals error by default on failure
   to prevent callers from accidentally proceeding with unverified manifests.

   Uses canonical JSON to ensure verification matches original signing.

   Args:
     manifest: embedding-manifest with signature
     public-key-path: Path to RSA public key (PEM)
     error-on-failure: If T (default), signal error on failure. If NIL, return NIL.

   Returns:
     T if signature valid
     Signals signature-verification-error if invalid and error-on-failure is T
     Returns NIL if invalid and error-on-failure is NIL"

  (let ((jws (embedding-manifest-jws-signature manifest))
        (manifest-id (embedding-manifest-id manifest)))

    ;; No signature to verify
    (unless jws
      (if error-on-failure
          (error 'signature-verification-error
                 :manifest-id manifest-id
                 :reason "Manifest has no signature")
          (return-from verify-manifest-signature nil)))

    ;; Reconstruct payload with canonical JSON (must match signing)
    (let* ((payload (manifest-to-signing-payload manifest))
           (payload-json (canon:canonicalize-json payload))
           ;; verify-jws is (jws payload public-key) and SIGNALS on a bad/invalid
           ;; signature (it does not return NIL); normalize to a boolean here.
           (result (handler-case (jws:verify-jws jws payload-json public-key-path)
                     (error () nil))))

      ;; CRITICAL: Check verification result explicitly
      (cond
        (result
         t)  ; Success
        (error-on-failure
         (error 'signature-verification-error
                :manifest-id manifest-id
                :reason "JWS signature verification failed"))
        (t
         nil)))))

;;; ============================================================================
;;; EXPORT: JSON-LD
;;; ============================================================================

(defun export-manifest-jsonld (manifest output-path &key (include-vector nil))
  "Export manifest as JSON-LD for AI consumption

   Args:
     manifest: embedding-manifest
     output-path: Output file path
     include-vector: If T, include raw vector (large!)

   Returns:
     Output path"

  (let ((jsonld (manifest-to-jsonld manifest :include-vector include-vector)))
    (ensure-directories-exist output-path)
    (alexandria:write-string-into-file
     (jonathan:to-json jsonld)
     output-path
     :if-exists :supersede)
    output-path))

(defun manifest-to-jsonld (manifest &key include-vector)
  "Convert manifest to JSON-LD structure"
  (let ((base (manifest-to-signing-payload manifest)))
    ;; Add vector if requested
    (when include-vector
      (setf base (append base
                         `(:|emb:vector| ,(coerce (embedding-manifest-vector manifest)
                                                  'list)))))
    ;; Add signature
    (when (embedding-manifest-jws-signature manifest)
      (setf base (append base
                         `(:|proof| (:|@type| "RsaSignature2018"
                                     :|created| ,(format-iso8601
                                                  (embedding-manifest-signed-at manifest))
                                     :|jws| ,(embedding-manifest-jws-signature manifest)
                                     :|proofPurpose| "assertionMethod")))))
    base))

;;; ============================================================================
;;; EXPORT: RDF/TURTLE
;;; ============================================================================

(defun export-manifest-ttl (manifest output-path)
  "Export manifest as RDF/Turtle for Linked Data

   Args:
     manifest: embedding-manifest
     output-path: Output file path

   Returns:
     Output path"

  (let ((ttl (manifest-to-ttl manifest)))
    (ensure-directories-exist output-path)
    (alexandria:write-string-into-file ttl output-path :if-exists :supersede)
    output-path))

(defun %ttl-lit (s)
  "Escape a string for safe use inside a Turtle double-quoted literal.
   Untreated quotes/newlines/backslashes in a title or author name would
   otherwise break the RDF (or allow triple injection)."
  (with-output-to-string (o)
    (loop for ch across (princ-to-string (or s ""))
          do (case ch
               (#\" (write-string "\\\"" o)) (#\\ (write-string "\\\\" o))
               (#\Newline (write-string "\\n" o)) (#\Return (write-string "\\r" o))
               (#\Tab (write-string "\\t" o)) (#\Backspace (write-string "\\b" o))
               (#\Page (write-string "\\f" o))
               (t (if (< (char-code ch) #x20)
                      (format o "\\u~4,'0x" (char-code ch))
                      (write-char ch o)))))))

(defun manifest-to-ttl (manifest)
  "Convert manifest to RDF/Turtle"
  (format nil "@prefix schema: <https://schema.org/> .
@prefix eli: <http://data.europa.eu/eli/ontology#> .
@prefix emb: <https://stavropouloslaw.com/vocab/embedding#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix sec: <https://w3id.org/security#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<~A> a emb:SignedEmbedding ;
    eli:id_local \"~A\" ;
    schema:url <~A> ;
    schema:name \"~A\"@en ;
    schema:name \"~A\"@el ;
    emb:textHash \"~A\" ;
    emb:textLength ~D ;
    emb:model \"~A\" ;
    emb:dimensions ~D ;
    emb:vectorHash \"~A\" ;
    schema:author [
        a schema:Person ;
        schema:name \"~A\" ;
        schema:identifier <https://orcid.org/~A>
    ] ;
    schema:dateCreated \"~A\"^^xsd:dateTime ;
    schema:inLanguage \"~A\" ;
    dct:spatial \"~A\" ;
    schema:license <~A>~A .
"
          (embedding-manifest-id manifest)
          (%ttl-lit (or (embedding-manifest-eli-uri manifest) ""))
          (or (embedding-manifest-canonical-url manifest) "")
          (%ttl-lit (or (embedding-manifest-title manifest) ""))
          (%ttl-lit (or (embedding-manifest-title-el manifest) ""))
          (%ttl-lit (embedding-manifest-text-hash manifest))
          (or (embedding-manifest-text-length manifest) 0)
          (%ttl-lit (or (embedding-manifest-model manifest) ""))
          (or (embedding-manifest-dimensions manifest) 0)
          (%ttl-lit (embedding-manifest-vector-hash manifest))
          (%ttl-lit (getf (embedding-manifest-author manifest) :name ""))
          (getf (embedding-manifest-author manifest) :orcid "")
          (%ttl-lit (format-iso8601 (embedding-manifest-created manifest)))
          (%ttl-lit (or (embedding-manifest-language manifest) "el"))
          (%ttl-lit (or (embedding-manifest-jurisdiction manifest) "GR"))
          (or (embedding-manifest-license manifest) "")
          ;; Add signature triple if signed
          (if (embedding-manifest-jws-signature manifest)
              (format nil " ;~%    sec:proof [~%        a sec:RsaSignature2018 ;~%        sec:jws \"~A\"~%    ]"
                      (%ttl-lit (embedding-manifest-jws-signature manifest)))
              "")))

;;; ============================================================================
;;; EXPORT: BINARY (.embedding)
;;; ============================================================================

(defun export-manifest-binary (manifest output-path)
  "Export manifest as binary .embedding file

   Format:
     Header (64 bytes):
       - Magic: 'EMB1' (4 bytes)
       - Version: uint16 (2 bytes)
       - Flags: uint16 (2 bytes)
       - Dimensions: uint32 (4 bytes)
       - Text hash: 32 bytes (SHA-256)
       - Reserved: 20 bytes
     Vector data:
       - float32[] (dimensions * 4 bytes)
     Signature (if present):
       - Signature length: uint32 (4 bytes)
       - JWS signature: variable

   Args:
     manifest: embedding-manifest
     output-path: Output file path

   Returns:
     Output path"

  (ensure-directories-exist output-path)

  (with-open-file (out output-path
                       :direction :output
                       :element-type '(unsigned-byte 8)
                       :if-exists :supersede)
    ;; Magic number: EMB1
    (write-byte (char-code #\E) out)
    (write-byte (char-code #\M) out)
    (write-byte (char-code #\B) out)
    (write-byte (char-code #\1) out)

    ;; Version (1.0 = 0x0100)
    (write-byte #x01 out)
    (write-byte #x00 out)

    ;; Flags: bit 0 = has signature
    (let ((flags (if (embedding-manifest-jws-signature manifest) 1 0)))
      (write-byte (ldb (byte 8 0) flags) out)
      (write-byte (ldb (byte 8 8) flags) out))

    ;; Dimensions
    (let ((dim (embedding-manifest-dimensions manifest)))
      (write-byte (ldb (byte 8 0) dim) out)
      (write-byte (ldb (byte 8 8) dim) out)
      (write-byte (ldb (byte 8 16) dim) out)
      (write-byte (ldb (byte 8 24) dim) out))

    ;; Text hash (32 bytes)
    (let ((hash-hex (embedding-manifest-text-hash manifest)))
      (loop for i from 0 below 32
            for hex-pos = (* i 2)
            for byte = (parse-integer (subseq hash-hex hex-pos (+ hex-pos 2))
                                      :radix 16)
            do (write-byte byte out)))

    ;; Reserved (20 bytes)
    (loop repeat 20 do (write-byte 0 out))

    ;; Vector data
    (loop for val across (embedding-manifest-vector manifest)
          for bits = (ieee-floats:encode-float32 val)
          do (write-byte (ldb (byte 8 0) bits) out)
             (write-byte (ldb (byte 8 8) bits) out)
             (write-byte (ldb (byte 8 16) bits) out)
             (write-byte (ldb (byte 8 24) bits) out))

    ;; Signature if present
    (when (embedding-manifest-jws-signature manifest)
      (let* ((sig-bytes (babel:string-to-octets
                         (embedding-manifest-jws-signature manifest)
                         :encoding :utf-8))
             (sig-len (length sig-bytes)))
        ;; Signature length
        (write-byte (ldb (byte 8 0) sig-len) out)
        (write-byte (ldb (byte 8 8) sig-len) out)
        (write-byte (ldb (byte 8 16) sig-len) out)
        (write-byte (ldb (byte 8 24) sig-len) out)
        ;; Signature bytes
        (write-sequence sig-bytes out))))

  output-path)

;;; ============================================================================
;;; LOADING
;;; ============================================================================

(defun load-signed-manifest (input-path)
  "Load manifest from .embedding binary file

   Args:
     input-path: Path to .embedding file

   Returns:
     embedding-manifest structure"

  (with-open-file (in input-path
                      :direction :input
                      :element-type '(unsigned-byte 8))
    ;; Verify magic
    (unless (and (= (read-byte in) (char-code #\E))
                 (= (read-byte in) (char-code #\M))
                 (= (read-byte in) (char-code #\B))
                 (= (read-byte in) (char-code #\1)))
      (error "Invalid .embedding file: bad magic number"))

    ;; Version
    (let ((version-minor (read-byte in))
          (version-major (read-byte in)))
      (declare (ignore version-minor version-major)))

    ;; Flags
    (let ((flags-lo (read-byte in))
          (flags-hi (read-byte in)))
      (declare (ignore flags-hi))
      (let ((has-signature (logbitp 0 flags-lo)))

        ;; Dimensions
        (let ((dim (+ (read-byte in)
                      (ash (read-byte in) 8)
                      (ash (read-byte in) 16)
                      (ash (read-byte in) 24))))

          ;; Text hash
          (let ((hash-bytes (make-array 32 :element-type '(unsigned-byte 8))))
            (read-sequence hash-bytes in)
            (let ((text-hash (ironclad:byte-array-to-hex-string hash-bytes)))

              ;; Skip reserved
              (loop repeat 20 do (read-byte in))

              ;; Read vector
              (let ((vector (make-array dim :element-type 'single-float)))
                (loop for i from 0 below dim
                      for bits = (+ (read-byte in)
                                    (ash (read-byte in) 8)
                                    (ash (read-byte in) 16)
                                    (ash (read-byte in) 24))
                      do (setf (aref vector i) (ieee-floats:decode-float32 bits)))

                ;; Read signature if present
                (let ((jws-signature
                        (when has-signature
                          (let ((sig-len (+ (read-byte in)
                                            (ash (read-byte in) 8)
                                            (ash (read-byte in) 16)
                                            (ash (read-byte in) 24))))
                            (let ((sig-bytes (make-array sig-len
                                                         :element-type '(unsigned-byte 8))))
                              (read-sequence sig-bytes in)
                              (babel:octets-to-string sig-bytes :encoding :utf-8))))))

                  ;; Construct manifest
                  (make-embedding-manifest
                   :text-hash text-hash
                   :vector vector
                   :dimensions dim
                   :vector-hash (compute-vector-hash vector)
                   :jws-signature jws-signature))))))))))

;;; ============================================================================
;;; CORPUS PROCESSING
;;; ============================================================================

(defun create-corpus-manifests (articles output-dir &key
                                                      private-key-path
                                                      (base-url "https://eli.stavropouloslaw.com")
                                                      (model emb:*openai-model*))
  "Generate signed embedding manifests for entire corpus

   Args:
     articles: List of article objects or plists
     output-dir: Output directory
     private-key-path: RSA private key for signing (optional)
     base-url: Base URL for canonical URLs
     model: Embedding model

   Returns:
     Number of manifests created"

  (ensure-directories-exist (merge-pathnames "dummy.txt" output-dir))

  (let ((count 0)
        (total (length articles)))

    (format t "~&; Creating ~D signed embedding manifests...~%" total)

    (dolist (article articles)
      (let* ((number (if (consp article) (getf article :number) (article-number article)))
             (text (if (consp article) (getf article :text) (article-text article)))
             (title-el (if (consp article) (getf article :title-el) (article-title-el article)))
             (title-en (if (consp article) (getf article :title-en) (article-title-en article)))

             (eli-uri (format nil "~A/eli/gr/syntagma/article/~D" base-url number))
             (canonical-url (format nil "~A/article-~3,'0D.html" base-url number))

             ;; Output paths
             (jsonld-path (merge-pathnames (format nil "article-~3,'0D.jsonld" number) output-dir))
             (ttl-path (merge-pathnames (format nil "article-~3,'0D.ttl" number) output-dir))
             (emb-path (merge-pathnames (format nil "article-~3,'0D.embedding" number) output-dir)))

        (format t ";   Article ~3,'0D: creating manifest...~%" number)

        ;; Create manifest
        (let ((manifest (create-embedding-manifest text
                                                   :eli-uri eli-uri
                                                   :canonical-url canonical-url
                                                   :title title-en
                                                   :title-el title-el
                                                   :model model)))

          ;; Sign if key provided
          (when private-key-path
            (sign-manifest manifest private-key-path))

          ;; Export all formats
          (export-manifest-jsonld manifest jsonld-path)
          (export-manifest-ttl manifest ttl-path)
          (export-manifest-binary manifest emb-path)

          (incf count)
          (format t ";   Article ~3,'0D: exported to .jsonld, .ttl, .embedding~%" number))))

    (format t "~&; Created ~D signed embedding manifests~%" count)
    count))

;;; ============================================================================
;;; UTILITY FUNCTIONS
;;; ============================================================================

(defun format-iso8601 (universal-time)
  "Format universal time as ISO 8601"
  (when universal-time
    (multiple-value-bind (sec min hour day month year)
        (decode-universal-time universal-time 0)
      (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
              year month day hour min sec))))

;; Placeholder accessors (should be defined in article model)
(defun article-number (article)
  (if (listp article) (getf article :number) 1))

(defun article-text (article)
  (if (listp article) (getf article :text) ""))

(defun article-title-el (article)
  (if (listp article) (getf article :title-el) ""))

(defun article-title-en (article)
  (if (listp article) (getf article :title-en) ""))

;;; ============================================================================
;;; END OF SIGNED-EMBEDDING-MANIFEST.LISP
;;; ============================================================================
