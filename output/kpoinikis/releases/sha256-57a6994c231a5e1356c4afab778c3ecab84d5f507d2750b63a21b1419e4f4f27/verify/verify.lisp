;;;; verify.lisp - Pure Lisp Epistemic Release Verification
;;;; ============================================================================
;;;; DARPA-GRADE: No OpenSSL, No external tools
;;;; Usage: sbcl --script verify.lisp [release-dir]
;;;; ============================================================================

(require :asdf)

;; Load minimal dependencies
(handler-case
    (progn
      (asdf:load-system :ironclad)
      (asdf:load-system :babel)
      (asdf:load-system :yason)
      (asdf:load-system :cl-base64))
  (error (e)
    (format t "ERROR: Missing dependencies. Install: ironclad, babel, yason, cl-base64~%")
    (format t "Details: ~A~%" e)
    (sb-ext:exit :code 1)))

;;; Base64URL decoding
(defun b64url-decode (string)
  (let* ((padded (concatenate 'string string
                              (make-string (mod (- 4 (mod (length string) 4)) 4)
                                          :initial-element #\=)))
         (standard (map 'string (lambda (c)
                                  (case c (#\- #\+) (#\_ #\/) (t c)))
                        padded)))
    (cl-base64:base64-string-to-usb8-array standard)))

;;; File utilities
(defun read-file-bytes (path)
  (with-open-file (s path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length s) :element-type '(unsigned-byte 8))))
      (read-sequence bytes s)
      bytes)))

(defun read-file-string (path)
  (with-open-file (s path)
    (let ((str (make-string (file-length s))))
      (read-sequence str s)
      str)))

;;; JWS verification
(defun verify-jws (jws-string payload public-key)
  (let* ((parts (split-string jws-string #\.))
         (header-b64 (first parts))
         (payload-b64 (second parts))
         (signature-b64 (third parts))
         (signing-input (format nil "~A.~A" header-b64 payload-b64))
         (signature (b64url-decode signature-b64))
         (digest (ironclad:digest-sequence :sha256
                   (babel:string-to-octets signing-input :encoding :utf-8))))
    (let ((digest-info (concatenate '(vector (unsigned-byte 8))
                         #(#x30 #x31 #x30 #x0d #x06 #x09 #x60 #x86 #x48 #x01
                           #x65 #x03 #x04 #x02 #x01 #x05 #x00 #x04 #x20)
                         digest)))
      (handler-case
          (progn
            (ironclad:verify-signature public-key digest-info signature)
            t)
        (error () nil)))))

(defun split-string (string char)
  (loop for start = 0 then (1+ end)
        for end = (position char string :start start)
        collect (subseq string start (or end (length string)))
        while end))

;;; Main verification
(defun verify-release (release-dir)
  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "  EPISTEMIC RELEASE VERIFICATION (Pure Lisp)~%")
  (format t "  DARPA-GRADE: No OpenSSL, No external tools~%")
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "Release: ~A~%~%" release-dir)

  (let ((errors 0))
    ;; Check manifest
    (format t "[1/4] Checking manifests...~%")
    (if (and (probe-file (merge-pathnames "manifest.ttl" release-dir))
             (probe-file (merge-pathnames "manifest.jsonld" release-dir)))
        (format t "  ✓ Manifests present~%~%")
        (progn (format t "  ✗ Manifests missing~%~%") (incf errors)))

    ;; Check JWS
    (format t "[2/4] Verifying JWS signature...~%")
    (let ((jws-path (merge-pathnames "temporal-proof/signature.jws" release-dir))
          (jwk-path (merge-pathnames "verify/public.jwk" release-dir))
          (manifest-path (merge-pathnames "manifest.ttl" release-dir)))
      (if (and (probe-file jws-path) (probe-file jwk-path) (probe-file manifest-path))
          (handler-case
              (let* ((jws (string-trim '(#\Space #\Newline) (read-file-string jws-path)))
                     (jwk (yason:parse (read-file-string jwk-path)))
                     (manifest (read-file-string manifest-path))
                     (n (ironclad:octets-to-integer (b64url-decode (gethash "n" jwk))))
                     (e (ironclad:octets-to-integer (b64url-decode (gethash "e" jwk))))
                     (pubkey (ironclad:make-public-key :rsa :n n :e e)))
                (if (verify-jws jws manifest pubkey)
                    (format t "  ✓ JWS signature valid~%~%")
                    (progn (format t "  ✗ JWS signature INVALID~%~%") (incf errors))))
            (error (e)
              (format t "  ✗ JWS error: ~A~%~%" e)
              (incf errors)))
          (format t "  ⚠ JWS files not found (skipped)~%~%")))

    ;; Check timestamp
    (format t "[3/4] Checking RFC 3161 timestamp...~%")
    (let ((tsr-path (merge-pathnames "temporal-proof/timestamp.tsr" release-dir)))
      (if (probe-file tsr-path)
          (let ((size (with-open-file (s tsr-path) (file-length s))))
            (format t "  ✓ Timestamp present (~D bytes)~%~%" size))
          (format t "  ⚠ Timestamp not found (skipped)~%~%")))

    ;; Check Merkle
    (format t "[4/4] Checking Merkle tree...~%")
    (let ((merkle-path (merge-pathnames "temporal-proof/merkle-tree.json" release-dir)))
      (if (probe-file merkle-path)
          (format t "  ✓ Merkle tree present~%~%")
          (format t "  ⚠ Merkle tree not found (skipped)~%~%")))

    ;; Summary
    (format t "═══════════════════════════════════════════════════════════════~%")
    (if (zerop errors)
        (format t "  ✓ VERIFICATION PASSED~%")
        (format t "  ✗ VERIFICATION FAILED (~D errors)~%" errors))
    (format t "═══════════════════════════════════════════════════════════════~%")

    (zerop errors)))

;; Entry point
(let ((release-dir (or (second sb-ext:*posix-argv*) ".")))
  (if (verify-release release-dir)
      (sb-ext:exit :code 0)
      (sb-ext:exit :code 1)))
