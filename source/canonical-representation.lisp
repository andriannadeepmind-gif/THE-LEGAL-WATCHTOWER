;;;; source/canonical-representation.lisp
;;;; ============================================================================
;;;; CANONICAL REPRESENTATION - Deterministic Serialization Authority
;;;; ============================================================================
;;;;
;;;; Ensures reproducible hashing and signing by providing:
;;;; - Stable @id generation (deterministic from content)
;;;; - Canonical JSON serialization (RFC 8785 - JCS)
;;;; - Deterministic vector → bytes conversion
;;;; - Reproducible hash chains for JWS payloads
;;;;
;;;; CRITICAL GUARANTEE:
;;;;   Same content → Same bytes → Same hash → Same signature
;;;;
;;;; Without this layer, JSON key ordering, float precision, and whitespace
;;;; would cause different hashes for semantically identical content.
;;;;
;;;; ARCHITECTURE:
;;;; ┌─────────────────────────────────────────────────────────────────────┐
;;;; │                    CANONICAL REPRESENTATION                         │
;;;; ├─────────────────────────────────────────────────────────────────────┤
;;;; │                                                                     │
;;;; │   semantic-object                                                   │
;;;; │        │                                                            │
;;;; │        ▼                                                            │
;;;; │   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐          │
;;;; │   │ Canonicalize│────▶│  Serialize  │────▶│    Hash     │          │
;;;; │   │  (sort keys)│     │ (UTF-8 JSON)│     │  (SHA-256)  │          │
;;;; │   └─────────────┘     └─────────────┘     └──────┬──────┘          │
;;;; │                                                   │                 │
;;;; │                                                   ▼                 │
;;;; │                                           Stable @id               │
;;;; │                                           Reproducible JWS         │
;;;; └─────────────────────────────────────────────────────────────────────┘
;;;;
;;;; DARPA-GRADE: Bit-perfect reproducibility across implementations.
;;;; ============================================================================

(defpackage :orchestrator.canonical-representation
  (:use :cl)
  (:local-nicknames
   (:hash :orchestrator.hash-authority))
  (:export
   ;; Canonical serialization
   #:canonicalize-json
   #:canonical-json-bytes
   #:canonical-hash
   ;; ID generation
   #:generate-canonical-id
   #:generate-embedding-id
   #:generate-manifest-id
   ;; Vector canonicalization
   #:canonicalize-vector
   #:vector-to-canonical-bytes
   #:canonical-vector-hash
   ;; Payload preparation
   #:prepare-jws-payload
   #:prepare-signing-input
   ;; Verification
   #:verify-canonical-hash
   ;; Configuration
   #:*id-namespace*
   #:*hash-algorithm*))

(in-package :orchestrator.canonical-representation)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *id-namespace* "https://eli.stavropouloslaw.com/id/"
  "Base namespace for generated IDs")

(defvar *hash-algorithm* :sha256
  "Hash algorithm for canonical hashing (SHA-256 per W3C standards)")

(defvar *float-precision* 17
  "Decimal precision for float serialization (17 = full IEEE 754 double precision)")

;;; ============================================================================
;;; JSON CANONICALIZATION (RFC 8785 - JSON Canonicalization Scheme)
;;; ============================================================================
;;;;
;;;; RFC 8785 defines deterministic JSON serialization:
;;;; 1. Object keys sorted lexicographically (UTF-16 code units)
;;;; 2. No whitespace between tokens
;;;; 3. Numbers in shortest form without leading zeros
;;;; 4. Strings with minimal escaping
;;;; 5. UTF-8 encoding

(defun canonicalize-json (obj)
  "Canonicalize JSON object per RFC 8785 (JCS)

   Transforms JSON-like Lisp structure into canonical form:
   - Plists/alists: keys sorted lexicographically
   - Numbers: shortest representation
   - Strings: minimal escaping
   - Lists: preserved order (arrays are ordered)

   Args:
     obj: JSON-like Lisp object (plist, alist, list, string, number, etc.)

   Returns:
     Canonicalized JSON string (no whitespace, sorted keys)"

  (etypecase obj
    ;; Null
    (null "null")

    ;; Boolean
    ((eql t) "true")
    ((eql :false) "false")
    ((eql :null) "null")

    ;; Keywords (treat as strings)
    (keyword
     (canonical-json-string (string-downcase (symbol-name obj))))

    ;; Symbols (treat as strings)
    (symbol
     (canonical-json-string (string-downcase (symbol-name obj))))

    ;; Strings
    (string
     (canonical-json-string obj))

    ;; Integers
    (integer
     (format nil "~D" obj))

    ;; Floats (full precision, no trailing zeros)
    (float
     (canonical-json-number obj))

    ;; Vectors (as JSON arrays)
    (vector
     (format nil "[~{~A~^,~}]"
             (map 'list #'canonicalize-json obj)))

    ;; Lists - could be array or object (plist/alist)
    (list
     (cond
       ;; Empty list = empty array
       ((null obj) "[]")

       ;; Plist (starts with keyword)
       ((keywordp (car obj))
        (canonicalize-json-object-from-plist obj))

       ;; Alist (cons pairs)
       ((and (consp (car obj))
             (or (stringp (caar obj))
                 (keywordp (caar obj))
                 (symbolp (caar obj))))
        (canonicalize-json-object-from-alist obj))

       ;; Regular list = JSON array
       (t
        (format nil "[~{~A~^,~}]"
                (mapcar #'canonicalize-json obj)))))))

(defun canonicalize-json-object-from-plist (plist)
  "Canonicalize plist as JSON object with sorted keys"
  (let ((pairs '()))
    ;; Extract key-value pairs
    (loop for (key value) on plist by #'cddr
          do (push (cons (canonical-key-string key) value) pairs))
    ;; Sort by key (lexicographic UTF-16)
    (setf pairs (sort pairs #'string< :key #'car))
    ;; Format as JSON object
    (format nil "{~{~A~^,~}}"
            (mapcar (lambda (pair)
                      (format nil "~A:~A"
                              (canonical-json-string (car pair))
                              (canonicalize-json (cdr pair))))
                    pairs))))

(defun canonicalize-json-object-from-alist (alist)
  "Canonicalize alist as JSON object with sorted keys"
  (let ((pairs (mapcar (lambda (pair)
                         (cons (canonical-key-string (car pair))
                               (cdr pair)))
                       alist)))
    ;; Sort by key
    (setf pairs (sort pairs #'string< :key #'car))
    ;; Format as JSON object
    (format nil "{~{~A~^,~}}"
            (mapcar (lambda (pair)
                      (format nil "~A:~A"
                              (canonical-json-string (car pair))
                              (canonicalize-json (cdr pair))))
                    pairs))))

(defun canonical-key-string (key)
  "Convert key to canonical string form"
  (etypecase key
    (string key)
    (keyword (let ((name (symbol-name key)))
               ;; Handle JSON-LD style keywords like :|@context|
               (if (char= (char name 0) #\|)
                   (subseq name 1 (1- (length name)))
                   (string-downcase name))))
    (symbol (string-downcase (symbol-name key)))))

(defun canonical-json-string (str)
  "Serialize string with minimal RFC 8785 escaping"
  (with-output-to-string (out)
    (write-char #\" out)
    (loop for char across str
          do (case char
               (#\" (write-string "\\\"" out))
               (#\\ (write-string "\\\\" out))
               (#\Backspace (write-string "\\b" out))
               (#\Page (write-string "\\f" out))
               (#\Newline (write-string "\\n" out))
               (#\Return (write-string "\\r" out))
               (#\Tab (write-string "\\t" out))
               (otherwise
                (if (< (char-code char) 32)
                    ;; Control characters as \uXXXX
                    (format out "\\u~4,'0X" (char-code char))
                    (write-char char out)))))
    (write-char #\" out)))

(defun canonical-json-number (num)
  "Serialize number per RFC 8785

   - No leading zeros
   - No trailing zeros after decimal
   - Exponential notation only when shorter
   - Full precision for floats"
  (let ((str (format nil "~,17G" (coerce num 'double-float))))
    ;; Clean up Common Lisp float notation
    (setf str (cl-ppcre:regex-replace "d0$" str ""))
    (setf str (cl-ppcre:regex-replace "d" str "e"))
    ;; Remove trailing zeros after decimal
    (setf str (cl-ppcre:regex-replace "\\.0+$" str ""))
    (setf str (cl-ppcre:regex-replace "(\\.\\d*[1-9])0+$" str "\\1"))
    str))

;;; ============================================================================
;;; CANONICAL BYTES AND HASHING
;;; ============================================================================

(defun canonical-json-bytes (obj)
  "Convert object to canonical JSON bytes (UTF-8)

   Args:
     obj: JSON-like Lisp object

   Returns:
     Byte vector (UTF-8 encoded canonical JSON)"
  (babel:string-to-octets (canonicalize-json obj) :encoding :utf-8))

(defun canonical-hash (obj &key (algorithm *hash-algorithm*))
  "Compute hash of canonical JSON representation

   Args:
     obj: JSON-like Lisp object
     algorithm: Hash algorithm (:sha256, :sha512, :blake2)

   Returns:
     Hex string hash"
  (hash:compute-hash (canonical-json-bytes obj) :algorithm algorithm))

(defun verify-canonical-hash (obj expected-hash &key (algorithm *hash-algorithm*))
  "Verify that object produces expected canonical hash

   Args:
     obj: JSON-like Lisp object
     expected-hash: Expected hex string hash
     algorithm: Hash algorithm

   Returns:
     T if hash matches, NIL otherwise"
  (string= (canonical-hash obj :algorithm algorithm) expected-hash))

;;; ============================================================================
;;; ID GENERATION
;;; ============================================================================

(defun generate-canonical-id (content &key (namespace *id-namespace*) (type "object"))
  "Generate deterministic ID from content

   ID is derived from canonical hash of content, ensuring:
   - Same content always produces same ID
   - ID is globally unique (collision-resistant)
   - ID encodes content type

   Args:
     content: Content to generate ID for (any JSON-serializable object)
     namespace: Base namespace URI
     type: Object type (for ID prefix)

   Returns:
     URI string (namespace/type/hash-prefix)"

  (let* ((hash (canonical-hash content))
         (short-hash (subseq hash 0 16)))  ; 64 bits = sufficient uniqueness
    (format nil "~A~A/~A" namespace type short-hash)))

(defun generate-embedding-id (text vector &key (namespace *id-namespace*))
  "Generate deterministic ID for embedding

   ID is derived from both text content and vector, ensuring:
   - Same text + same vector = same ID
   - Different embeddings of same text get different IDs

   Args:
     text: Source text
     vector: Embedding vector

   Returns:
     URN string"

  (let* ((text-hash (hash:compute-hash
                     (babel:string-to-octets text :encoding :utf-8)
                     :algorithm :sha256))
         (vector-hash (canonical-vector-hash vector))
         (combined (format nil "~A:~A" text-hash vector-hash))
         (final-hash (hash:compute-hash
                      (babel:string-to-octets combined :encoding :utf-8)
                      :algorithm :sha256)))
    (format nil "urn:embedding:~A" (subseq final-hash 0 16))))

(defun generate-manifest-id (eli-uri text-hash &key (namespace *id-namespace*))
  "Generate deterministic manifest ID

   Args:
     eli-uri: European Legislation Identifier URI
     text-hash: SHA-256 hash of source text

   Returns:
     URN string"

  (let* ((seed (format nil "~A:~A" (or eli-uri "anonymous") text-hash))
         (seed-bytes (babel:string-to-octets seed :encoding :utf-8))
         (hash (ironclad:byte-array-to-hex-string
                (ironclad:digest-sequence :sha256 seed-bytes))))
    (format nil "urn:manifest:~A" (subseq hash 0 16))))

;;; ============================================================================
;;; VECTOR CANONICALIZATION
;;; ============================================================================

(defun canonicalize-vector (vector)
  "Canonicalize embedding vector

   Ensures consistent representation:
   - Convert to single-float array
   - Normalize precision
   - Remove NaN/Inf (replace with 0)

   Args:
     vector: Input vector (any numeric sequence)

   Returns:
     Canonical single-float vector"

  (let ((result (make-array (length vector) :element-type 'single-float)))
    (loop for i from 0 below (length vector)
          for val = (elt vector i)
          do (setf (aref result i)
                   (let ((f (coerce val 'single-float)))
                     ;; Handle special values
                     (if (or (float-nan-p f)
                             (float-infinity-p f))
                         0.0
                         f))))
    result))

(defun float-nan-p (f)
  "Check if float is NaN"
  (/= f f))

(defun float-infinity-p (f)
  "Check if float is infinity"
  (and (not (float-nan-p f))
       (> (abs f) most-positive-single-float)))

(defun vector-to-canonical-bytes (vector)
  "Convert vector to canonical byte representation

   Format: IEEE 754 binary32, little-endian
   This ensures bit-perfect reproducibility across platforms.

   Args:
     vector: Float vector

   Returns:
     Byte vector"

  (let* ((canonical (canonicalize-vector vector))
         (bytes (make-array (* 4 (length canonical))
                            :element-type '(unsigned-byte 8))))
    (loop for i from 0 below (length canonical)
          for val = (aref canonical i)
          for bits = (ieee-floats:encode-float32 val)
          for offset = (* i 4)
          do (setf (aref bytes offset) (ldb (byte 8 0) bits))
             (setf (aref bytes (+ offset 1)) (ldb (byte 8 8) bits))
             (setf (aref bytes (+ offset 2)) (ldb (byte 8 16) bits))
             (setf (aref bytes (+ offset 3)) (ldb (byte 8 24) bits)))
    bytes))

(defun canonical-vector-hash (vector &key (algorithm *hash-algorithm*))
  "Compute hash of canonical vector representation

   Args:
     vector: Float vector
     algorithm: Hash algorithm

   Returns:
     Hex string hash"

  (hash:compute-hash (vector-to-canonical-bytes vector) :algorithm algorithm))

;;; ============================================================================
;;; JWS PAYLOAD PREPARATION
;;; ============================================================================

(defun prepare-jws-payload (obj &key include-vector)
  "Prepare object for JWS signing

   Creates canonical JSON payload suitable for signing:
   - Sorted keys
   - Minimal whitespace
   - UTF-8 encoding
   - Optional vector exclusion (vectors are large)

   Args:
     obj: Object to sign (plist, alist, or struct)
     include-vector: If NIL, exclude :vector key from payload

   Returns:
     Canonical JSON string"

  (let ((payload (if (and (not include-vector)
                          (listp obj))
                     (remove-vector-from-object obj)
                     obj)))
    (canonicalize-json payload)))

(defun remove-vector-from-object (obj)
  "Remove :vector key from object for signing

   Vectors are hashed separately and referenced by hash,
   not included directly in JWS payload (too large)."

  (cond
    ;; Plist
    ((and (listp obj) (keywordp (car obj)))
     (loop for (key value) on obj by #'cddr
           unless (member key '(:vector :|vector|) :test #'eq)
           collect key
           and collect value))

    ;; Alist
    ((and (listp obj) (consp (car obj)))
     (remove-if (lambda (pair)
                  (member (car pair) '(:vector "vector" "emb:vector" :|vector|)
                          :test #'equalp))
                obj))

    ;; Other - return as-is
    (t obj)))

(defun prepare-signing-input (header payload)
  "Prepare JWS signing input per RFC 7515

   SigningInput = ASCII(BASE64URL(UTF8(JWS Protected Header)) || '.' ||
                        BASE64URL(JWS Payload))

   Args:
     header: JWS header plist
     payload: Payload object

   Returns:
     Signing input string"

  (let ((header-b64 (base64url-encode (canonical-json-bytes header)))
        (payload-b64 (base64url-encode
                      (if (stringp payload)
                          (babel:string-to-octets payload :encoding :utf-8)
                          (canonical-json-bytes payload)))))
    (format nil "~A.~A" header-b64 payload-b64)))

(defun base64url-encode (bytes)
  "Base64url encode bytes (RFC 4648 §5)"
  (let ((b64 (cl-base64:usb8-array-to-base64-string bytes)))
    ;; Convert to URL-safe: + → - / → _ remove padding
    (cl-ppcre:regex-replace-all
     "=+$"
     (cl-ppcre:regex-replace-all
      "/"
      (cl-ppcre:regex-replace-all "\\+" b64 "-")
      "_")
     "")))

;;; ============================================================================
;;; SEMANTIC OBJECT STRUCTURE
;;; ============================================================================

(defstruct semantic-object
  "Base structure for semantically-identified objects

   All semantic objects have:
   - Canonical @id (deterministic from content)
   - Content hash (for integrity verification)
   - Timestamps (creation, modification)"

  ;; Identity
  (id nil :type (or null string))              ; Canonical @id
  (type nil :type (or null string list))       ; @type(s)

  ;; Content
  (content-hash nil :type (or null string))    ; SHA-256 of canonical content

  ;; Provenance
  (created nil :type (or null integer))        ; Creation timestamp
  (modified nil :type (or null integer))       ; Last modification

  ;; Extensible properties
  (properties nil :type list))                 ; Additional key-value pairs

(defun finalize-semantic-object (obj content)
  "Finalize semantic object with canonical ID and hash

   Sets:
   - @id from content hash
   - content-hash

   Args:
     obj: semantic-object structure
     content: Content to derive ID from

   Returns:
     Modified obj"

  (let ((hash (canonical-hash content)))
    (setf (semantic-object-id obj)
          (generate-canonical-id content :type (or (semantic-object-type obj) "object")))
    (setf (semantic-object-content-hash obj) hash)
    (unless (semantic-object-created obj)
      (setf (semantic-object-created obj) (get-universal-time))))
  obj)

;;; ============================================================================
;;; END OF CANONICAL-REPRESENTATION.LISP
;;; ============================================================================
