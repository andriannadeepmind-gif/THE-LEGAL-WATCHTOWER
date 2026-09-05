;;;; hash-provider.lisp — the single SHA-256 seat of the Common Lisp verification path.
;;;;
;;;; REVIEW-2 N-1 / N-11 — WHY THIS IS NOT A VENDORED LISP LIBRARY ANY MORE.
;;;; The previous provider loaded ironclad through ASDF from an in-repo `third-party/` tree. That COMPILED AND
;;;; EXECUTED 725 units of unpinned Lisp inside the kernel process before a single model hash was computed, and
;;;; the independent review demonstrated that a one-line edit to any of those files could silence the kernel's
;;;; own violation recorder and turn a genuine L5 leak into `ARCHITECTURE MODEL LAWS: PASS`. Pinning that closure
;;;; is circular: verifying ~700 files needs SHA-256, which is what the closure provides. The dominance decision
;;;; (recorded in TCB-DECISION.md) therefore removes the closure entirely instead of guarding it.
;;;;
;;;; THE CONSTRUCTION. SHA-256 comes from ONE pinned external digest program, executed directly — never through a
;;;; shell, never resolved through PATH — with its absolute path, semantic version and exact executable digest
;;;; declared as `tool` facts in TOOLCHAIN.sexp. Bytes are fed to it on STDIN and files are named on argv, so this
;;;; path creates no temporary file of its own and has no scratch directory to collide with or be symlinked
;;;; (Review-2 N-12). Before ANY model byte is hashed the provider:
;;;;   1. digests the program WITH ITSELF and requires the result to equal its pinned :sha256;
;;;;   2. reproduces the FIPS 180-4 SHA-256 known-answer vectors, including the 1,000,000 x 'a' vector.
;;;; Either failure aborts with exit code 4 and NO verdict. There is no fallback and no in-repo implementation.
;;;;
;;;; BOOTSTRAP TRUST ANCHOR — stated plainly, because every verifier has one and hiding it is the dishonesty.
;;;; This path trusts exactly two things it cannot verify with itself: the SBCL binary executing this code, and
;;;; the digest program's first self-measurement. Step 1 above is therefore NOT proof on its own: a substituted
;;;; program could lie about its own bytes. What closes it is that the INDEPENDENT Python path digests the same
;;;; program with a different engine (hashlib/OpenSSL) and compares it to the same pinned value, while this path
;;;; measures the Python binary in return; `gate_checks.py toolchain` refuses to let either verifier run until
;;;; both agree. Neither path is ever asked to certify itself.
;;;;
;;;; Hashing semantics — one definition, used everywhere on this path:
;;;;   hash(file)   = SHA-256 over the EXACT RAW BYTES of the file (no decoding, no newline translation)
;;;;   hash(string) = SHA-256 over the UTF-8 encoding of the string
(defpackage :aml-hash
  (:use :cl)
  (:export #:ensure-provider #:provider-id
           #:sha256-hex-of-file #:sha256-hex-of-bytes #:sha256-hex-of-string))
(in-package :aml-hash)

(defvar *tool* nil) (defvar *provider-id* nil)

(defun die (fmt &rest args)
  (format t "~&TOOLCHAIN-FAILURE: ~a~%" (apply #'format nil fmt args))
  (format t "SHA-256 PROVIDER: UNAVAILABLE — no model hash was computed and no verdict is issued.~%")
  (finish-output)
  (sb-ext:exit :code 4))

(defun take-digest (text)
  "The leading 64 lower-case hex characters of the program's output, or NIL if it did not produce one."
  (when (>= (length text) 64)
    (let ((d (subseq text 0 64)))
      (when (every (lambda (c) (or (char<= #\0 c #\9) (char<= #\a c #\f))) d) d))))

(defun run-tool (args &optional bytes)
  "Invoke the pinned program directly — never a shell, never PATH. BYTES, when given, are fed on stdin."
  (let* ((out (make-string-output-stream))
         (proc (handler-case (sb-ext:run-program *tool* args :input (and bytes :stream) :output out
                                                 :error nil :search nil :wait (null bytes))
                 (error () nil))))
    (when proc
      (when bytes
        (let ((in (sb-ext:process-input proc)))
          (write-sequence bytes in) (finish-output in) (close in))
        (sb-ext:process-wait proc))
      (when (eql (sb-ext:process-exit-code proc) 0) (take-digest (get-output-stream-string out))))))

(defun sha256-hex-of-bytes (bytes)
  (unless *tool* (die "SHA-256 provider used before ensure-provider"))
  (or (run-tool (list "--binary" "-") bytes) (die "the pinned digest program produced no digest for a byte sequence")))

(defun sha256-hex-of-file (path)
  "SHA-256 over the exact raw bytes of PATH. No decoding, no newline translation."
  (unless *tool* (die "SHA-256 provider used before ensure-provider"))
  (or (run-tool (list "--binary" "--" (namestring path))) (die "the pinned digest program produced no digest for ~a" path)))

(defun sha256-hex-of-string (string)
  "SHA-256 over the UTF-8 encoding of STRING."
  (sha256-hex-of-bytes (sb-ext:string-to-octets string :external-format :utf-8)))

;; FIPS 180-4 SHA-256 known-answer tests, re-run in this process at every start, BEFORE any model hash.
(defparameter +vectors+
  '(("" . "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    ("abc" . "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
     . "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")))
(defparameter +million-a+ "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")

(defun self-test ()
  (dolist (v +vectors+)
    (let ((got (sha256-hex-of-string (car v))))
      (unless (string= got (cdr v))
        (die "digest program failed FIPS 180-4 vector ~s: got ~a want ~a" (car v) got (cdr v)))))
  (let ((got (sha256-hex-of-bytes (make-array 1000000 :element-type '(unsigned-byte 8)
                                              :initial-element (char-code #\a)))))
    (unless (string= got +million-a+)
      (die "digest program failed the 1,000,000 x 'a' vector: got ~a want ~a" got +million-a+))))

(defun ensure-provider (tool-path pinned-sha256 semantic-version)
  "Authorize the pinned digest program, then prove it against the FIPS vectors, or abort with exit 4."
  (let ((tool (namestring tool-path)))
    (unless (and (plusp (length tool)) (char= (char tool 0) #\/))
      (die "declared digest program is not an absolute path: ~a" tool))
    (unless (probe-file tool) (die "declared digest program does not exist: ~a" tool))
    (setf *tool* tool)
    (let ((actual (run-tool (list "--binary" "--" tool))))   ; measured again, with a different engine, by the independent path
      (unless actual (die "declared digest program ~a produced no digest for itself" tool))
      (unless (string= actual pinned-sha256)
        (die "digest program identity mismatch: ~a is ~a, TOOLCHAIN.sexp pins ~a" tool actual pinned-sha256)))
    (self-test)
    (setf *provider-id* (format nil "~a ~a (pinned external digest program)" tool semantic-version))))

(defun provider-id () (or *provider-id* "UNINITIALISED"))
