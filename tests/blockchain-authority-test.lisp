;;;; tests/blockchain-authority-test.lisp
;;;; ============================================================================
;;;; BLOCKCHAIN AUTHORITY TESTS
;;;; ============================================================================
;;;;
;;;; Tests for pure Common Lisp blockchain implementation
;;;; Focus: RLP encoding, Keccak-256, key derivation, transaction signing
;;;;
;;;; These tests verify correctness against known Ethereum test vectors.
;;;; ============================================================================

(defpackage :orchestrator.blockchain-authority.tests
  (:use :cl :fiveam :orchestrator.blockchain-authority))

(in-package :orchestrator.blockchain-authority.tests)

;;; ============================================================================
;;; TEST SUITE DEFINITION
;;; ============================================================================

(def-suite blockchain-authority-tests
  :description "Tests for blockchain authority module")

(in-suite blockchain-authority-tests)

;;; ============================================================================
;;; RLP ENCODING TESTS
;;; ============================================================================
;;; Test vectors from Ethereum Yellow Paper Appendix B

(test rlp-encode-empty-string
  "RLP encode empty string"
  (is (equalp #(#x80) (rlp-encode #()))))

(test rlp-encode-single-byte
  "RLP encode single byte < 0x80"
  (is (equalp #(#x00) (rlp-encode #(#x00))))
  (is (equalp #(#x0f) (rlp-encode #(#x0f))))
  (is (equalp #(#x7f) (rlp-encode #(#x7f)))))

(test rlp-encode-short-string
  "RLP encode string 1-55 bytes"
  ;; \"dog\" = [0x83, 'd', 'o', 'g']
  (is (equalp #(#x83 #x64 #x6f #x67)
              (rlp-encode (babel:string-to-octets "dog" :encoding :utf-8)))))

(test rlp-encode-long-string
  "RLP encode string > 55 bytes"
  (let* ((long-string (make-string 1024 :initial-element #\a))
         (encoded (rlp-encode long-string)))
    ;; First byte should be 0xb9 (0xb7 + 2 = string with 2-byte length)
    (is (= #xb9 (aref encoded 0)))
    ;; Next 2 bytes should be length 1024 = 0x0400
    (is (= #x04 (aref encoded 1)))
    (is (= #x00 (aref encoded 2)))))

(test rlp-encode-integer
  "RLP encode integers"
  ;; 0 encodes as empty string
  (is (equalp #(#x80) (rlp-encode 0)))
  ;; 15 (0x0f) encodes as single byte
  (is (equalp #(#x0f) (rlp-encode 15)))
  ;; 1024 = 0x0400 encodes as [0x82, 0x04, 0x00]
  (is (equalp #(#x82 #x04 #x00) (rlp-encode 1024))))

(test rlp-encode-empty-list
  "RLP encode empty list"
  (is (equalp #(#xc0) (rlp-encode '()))))

(test rlp-encode-string-list
  "RLP encode list of strings"
  ;; [\"cat\", \"dog\"]
  (let ((expected #(#xc8 #x83 #x63 #x61 #x74 #x83 #x64 #x6f #x67)))
    (is (equalp expected
                (rlp-encode (list (babel:string-to-octets "cat" :encoding :utf-8)
                                 (babel:string-to-octets "dog" :encoding :utf-8)))))))

(test rlp-encode-nested-list
  "RLP encode nested list"
  ;; [ [], [[]], [ [], [[]] ] ]
  (let ((expected #(#xc7 #xc0 #xc1 #xc0 #xc3 #xc0 #xc1 #xc0)))
    (is (equalp expected
                (rlp-encode (list '() (list '()) (list '() (list '()))))))))

;;; ============================================================================
;;; KECCAK-256 TESTS
;;; ============================================================================
;;; Test vectors from Ethereum

(test keccak-256-empty
  "Keccak-256 of empty string"
  (let ((expected "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"))
    (is (string= expected (keccak-256-hex "")))))

(test keccak-256-hello
  "Keccak-256 of 'hello'"
  (let ((expected "1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8"))
    (is (string= expected (keccak-256-hex "hello")))))

;;; ============================================================================
;;; INTEGER/BYTE CONVERSION TESTS
;;; ============================================================================

(test integer-to-bytes-zero
  "Integer to bytes: zero"
  (is (equalp #() (integer-to-bytes 0))))

(test integer-to-bytes-small
  "Integer to bytes: small numbers"
  (is (equalp #(#x01) (integer-to-bytes 1)))
  (is (equalp #(#xff) (integer-to-bytes 255))))

(test integer-to-bytes-large
  "Integer to bytes: larger numbers"
  (is (equalp #(#x01 #x00) (integer-to-bytes 256)))
  (is (equalp #(#x01 #x00 #x00) (integer-to-bytes 65536))))

(test bytes-to-integer-round-trip
  "Bytes to integer round trip"
  ;; NB: a LIST literal — the last value must be EVALUATED 2^64, not the quoted
  ;; form (expt 2 64), which would make N a list and break the arithmetic.
  (loop for n in (list 0 1 255 256 65535 1000000 (expt 2 64))
        do (is (= n (bytes-to-integer (integer-to-bytes n))))))

;;; ============================================================================
;;; ETHEREUM ADDRESS DERIVATION TESTS
;;; ============================================================================

(test address-from-private-key
  "Derive Ethereum address from private key"
  ;; Known test vector
  (let* ((private-key "4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318")
         (pk-bytes (ironclad:hex-string-to-byte-array private-key))
         (pub-key (private-key-to-public-key pk-bytes))
         (address-bytes (public-key-to-address pub-key))
         (address (address-to-hex address-bytes)))
    ;; Expected address for this private key
    (is (string-equal "0x2c7536E3605D9C16a7a3D7b1898e529396a65c23"
                      address
                      :start1 0 :end1 42
                      :start2 0 :end2 42))))

;;; ============================================================================
;;; TRANSACTION RLP ENCODING TESTS
;;; ============================================================================

(test ethereum-tx-rlp
  "Ethereum transaction RLP encoding"
  (let* ((tx-list (list 0        ; nonce
                        20000000000  ; gas price (20 gwei)
                        21000     ; gas limit
                        #()       ; to (empty = contract creation)
                        0         ; value
                        #()       ; data
                        1         ; chain id (mainnet)
                        0         ; empty for unsigned
                        0))       ; empty for unsigned
         (encoded (rlp-encode tx-list)))
    ;; Verify it's a valid RLP list
    (is (>= (aref encoded 0) #xc0))))

;;; ============================================================================
;;; CONDITIONAL SKIP TESTS
;;; ============================================================================

(test ethereum-anchor-not-configured
  "Ethereum anchor returns nil when not configured"
  (let ((*ethereum-rpc-url* nil)
        (*ethereum-private-key* nil))
    (is (null (ethereum-anchor "0000000000000000000000000000000000000000000000000000000000000000"
                               :chain :ethereum)))))

(test arweave-upload-not-configured
  "Arweave upload returns nil when not configured"
  (let ((*arweave-wallet-path* nil))
    (is (null (arweave-upload "test data" :chain :arweave)))))

;;; ============================================================================
;;; RUN TESTS
;;; ============================================================================

(defun run-blockchain-tests ()
  "Run all blockchain authority tests"
  (run! 'blockchain-authority-tests))

(export 'run-blockchain-tests)

;;; Standalone gate: run the suite, exit non-zero on any failure (was never invoked).
(let* ((results (fiveam:run 'blockchain-authority-tests))
       (failed (count-if-not (lambda (r) (typep r 'fiveam::test-passed)) results)))
  (fiveam:explain! results)
  ;; Canonical parseable proof line (manifest gate) — uniform «N passed, M failed»
  (format t "~%BLOCKCHAIN-AUTHORITY: ~D passed, ~D failed~%" (- (length results) failed) failed)
  (sb-ext:exit :code (if (zerop failed) 0 1)))
