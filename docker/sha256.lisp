;;;; docker/sha256.lisp
;;;; ============================================================================
;;;; Pure, dependency-free SHA-256 (FIPS 180-4) for the deps-verify stage.
;;;; ============================================================================
;;;; This MUST run under vanilla SBCL with no third-party systems loaded: the
;;;; dependency-verification stage runs BEFORE any vendored library is trusted,
;;;; so it cannot use ironclad (which is itself one of the deps being verified).
;;;; Hence a self-contained implementation. Operates on (unsigned-byte 8) vectors.
;;;; ============================================================================

(defpackage :pcl-sha256 (:use :cl) (:export #:sha256-hex #:sha256-octets))
(in-package :pcl-sha256)

(declaim (inline u32+ rotr shr))
(defun u32+ (&rest xs) (logand (apply #'+ xs) #xFFFFFFFF))
(defun rotr (x n) (logand (logior (ash x (- n)) (ash x (- 32 n))) #xFFFFFFFF))
(defun shr (x n) (ash x (- n)))

(defparameter +k+
  (make-array 64 :element-type '(unsigned-byte 32) :initial-contents
   '(#x428a2f98 #x71374491 #xb5c0fbcf #xe9b5dba5 #x3956c25b #x59f111f1 #x923f82a4 #xab1c5ed5
     #xd807aa98 #x12835b01 #x243185be #x550c7dc3 #x72be5d74 #x80deb1fe #x9bdc06a7 #xc19bf174
     #xe49b69c1 #xefbe4786 #x0fc19dc6 #x240ca1cc #x2de92c6f #x4a7484aa #x5cb0a9dc #x76f988da
     #x983e5152 #xa831c66d #xb00327c8 #xbf597fc7 #xc6e00bf3 #xd5a79147 #x06ca6351 #x14292967
     #x27b70a85 #x2e1b2138 #x4d2c6dfc #x53380d13 #x650a7354 #x766a0abb #x81c2c92e #x92722c85
     #xa2bfe8a1 #xa81a664b #xc24b8b70 #xc76c51a3 #xd192e819 #xd6990624 #xf40e3585 #x106aa070
     #x19a4c116 #x1e376c08 #x2748774c #x34b0bcb5 #x391c0cb3 #x4ed8aa4a #x5b9cca4f #x682e6ff3
     #x748f82ee #x78a5636f #x84c87814 #x8cc70208 #x90befffa #xa4506ceb #xbef9a3f7 #xc67178f2)))

(defun sha256-octets (message)
  "SHA-256 of an (unsigned-byte 8) vector → a 32-byte (unsigned-byte 8) vector."
  (let* ((ml (length message))
         (bitlen (* ml 8))
         ;; padding: 0x80, then zeros, to 56 mod 64, then 64-bit big-endian length
         (padlen (let ((r (mod (+ ml 1) 64))) (if (<= r 56) (- 56 r) (- 120 r))))
         (total (+ ml 1 padlen 8))
         (buf (make-array total :element-type '(unsigned-byte 8) :initial-element 0)))
    (replace buf message)
    (setf (aref buf ml) #x80)
    (loop for i from 0 below 8
          do (setf (aref buf (- total 1 i)) (logand (ash bitlen (* -8 i)) #xFF)))
    (let ((h0 #x6a09e667) (h1 #xbb67ae85) (h2 #x3c6ef372) (h3 #xa54ff53a)
          (h4 #x510e527f) (h5 #x9b05688c) (h6 #x1f83d9ab) (h7 #x5be0cd19)
          (w (make-array 64 :element-type '(unsigned-byte 32))))
      (loop for base from 0 below total by 64 do
        (loop for i from 0 below 16
              do (setf (aref w i)
                       (logior (ash (aref buf (+ base (* i 4))) 24)
                               (ash (aref buf (+ base (* i 4) 1)) 16)
                               (ash (aref buf (+ base (* i 4) 2)) 8)
                               (aref buf (+ base (* i 4) 3)))))
        (loop for i from 16 below 64
              for s0 = (logxor (rotr (aref w (- i 15)) 7) (rotr (aref w (- i 15)) 18) (shr (aref w (- i 15)) 3))
              for s1 = (logxor (rotr (aref w (- i 2)) 17) (rotr (aref w (- i 2)) 19) (shr (aref w (- i 2)) 10))
              do (setf (aref w i) (u32+ (aref w (- i 16)) s0 (aref w (- i 7)) s1)))
        (let ((a h0) (b h1) (c h2) (d h3) (e h4) (f h5) (g h6) (h h7))
          (loop for i from 0 below 64
                for s1 = (logxor (rotr e 6) (rotr e 11) (rotr e 25))
                for ch = (logxor (logand e f) (logand (lognot e) g))
                for t1 = (u32+ h s1 (logand ch #xFFFFFFFF) (aref +k+ i) (aref w i))
                for s0 = (logxor (rotr a 2) (rotr a 13) (rotr a 22))
                for maj = (logxor (logand a b) (logand a c) (logand b c))
                for t2 = (u32+ s0 maj)
                do (setf h g g f f e e (u32+ d t1) d c c b b a a (u32+ t1 t2)))
          (setf h0 (u32+ h0 a) h1 (u32+ h1 b) h2 (u32+ h2 c) h3 (u32+ h3 d)
                h4 (u32+ h4 e) h5 (u32+ h5 f) h6 (u32+ h6 g) h7 (u32+ h7 h))))
      (let ((out (make-array 32 :element-type '(unsigned-byte 8))))
        (loop for word in (list h0 h1 h2 h3 h4 h5 h6 h7) for j from 0
              do (loop for i from 0 below 4
                       do (setf (aref out (+ (* j 4) i)) (logand (ash word (* -8 (- 3 i))) #xFF))))
        out))))

(defun sha256-hex (message)
  "Lowercase hex SHA-256 of MESSAGE (an (unsigned-byte 8) vector)."
  (let ((d (sha256-octets message)))
    (string-downcase
     (with-output-to-string (s) (loop for b across d do (format s "~2,'0x" b))))))
