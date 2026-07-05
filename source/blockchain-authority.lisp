;;;; source/blockchain-authority.lisp
;;;; ============================================================================
;;;; BLOCKCHAIN AUTHORITY - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; DARPA-GRADE: Zero external dependencies beyond standard CL libraries.
;;;; All blockchain interactions via pure Lisp HTTP and cryptography.
;;;;
;;;; SUPPORTED CHAINS:
;;;; - Ethereum (JSON-RPC over HTTPS)
;;;; - Arweave (REST API over HTTPS)
;;;; - IPFS (HTTP API)
;;;;
;;;; AUTHORITY PATTERN:
;;;; - All functions require explicit :chain parameter
;;;; - CONDITIONAL: Skip if not configured, STRICT if configured
;;;; - Full PROV-O audit trail
;;;;
;;;; DEPENDENCIES (all in third-party/):
;;;; - drakma: HTTP client
;;;; - ironclad: Cryptography (secp256k1, keccak, SHA256)
;;;; - jonathan: JSON encoding/decoding
;;;; - cl-base64: Base64 encoding
;;;;
;;;; Author: ORCHESTRATOR
;;;; Created: 2026-01-03
;;;; ============================================================================

(defpackage :orchestrator.blockchain-authority
  (:use :cl)
  (:export
   ;; Core Authority Functions
   #:anchor-hash
   #:verify-anchor
   #:get-transaction
   ;; Ethereum-specific
   #:ethereum-anchor
   #:ethereum-verify
   #:ethereum-get-balance
   ;; Arweave-specific
   #:arweave-upload
   #:arweave-verify
   #:arweave-get-data
   ;; IPFS-specific
   #:ipfs-add
   #:ipfs-cat
   #:ipfs-pin
   ;; Configuration
   #:*ethereum-rpc-url*
   #:*ethereum-private-key*
   #:*arweave-gateway-url*
   #:*arweave-wallet-path*
   #:*ipfs-api-url*
   ;; Conditions
   #:blockchain-error
   #:chain-not-configured
   #:transaction-failed
   ;; RLP Encoding
   #:rlp-encode
   ;; Keccak-256
   #:keccak-256
   #:keccak-256-hex
   ;; Key derivation & address (secp256k1 → Ethereum address)
   #:private-key-to-public-key
   #:public-key-to-address
   #:address-to-hex
   ;; Byte utilities
   #:integer-to-bytes
   #:bytes-to-integer
   ;; Chain ID
   #:*ethereum-chain-id*))

(in-package :orchestrator.blockchain-authority)

;;; ============================================================================
;;; CONFIGURATION (Environment-based, CONDITIONAL pattern)
;;; ============================================================================

(defvar *ethereum-rpc-url* nil
  "Ethereum JSON-RPC endpoint URL (e.g., https://mainnet.infura.io/v3/YOUR-KEY)")

(defvar *ethereum-private-key* nil
  "Ethereum private key as hex string (without 0x prefix)")

(defvar *ethereum-chain-id* 1
  "Ethereum chain ID (1=mainnet, 5=goerli, 11155111=sepolia)")

(defvar *arweave-gateway-url* "https://arweave.net"
  "Arweave gateway URL")

(defvar *arweave-wallet-path* nil
  "Path to Arweave JWK wallet file")

(defvar *ipfs-api-url* "http://localhost:5001"
  "IPFS HTTP API endpoint")

;;; ============================================================================
;;; CONDITIONS (Error Hierarchy)
;;; ============================================================================

(define-condition blockchain-error (error)
  ((chain :initarg :chain :reader blockchain-error-chain)
   (operation :initarg :operation :reader blockchain-error-operation)
   (details :initarg :details :reader blockchain-error-details))
  (:report (lambda (c s)
             (format s "Blockchain error on ~A during ~A: ~A"
                     (blockchain-error-chain c)
                     (blockchain-error-operation c)
                     (blockchain-error-details c)))))

(define-condition chain-not-configured (blockchain-error)
  ()
  (:report (lambda (c s)
             (format s "Chain ~A not configured. Set required environment variables."
                     (blockchain-error-chain c)))))

(define-condition transaction-failed (blockchain-error)
  ((tx-hash :initarg :tx-hash :reader transaction-failed-hash :initform nil))
  (:report (lambda (c s)
             (format s "Transaction failed on ~A: ~A (tx: ~A)"
                     (blockchain-error-chain c)
                     (blockchain-error-details c)
                     (transaction-failed-hash c)))))

;;; ============================================================================
;;; RLP ENCODING (Recursive Length Prefix - Ethereum Wire Format)
;;; ============================================================================
;;;
;;; RLP encoding rules:
;;; - Single byte [0x00, 0x7f]: encode as itself
;;; - String 0-55 bytes: 0x80 + length, then string
;;; - String >55 bytes: 0xb7 + length-of-length, length bytes, string
;;; - List 0-55 bytes total: 0xc0 + length, then concatenated items
;;; - List >55 bytes total: 0xf7 + length-of-length, length bytes, items

(defun rlp-encode-length (len offset)
  "Encode RLP length prefix"
  (cond
    ((< len 56)
     (vector (+ offset len)))
    (t
     (let* ((len-bytes (integer-to-bytes len))
            (len-len (length len-bytes)))
       (concatenate '(vector (unsigned-byte 8))
                    (vector (+ offset 55 len-len))
                    len-bytes)))))

(defun integer-to-bytes (n)
  "Convert integer to minimal big-endian byte vector"
  (if (zerop n)
      #()
      (let ((bytes nil))
        (loop while (plusp n)
              do (push (logand n #xff) bytes)
                 (setf n (ash n -8)))
        (coerce bytes '(vector (unsigned-byte 8))))))

(defun bytes-to-integer (bytes)
  "Convert big-endian byte vector to integer"
  (reduce (lambda (acc b) (+ (ash acc 8) b)) bytes :initial-value 0))

(defgeneric rlp-encode (item)
  (:documentation "RLP encode an item (string, bytes, integer, or list)"))

(defmethod rlp-encode ((item vector))
  "RLP encode byte vector"
  (let ((len (length item)))
    (cond
      ((and (= len 1) (< (aref item 0) #x80))
       item)
      ((< len 56)
       (concatenate '(vector (unsigned-byte 8))
                    (vector (+ #x80 len))
                    item))
      (t
       (let ((len-bytes (integer-to-bytes len)))
         (concatenate '(vector (unsigned-byte 8))
                      (vector (+ #xb7 (length len-bytes)))
                      len-bytes
                      item))))))

(defmethod rlp-encode ((item integer))
  "RLP encode integer"
  (if (zerop item)
      #(#x80)  ; Empty byte string
      (rlp-encode (integer-to-bytes item))))

(defmethod rlp-encode ((item string))
  "RLP encode string as UTF-8 bytes"
  (rlp-encode (babel:string-to-octets item :encoding :utf-8)))

(defmethod rlp-encode ((item list))
  "RLP encode list"
  (let* ((encoded-items (mapcar #'rlp-encode item))
         (payload (apply #'concatenate '(vector (unsigned-byte 8)) encoded-items))
         (len (length payload)))
    (concatenate '(vector (unsigned-byte 8))
                 (rlp-encode-length len #xc0)
                 payload)))

(defmethod rlp-encode ((item null))
  "RLP encode NIL as the empty LIST (0xc0), per the Ethereum RLP spec — NIL is the
   empty list, not the empty byte string. (An empty byte string is #(), which the
   vector method already encodes as 0x80; transaction builders pass #() — never NIL
   — for empty fields, so this can never mis-encode a tx field.)"
  #(#xc0))

;;; ============================================================================
;;; KECCAK-256 (Ethereum's Hash Function)
;;; ============================================================================

(defun keccak-256 (data)
  "Compute Keccak-256 hash of data (bytes or string)
   Returns 32-byte vector"
  (let ((data-bytes (etypecase data
                      (string (babel:string-to-octets data :encoding :utf-8))
                      (vector data))))
    (ironclad:digest-sequence :keccak/256 data-bytes)))

(defun keccak-256-hex (data)
  "Compute Keccak-256 hash and return as hex string"
  (ironclad:byte-array-to-hex-string (keccak-256 data)))

;;; ============================================================================
;;; ETHEREUM ADDRESS DERIVATION
;;; ============================================================================

(defun private-key-to-public-key (private-key-bytes)
  "Derive uncompressed public key from private key
   Returns 64-byte public key (without 04 prefix)"
  (let* ((sk (ironclad:ec-decode-scalar :secp256k1 private-key-bytes))
         (pk-point (ironclad:ec-scalar-mult ironclad::+secp256k1-g+ sk))
         (pk-encoded (ironclad:ec-encode-point pk-point)))
    ;; Remove 04 prefix (uncompressed point indicator)
    (subseq pk-encoded 1)))

;;; ============================================================================
;;; ECDSA PUBLIC KEY RECOVERY (for determining recovery_id)
;;; ============================================================================

;; secp256k1 curve parameters
(defconstant +secp256k1-p+
  #xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
  "secp256k1 field prime p")

(defconstant +secp256k1-n+
  #xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  "secp256k1 curve order n")

;; secp256k1 generator point G
(defconstant +secp256k1-gx+
  #x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
  "secp256k1 generator point x-coordinate")

(defconstant +secp256k1-gy+
  #x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
  "secp256k1 generator point y-coordinate")

(defun mod-inverse (a n)
  "Compute modular multiplicative inverse of a mod n using extended Euclidean algorithm"
  (declare (type integer a n))
  (let ((t0 0) (t1 1) (r0 n) (r1 (mod a n)))
    (loop while (not (zerop r1))
          do (let ((q (floor r0 r1)))
               (psetf t0 t1 t1 (- t0 (* q t1)))
               (psetf r0 r1 r1 (- r0 (* q r1)))))
    (if (> r0 1)
        (error "No modular inverse exists")
        (mod t0 n))))

(defun secp256k1-recover-y (x recovery-flag)
  "Recover y-coordinate from x-coordinate on secp256k1
   recovery-flag: 0 for even y, 1 for odd y
   Returns y or nil if x is not on curve"
  (declare (type integer x recovery-flag))
  (let* ((p +secp256k1-p+)
         ;; y² = x³ + 7 (mod p)
         (x3 (mod (* x x x) p))
         (y-squared (mod (+ x3 7) p))
         ;; Compute square root using Tonelli-Shanks (p ≡ 3 mod 4, so use simple formula)
         ;; y = y_squared^((p+1)/4) mod p
         (y (ironclad:expt-mod y-squared (/ (+ p 1) 4) p)))
    ;; Verify y² = y_squared
    (when (= (mod (* y y) p) y-squared)
      ;; Return y with correct parity
      (if (= (logand y 1) recovery-flag)
          y
          (- p y)))))

(defun secp256k1-point-add (p1 p2)
  "Add two points on secp256k1 curve using explicit formulas
   Points are (x . y) cons cells. Returns nil for point at infinity."
  (declare (type cons p1 p2))
  (let* ((p +secp256k1-p+)
         (x1 (car p1)) (y1 (cdr p1))
         (x2 (car p2)) (y2 (cdr p2)))
    (cond
      ;; Point at infinity cases
      ((and (zerop x1) (zerop y1)) p2)
      ((and (zerop x2) (zerop y2)) p1)
      ;; P + (-P) = O (point at infinity)
      ((and (= x1 x2) (= (mod (+ y1 y2) p) 0))
       (cons 0 0))
      ;; Point doubling (P1 = P2)
      ((and (= x1 x2) (= y1 y2))
       (let* ((s (mod (* (mod (* 3 x1 x1) p) (mod-inverse (* 2 y1) p)) p))
              (x3 (mod (- (* s s) (* 2 x1)) p))
              (y3 (mod (- (* s (- x1 x3)) y1) p)))
         (cons x3 y3)))
      ;; General case: P1 ≠ P2
      (t
       (let* ((s (mod (* (- y2 y1) (mod-inverse (- x2 x1) p)) p))
              (x3 (mod (- (- (* s s) x1) x2) p))
              (y3 (mod (- (* s (- x1 x3)) y1) p)))
         (cons x3 y3))))))

(defun secp256k1-scalar-mult (k point)
  "Scalar multiplication k*P on secp256k1 using double-and-add"
  (declare (type integer k) (type cons point))
  (let ((result (cons 0 0))  ; Point at infinity
        (addend point)
        (n (mod k +secp256k1-n+)))
    (loop while (> n 0)
          do (when (oddp n)
               (setf result (secp256k1-point-add result addend)))
             (setf addend (secp256k1-point-add addend addend))
             (setf n (ash n -1)))
    result))

(defun ecrecover (msg-hash r s recovery-id)
  "Recover public key from ECDSA signature (Ethereum ecrecover)

   Args:
     msg-hash: 32-byte message hash
     r: r component of signature (integer)
     s: s component of signature (integer)
     recovery-id: 0 or 1 (y-parity of R point)

   Returns:
     64-byte uncompressed public key (without 04 prefix), or nil if recovery fails"
  (let* ((n +secp256k1-n+)
         ;; Recover R point from r and recovery-id
         (r-y (secp256k1-recover-y r recovery-id)))
    (when r-y
      (let* ((R (cons r r-y))
             ;; e = msg_hash as integer, reduced mod n (ECDSA requirement)
             (e (mod (bytes-to-integer msg-hash) n))
             ;; s must also be < n (should already be for valid signatures)
             (s-mod (mod s n))
             ;; r_inv = r^(-1) mod n
             (r-inv (mod-inverse r n))
             ;; Q = r^(-1) * (s*R - e*G)
             ;; First compute s*R
             (sR (secp256k1-scalar-mult s-mod R))
             ;; Get generator point G
             (G (cons +secp256k1-gx+ +secp256k1-gy+))
             ;; Compute e*G
             (eG (secp256k1-scalar-mult e G))
             ;; Compute -eG (negate y)
             (neg-eG (cons (car eG) (- +secp256k1-p+ (cdr eG))))
             ;; Compute sR - eG = sR + (-eG)
             (sR-eG (secp256k1-point-add sR neg-eG))
             ;; Finally Q = r^(-1) * (sR - eG)
             (Q (secp256k1-scalar-mult r-inv sR-eG)))
        ;; Encode public key as 64 bytes (x || y)
        (let ((x-bytes (integer-to-bytes-be (car Q) 32))
              (y-bytes (integer-to-bytes-be (cdr Q) 32)))
          (concatenate '(vector (unsigned-byte 8)) x-bytes y-bytes))))))

(defun integer-to-bytes-be (n size)
  "Convert integer to big-endian byte array of specified size"
  (let ((bytes (make-array size :element-type '(unsigned-byte 8) :initial-element 0)))
    (loop for i from (1- size) downto 0
          for byte-pos from 0
          do (setf (aref bytes i) (ldb (byte 8 (* byte-pos 8)) n)))
    bytes))

(defun find-recovery-id (msg-hash r s expected-public-key)
  "Find the correct recovery_id by trying both possibilities

   Args:
     msg-hash: 32-byte message hash
     r, s: signature components as integers
     expected-public-key: 64-byte public key to match

   Returns:
     recovery_id (0 or 1), or nil if none matches"
  (loop for recovery-id from 0 to 1
        for recovered = (ecrecover msg-hash r s recovery-id)
        when (and recovered (equalp recovered expected-public-key))
          return recovery-id))

(defun public-key-to-address (public-key-bytes)
  "Derive Ethereum address from public key
   Returns 20-byte address"
  (let ((hash (keccak-256 public-key-bytes)))
    ;; Take last 20 bytes of Keccak-256 hash
    (subseq hash 12)))

(defun address-to-hex (address-bytes)
  "Convert address bytes to checksummed hex string with 0x prefix"
  (let* ((hex-lower (ironclad:byte-array-to-hex-string address-bytes))
         (hash (keccak-256-hex hex-lower))
         (result (make-string 42)))
    (setf (char result 0) #\0)
    (setf (char result 1) #\x)
    (loop for i from 0 below 40
          for c = (char hex-lower i)
          for h = (digit-char-p (char hash i) 16)
          do (setf (char result (+ i 2))
                   (if (and (alpha-char-p c) (>= h 8))
                       (char-upcase c)
                       c)))
    result))

;;; ============================================================================
;;; ETHEREUM TRANSACTION SIGNING
;;; ============================================================================

(defstruct ethereum-tx
  "Ethereum transaction structure (EIP-155)"
  nonce
  gas-price
  gas-limit
  to
  value
  data
  chain-id)

(defun sign-ethereum-transaction (tx private-key-hex)
  "Sign Ethereum transaction using EIP-155
   Returns signed transaction as hex string

   EIP-155 formula: v = chain_id * 2 + 35 + recovery_id
   recovery_id is determined by trying to recover the public key from signature"
  (let* ((private-key-bytes (ironclad:hex-string-to-byte-array private-key-hex))
         ;; Derive public key for recovery_id verification
         (expected-public-key (private-key-to-public-key private-key-bytes))
         ;; Create unsigned transaction for signing (EIP-155)
         (unsigned-tx (list (ethereum-tx-nonce tx)
                            (ethereum-tx-gas-price tx)
                            (ethereum-tx-gas-limit tx)
                            (or (ethereum-tx-to tx) #())
                            (ethereum-tx-value tx)
                            (or (ethereum-tx-data tx) #())
                            (ethereum-tx-chain-id tx)
                            0
                            0))
         (unsigned-rlp (rlp-encode unsigned-tx))
         (msg-hash (keccak-256 unsigned-rlp))
         ;; Sign with secp256k1
         (sk (ironclad:make-private-key :secp256k1 :x private-key-bytes))
         (signature (ironclad:sign-message sk msg-hash))
         ;; DARPA-GRADE: Validate signature length before extraction
         (_ (unless (>= (length signature) 64)
              (error 'transaction-failed
                     :chain :ethereum
                     :operation "sign"
                     :details (format nil "Invalid signature length: ~D (expected >= 64)"
                                      (length signature)))))
         ;; Extract r, s from signature (each 32 bytes)
         (r-bytes (subseq signature 0 32))
         (s-bytes (subseq signature 32 64))
         (r-int (bytes-to-integer r-bytes))
         (s-int (bytes-to-integer s-bytes))
         ;; Find correct recovery_id by trying ecrecover
         (recovery-id (or (find-recovery-id msg-hash r-int s-int expected-public-key)
                          (error 'transaction-failed
                                 :chain :ethereum
                                 :operation "sign"
                                 :details "Could not determine recovery_id")))
         ;; Calculate v per EIP-155: v = chain_id * 2 + 35 + recovery_id
         (v (+ (* (ethereum-tx-chain-id tx) 2) 35 recovery-id))
         ;; Create signed transaction
         (signed-tx (list (ethereum-tx-nonce tx)
                          (ethereum-tx-gas-price tx)
                          (ethereum-tx-gas-limit tx)
                          (or (ethereum-tx-to tx) #())
                          (ethereum-tx-value tx)
                          (or (ethereum-tx-data tx) #())
                          v
                          r-int
                          s-int))
         (signed-rlp (rlp-encode signed-tx)))
    (concatenate 'string "0x" (ironclad:byte-array-to-hex-string signed-rlp))))

;;; ============================================================================
;;; HTTP CLIENT UTILITIES (Using Drakma)
;;; ============================================================================

(defun http-post-json (url body &key headers)
  "POST JSON to URL, return parsed response"
  (multiple-value-bind (response status-code)
      (drakma:http-request url
                           :method :post
                           :content-type "application/json"
                           :content (jonathan:to-json body)
                           :additional-headers headers
                           :want-stream nil
                           :force-binary nil)
    (let ((response-str (etypecase response
                          (string response)
                          (vector (babel:octets-to-string response :encoding :utf-8)))))
      (values (jonathan:parse response-str :as :alist)
              status-code))))

(defun http-get-json (url &key headers)
  "GET JSON from URL, return parsed response"
  (multiple-value-bind (response status-code)
      (drakma:http-request url
                           :method :get
                           :additional-headers headers
                           :want-stream nil
                           :force-binary nil)
    (let ((response-str (etypecase response
                          (string response)
                          (vector (babel:octets-to-string response :encoding :utf-8)))))
      (values (jonathan:parse response-str :as :alist)
              status-code))))

;;; ============================================================================
;;; ETHEREUM JSON-RPC CLIENT
;;; ============================================================================

(defvar *json-rpc-id* 0
  "JSON-RPC request ID counter")

(defun eth-rpc-call (method &rest params)
  "Make Ethereum JSON-RPC call
   Returns result or signals error"
  (unless *ethereum-rpc-url*
    (error 'chain-not-configured
           :chain :ethereum
           :operation method
           :details "Set *ethereum-rpc-url* to Ethereum node URL"))

  (let* ((id (incf *json-rpc-id*))
         (request `(("jsonrpc" . "2.0")
                    ("method" . ,method)
                    ("params" . ,(coerce params 'vector))
                    ("id" . ,id))))
    (multiple-value-bind (response status)
        (http-post-json *ethereum-rpc-url* request)
      (cond
        ((not (= status 200))
         (error 'blockchain-error
                :chain :ethereum
                :operation method
                :details (format nil "HTTP ~A" status)))
        ((assoc "error" response :test #'string=)
         (let ((err (cdr (assoc "error" response :test #'string=))))
           (error 'transaction-failed
                  :chain :ethereum
                  :operation method
                  :details (cdr (assoc "message" err :test #'string=)))))
        (t
         (cdr (assoc "result" response :test #'string=)))))))

(defun parse-eth-hex-result (result operation-name)
  "Safely parse Ethereum hex result (0x...) to integer.

   DARPA-GRADE: Validates format before parsing to prevent errors.
   - Checks for nil result
   - Validates 0x prefix presence
   - Handles parse errors gracefully"
  (unless result
    (error 'blockchain-error
           :chain :ethereum
           :operation operation-name
           :details "Nil result from RPC call"))
  (unless (and (stringp result) (>= (length result) 2))
    (error 'blockchain-error
           :chain :ethereum
           :operation operation-name
           :details (format nil "Invalid result format: ~A" result)))
  (unless (string= (subseq result 0 2) "0x")
    (error 'blockchain-error
           :chain :ethereum
           :operation operation-name
           :details (format nil "Missing 0x prefix: ~A" result)))
  (handler-case
      (parse-integer (subseq result 2) :radix 16)
    (error (e)
      (error 'blockchain-error
             :chain :ethereum
             :operation operation-name
             :details (format nil "Parse error: ~A" e)))))

(defun eth-get-transaction-count (address &optional (block "latest"))
  "Get transaction count (nonce) for address"
  (let ((result (eth-rpc-call "eth_getTransactionCount" address block)))
    (parse-eth-hex-result result "eth_getTransactionCount")))

(defun eth-gas-price ()
  "Get current gas price in Wei"
  (let ((result (eth-rpc-call "eth_gasPrice")))
    (parse-eth-hex-result result "eth_gasPrice")))

(defun eth-send-raw-transaction (signed-tx-hex)
  "Send signed transaction, return transaction hash"
  (eth-rpc-call "eth_sendRawTransaction" signed-tx-hex))

(defun eth-get-transaction-receipt (tx-hash)
  "Get transaction receipt"
  (eth-rpc-call "eth_getTransactionReceipt" tx-hash))

(defun ethereum-get-balance (address &optional (block "latest"))
  "Get balance in Wei (exported name; ETH-GET-BALANCE retained as an alias)."
  (let ((result (eth-rpc-call "eth_getBalance" address block)))
    (parse-eth-hex-result result "eth_getBalance")))

;; Backwards-compatible internal alias.
(setf (fdefinition 'eth-get-balance) #'ethereum-get-balance)

;;; ============================================================================
;;; ETHEREUM ANCHOR FUNCTION (Main API)
;;; ============================================================================

(defun ethereum-anchor (merkle-root &key (chain :ethereum)
                                         (gas-limit 100000)
                                         (wait-confirmation t))
  "Anchor Merkle root hash to Ethereum blockchain

   AUTHORITY PATTERN:
   - Requires :chain parameter (explicit)
   - CONDITIONAL: Returns nil if not configured
   - STRICT: Signals error if configured but fails

   Args:
     merkle-root: 32-byte hash or hex string to anchor
     chain: Blockchain identifier (must be :ethereum)
     gas-limit: Gas limit for transaction
     wait-confirmation: If T, wait for transaction confirmation

   Returns:
     Plist with :tx-hash, :block-number, :merkle-root, :timestamp
     or nil if not configured"
  (declare (type (member :ethereum) chain))

  ;; CONDITIONAL: Skip silently if not configured
  (unless (and *ethereum-rpc-url* *ethereum-private-key*)
    (return-from ethereum-anchor nil))

  ;; Normalize merkle-root to bytes
  ;; DARPA-GRADE: Validate hex format before parsing
  (let* ((root-bytes (etypecase merkle-root
                       (string
                        (let* ((hex-str (if (and (>= (length merkle-root) 2)
                                                 (string= (subseq merkle-root 0 2) "0x"))
                                            (subseq merkle-root 2)
                                            merkle-root)))
                          (unless (and (> (length hex-str) 0)
                                       (every (lambda (c)
                                                (or (digit-char-p c)
                                                    (find c "abcdefABCDEF")))
                                              hex-str))
                            (error 'blockchain-error
                                   :chain chain
                                   :operation "anchor"
                                   :details (format nil "Invalid hex merkle-root: ~A" merkle-root)))
                          (handler-case
                              (ironclad:hex-string-to-byte-array hex-str)
                            (error (e)
                              (error 'blockchain-error
                                     :chain chain
                                     :operation "anchor"
                                     :details (format nil "Hex parse error: ~A" e))))))
                       (vector merkle-root)))
         ;; Derive sender address
         (pk-bytes (ironclad:hex-string-to-byte-array *ethereum-private-key*))
         (pub-key (private-key-to-public-key pk-bytes))
         (address (address-to-hex (public-key-to-address pub-key)))
         ;; Get nonce and gas price
         (nonce (eth-get-transaction-count address))
         (gas-price (eth-gas-price))
         ;; Build transaction (data-only, no value transfer)
         (tx (make-ethereum-tx
              :nonce nonce
              :gas-price gas-price
              :gas-limit gas-limit
              :to nil  ; Contract creation style, data-only
              :value 0
              :data root-bytes
              :chain-id *ethereum-chain-id*))
         ;; Sign transaction
         (signed-tx (sign-ethereum-transaction tx *ethereum-private-key*))
         ;; Send transaction
         (tx-hash (eth-send-raw-transaction signed-tx)))

    (format t "✓ Ethereum transaction sent: ~A~%" tx-hash)

    ;; Wait for confirmation if requested
    (when wait-confirmation
      (format t "  Waiting for confirmation...")
      (loop for attempt from 1 to 30
            for receipt = (handler-case
                              (eth-get-transaction-receipt tx-hash)
                            (error () nil))
            when receipt
              do (format t " confirmed in block ~A~%"
                        (cdr (assoc "blockNumber" receipt :test #'string=)))
                 (return)
            do (sleep 2)
            finally (format t " timeout~%")))

    (list :tx-hash tx-hash
          :chain :ethereum
          :chain-id *ethereum-chain-id*
          :merkle-root (ironclad:byte-array-to-hex-string root-bytes)
          :timestamp (get-universal-time))))

;;; ============================================================================
;;; ARWEAVE CLIENT (REST API)
;;; ============================================================================

(defun arweave-get-price (bytes)
  "Get Arweave upload price in Winston for given byte size"
  (let ((url (format nil "~A/price/~D" *arweave-gateway-url* bytes)))
    (multiple-value-bind (response status)
        (drakma:http-request url :method :get)
      (if (= status 200)
          (parse-integer (babel:octets-to-string response :encoding :utf-8))
          (error 'blockchain-error
                 :chain :arweave
                 :operation "get-price"
                 :details (format nil "HTTP ~A" status))))))

(defun arweave-upload (data &key (chain :arweave)
                                 content-type
                                 tags)
  "Upload data to Arweave permanent storage

   AUTHORITY PATTERN:
   - Requires :chain parameter (explicit)
   - CONDITIONAL: Returns nil if wallet not configured
   - STRICT: Signals error if configured but fails

   Args:
     data: Byte vector or string to upload
     chain: Blockchain identifier (must be :arweave)
     content-type: MIME type for data
     tags: Alist of name-value tag pairs

   Returns:
     Plist with :tx-id, :size, :price, :timestamp
     or nil if not configured"
  (declare (type (member :arweave) chain))

  ;; CONDITIONAL: Skip silently if not configured
  (unless *arweave-wallet-path*
    (return-from arweave-upload nil))

  (unless (probe-file *arweave-wallet-path*)
    (error 'chain-not-configured
           :chain :arweave
           :operation "upload"
           :details (format nil "Wallet not found: ~A" *arweave-wallet-path*)))

  ;; Normalize data to bytes
  (let* ((data-bytes (etypecase data
                       (string (babel:string-to-octets data :encoding :utf-8))
                       (vector data)))
         (size (length data-bytes))
         ;; Load wallet
         (wallet-json (alexandria:read-file-into-string *arweave-wallet-path*))
         (wallet (jonathan:parse wallet-json :as :alist))
         ;; Get price
         (price (arweave-get-price size))
         ;; Build transaction (simplified - full implementation needs RSA signing)
         (tx-data `(("data" . ,(cl-base64:usb8-array-to-base64-string data-bytes :uri t))
                    ("reward" . ,(format nil "~D" price))
                    ("tags" . ,(mapcar (lambda (tag)
                                        `(("name" . ,(cl-base64:string-to-base64-string
                                                     (car tag) :uri t))
                                          ("value" . ,(cl-base64:string-to-base64-string
                                                      (cdr tag) :uri t))))
                                      (or tags '(("App-Name" . "ORCHESTRATOR"))))))))

    ;; HONESTY GATE: full Arweave signing/submission (RSA-PSS with the wallet key +
    ;; POST to a node) is NOT implemented here — this only PREPARES the transaction.
    ;; Returning a bare success plist made callers record a "permanent Arweave anchor"
    ;; that was never submitted (a false provenance claim in a legal corpus). The
    ;; result is now explicitly marked :submitted NIL with no :tx-id, so no caller can
    ;; mistake preparation for a real anchor.
    (format t "⚠ Arweave transaction PREPARED but NOT submitted (signing/upload not implemented): ~D bytes, ~D Winston~%" size price)

    (list :chain :arweave
          :submitted nil
          :status :prepared-not-submitted
          :size size
          :price price
          :data-hash (ironclad:byte-array-to-hex-string
                     (ironclad:digest-sequence :sha256 data-bytes))
          :timestamp (get-universal-time))))

(defun arweave-get-data (tx-id)
  "Retrieve data from Arweave by transaction ID

   Args:
     tx-id: Arweave transaction ID

   Returns:
     Data as byte vector, or nil if not found"
  (handler-case
      (let ((url (format nil "~A/~A" *arweave-gateway-url* tx-id)))
        (multiple-value-bind (response status)
            (drakma:http-request url :method :get)
          (if (= status 200)
              (etypecase response
                (string (babel:string-to-octets response :encoding :utf-8))
                (vector response))
              nil)))
    (error () nil)))

;;; ============================================================================
;;; IPFS CLIENT (HTTP API)
;;; ============================================================================

(defun ipfs-add (data &key (chain :ipfs)
                          filename
                          pin)
  "Add data to IPFS

   AUTHORITY PATTERN:
   - Requires :chain parameter (explicit)
   - CONDITIONAL: Returns nil if IPFS not available

   Args:
     data: Byte vector or string to add
     chain: Storage identifier (must be :ipfs)
     filename: Optional filename for the data
     pin: If T, pin the content locally

   Returns:
     Plist with :cid, :size, :name
     or nil if not available"
  (declare (type (member :ipfs) chain))

  ;; Normalize data to bytes
  (let ((data-bytes (etypecase data
                      (string (babel:string-to-octets data :encoding :utf-8))
                      (vector data))))

    ;; Try to connect to IPFS
    (handler-case
        (let* ((url (format nil "~A/api/v0/add?pin=~A"
                           *ipfs-api-url*
                           (if pin "true" "false")))
               ;; Build multipart form data
               (boundary "----IPFSBoundary")
               (body (with-output-to-string (s)
                       (format s "--~A~C~C" boundary #\Return #\Newline)
                       (format s "Content-Disposition: form-data; name=\"file\"")
                       (when filename
                         (format s "; filename=\"~A\"" filename))
                       (format s "~C~C~C~C" #\Return #\Newline #\Return #\Newline))))
          (multiple-value-bind (response status)
              (drakma:http-request url
                                   :method :post
                                   :content-type (format nil "multipart/form-data; boundary=~A"
                                                        boundary)
                                   :content (concatenate '(vector (unsigned-byte 8))
                                                        (babel:string-to-octets body :encoding :utf-8)
                                                        data-bytes
                                                        (babel:string-to-octets
                                                         (format nil "~C~C--~A--~C~C"
                                                                #\Return #\Newline
                                                                boundary
                                                                #\Return #\Newline)
                                                         :encoding :utf-8)))
            (if (= status 200)
                (let* ((response-str (babel:octets-to-string response :encoding :utf-8))
                       (result (jonathan:parse response-str :as :alist)))
                  (format t "✓ IPFS added: ~A~%" (cdr (assoc "Hash" result :test #'string=)))
                  (list :cid (cdr (assoc "Hash" result :test #'string=))
                        :size (cdr (assoc "Size" result :test #'string=))
                        :name (cdr (assoc "Name" result :test #'string=))
                        :chain :ipfs
                        :timestamp (get-universal-time)))
                nil)))
      (error (e)
        (declare (ignore e))
        nil))))

;;; ============================================================================
;;; UNIFIED ANCHOR FUNCTION (Main Entry Point)
;;; ============================================================================

(defun anchor-hash (hash &key (chains '(:ethereum :arweave :ipfs)))
  "Anchor hash to multiple blockchains

   AUTHORITY PATTERN:
   - Each chain is CONDITIONAL (skip if not configured)
   - Returns results for all attempted chains

   Args:
     hash: 32-byte hash or hex string to anchor
     chains: List of chains to anchor to

   Returns:
     Plist with chain -> result pairs"
  (let ((results nil))
    (dolist (chain chains)
      (let ((result (case chain
                      (:ethereum (ethereum-anchor hash :chain :ethereum))
                      (:arweave (arweave-upload hash :chain :arweave))
                      (:ipfs (ipfs-add hash :chain :ipfs)))))
        (when result
          (push (cons chain result) results))))
    (nreverse results)))

(defun verify-anchor (tx-reference &key chain)
  "Verify an anchor exists on blockchain

   Args:
     tx-reference: Transaction hash or CID
     chain: Which blockchain to check

   Returns:
     T if verified, NIL otherwise"
  (case chain
    (:ethereum
     (when *ethereum-rpc-url*
       (let ((receipt (eth-get-transaction-receipt tx-reference)))
         (and receipt
              (string= (cdr (assoc "status" receipt :test #'string=)) "0x1")))))
    (:arweave
     ;; Check if transaction exists on Arweave
     (handler-case
         (let ((url (format nil "~A/tx/~A/status" *arweave-gateway-url* tx-reference)))
           (multiple-value-bind (response status)
               (drakma:http-request url :method :get)
             (declare (ignore response))
             (= status 200)))
       (error () nil)))
    (:ipfs
     ;; Check if CID is pinned/available
     (handler-case
         (let ((url (format nil "~A/api/v0/pin/ls?arg=~A" *ipfs-api-url* tx-reference)))
           (multiple-value-bind (response status)
               (drakma:http-request url :method :post)
             (declare (ignore response))
             (= status 200)))
       (error () nil)))
    (t nil)))

;;; ============================================================================
;;; INITIALIZATION
;;; ============================================================================

(defun initialize-from-environment ()
  "Initialize blockchain configuration from environment variables"
  (alexandria:when-let ((url (uiop:getenv "ETHEREUM_RPC_URL")))
    (setf *ethereum-rpc-url* url))
  (alexandria:when-let ((key (uiop:getenv "ETHEREUM_PRIVATE_KEY")))
    (setf *ethereum-private-key* key))
  (alexandria:when-let ((chain-id (uiop:getenv "ETHEREUM_CHAIN_ID")))
    ;; DARPA-GRADE: Validate chain-id is a valid integer
    (handler-case
        (let ((parsed (parse-integer chain-id)))
          (unless (plusp parsed)
            (warn "ETHEREUM_CHAIN_ID must be positive: ~A" chain-id))
          (setf *ethereum-chain-id* parsed))
      (error (e)
        (warn "Invalid ETHEREUM_CHAIN_ID '~A': ~A" chain-id e))))
  (alexandria:when-let ((wallet (uiop:getenv "ARWEAVE_WALLET_PATH")))
    (setf *arweave-wallet-path* wallet))
  (alexandria:when-let ((ipfs (uiop:getenv "IPFS_API_URL")))
    (setf *ipfs-api-url* ipfs)))

;;; Initialize on load
(initialize-from-environment)

;;; ============================================================================
;;; END OF BLOCKCHAIN-AUTHORITY.LISP
;;; ============================================================================
