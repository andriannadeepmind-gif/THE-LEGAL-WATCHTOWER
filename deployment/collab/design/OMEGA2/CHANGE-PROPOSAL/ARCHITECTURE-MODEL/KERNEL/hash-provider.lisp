;;;; hash-provider.lisp — the single SHA-256 seat of the Common Lisp verification path.
;;;;
;;;; The provider is a VETTED, MAINTAINED implementation (ironclad), vendored in-repo and loaded through ASDF
;;;; from the source-registry tree declared in TOOLCHAIN.sexp. There is no in-repo SHA-256 implementation and
;;;; no fallback: if the declared provider cannot be located, loaded, or does not reproduce the FIPS 180-4
;;;; SHA-256 test vectors in this process, the kernel ABORTS with exit code 4 and computes nothing.
;;;;
;;;; Hashing semantics — one definition, used everywhere on this path:
;;;;   hash(file)   = SHA-256 over the EXACT RAW BYTES of the file (no decoding, no newline translation)
;;;;   hash(string) = SHA-256 over the UTF-8 encoding of the string
;;;; The independent Python path computes the same two functions with a different vetted engine
;;;; (hashlib/OpenSSL); the gate compares both engines over identical inputs.
(defpackage :aml-hash
  (:use :cl)
  (:export #:ensure-provider #:provider-id #:sha256-hex-of-file #:sha256-hex-of-bytes #:sha256-hex-of-string))
(in-package :aml-hash)

(defvar *provider-id* nil)
(defvar *digest-file* nil)
(defvar *digest-sequence* nil)

(defun die (fmt &rest args)
  (format t "~&TOOLCHAIN-FAILURE: ~a~%" (apply #'format nil fmt args))
  (format t "SHA-256 PROVIDER: UNAVAILABLE — no model hash was computed and no verdict is issued.~%")
  (finish-output)
  (sb-ext:exit :code 4))

(defun up (dir n)
  "The directory N levels above DIR."
  (let ((d (pathname-directory (truename dir))))
    (dotimes (i n) (setf d (butlast d)))
    (make-pathname :directory d :name nil :type nil :version nil)))

(defun hex (bytes)
  (string-downcase (with-output-to-string (s) (loop for b across bytes do (format s "~2,'0x" b)))))

(defun ascii-bytes (string)
  (let ((v (make-array (length string) :element-type '(unsigned-byte 8))))
    (loop for i from 0 below (length string)
          for c = (char-code (char string i))
          do (when (> c 127) (die "non-ASCII character in a built-in test vector"))
             (setf (aref v i) c))
    v))

(defun repeat-bytes (byte n)
  (make-array n :element-type '(unsigned-byte 8) :initial-element byte))

;; FIPS 180-4 SHA-256 known-answer tests. Re-run in this process at every start, BEFORE any model hash.
(defparameter +vectors+
  '(("" . "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    ("abc" . "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
     . "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")))
(defparameter +million-a-digest+ "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")

(defun self-test ()
  (dolist (v +vectors+)
    (let ((got (sha256-hex-of-bytes (ascii-bytes (car v)))))
      (unless (string= got (cdr v))
        (die "SHA-256 provider failed FIPS 180-4 vector ~s: got ~a want ~a" (car v) got (cdr v)))))
  (let ((got (sha256-hex-of-bytes (repeat-bytes (char-code #\a) 1000000))))
    (unless (string= got +million-a-digest+)
      (die "SHA-256 provider failed the 1,000,000 x 'a' vector: got ~a want ~a" got +million-a-digest+))))

(defun ensure-provider (registry-tree system-name declared-version)
  "Load the declared SHA-256 provider from REGISTRY-TREE and prove it against the FIPS vectors, or abort."
  (unless (probe-file registry-tree)
    (die "declared SHA-256 provider source-registry tree does not exist: ~a" registry-tree))
  (handler-case (require :asdf)
    (error (e) (die "ASDF unavailable (~a)" (type-of e))))
  (let ((asdf (find-package :asdf)))
    (unless asdf (die "ASDF package unavailable after (require :asdf)"))
    (handler-case
        (progn
          (funcall (find-symbol "INITIALIZE-SOURCE-REGISTRY" asdf)
                   (list :source-registry (list :tree registry-tree) :inherit-configuration))
          (handler-bind ((warning #'muffle-warning))
            (funcall (find-symbol "LOAD-SYSTEM" asdf) system-name)))
      (error (e) (die "declared SHA-256 provider ~a could not be loaded from ~a (~a)"
                      system-name registry-tree (type-of e)))))
  (let ((pkg (find-package (string-upcase system-name))))
    (unless pkg (die "SHA-256 provider ~a loaded but exports no package" system-name))
    (setf *digest-file* (find-symbol "DIGEST-FILE" pkg)
          *digest-sequence* (find-symbol "DIGEST-SEQUENCE" pkg))
    (unless (and *digest-file* *digest-sequence* (fboundp *digest-file*) (fboundp *digest-sequence*))
      (die "SHA-256 provider ~a does not supply digest-file/digest-sequence" system-name)))
  (setf *provider-id* (format nil "~a ~a (vendored ASDF system, tree ~a)"
                              system-name declared-version (namestring registry-tree)))
  (self-test)
  *provider-id*)

(defun provider-id () (or *provider-id* "UNINITIALISED"))

(defun sha256-hex-of-bytes (bytes)
  (unless *digest-sequence* (die "SHA-256 provider used before ensure-provider"))
  (hex (funcall *digest-sequence* :sha256 bytes)))

(defun sha256-hex-of-file (path)
  "SHA-256 over the exact raw bytes of PATH. No decoding, no newline translation."
  (unless *digest-file* (die "SHA-256 provider used before ensure-provider"))
  (hex (funcall *digest-file* :sha256 path)))

(defun sha256-hex-of-string (string)
  "SHA-256 over the UTF-8 encoding of STRING."
  (sha256-hex-of-bytes (sb-ext:string-to-octets string :external-format :utf-8)))
