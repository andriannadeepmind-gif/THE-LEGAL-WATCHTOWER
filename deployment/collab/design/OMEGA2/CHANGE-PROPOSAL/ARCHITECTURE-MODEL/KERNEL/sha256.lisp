;;;; sha256.lisp — compact ANSI Common Lisp SHA-256 (FIPS 180-4). 32-bit ops masked; no external dependency.
(defpackage :aml-sha (:use :cl) (:export :sha256-hex-of-file))
(in-package :aml-sha)
(defconstant +k+
  #(#x428a2f98 #x71374491 #xb5c0fbcf #xe9b5dba5 #x3956c25b #x59f111f1 #x923f82a4 #xab1c5ed5
    #xd807aa98 #x12835b01 #x243185be #x550c7dc3 #x72be5d74 #x80deb1fe #x9bdc06a7 #xc19bf174
    #xe49b69c1 #xefbe4786 #x0fc19dc6 #x240ca1cc #x2de92c6f #x4a7484aa #x5cb0a9dc #x76f988da
    #x983e5152 #xa831c66d #xb00327c8 #xbf597fc7 #xc6e00bf3 #xd5a79147 #x06ca6351 #x14292967
    #x27b70a85 #x2e1b2138 #x4d2c6dfc #x53380d13 #x650a7354 #x766a0abb #x81c2c92e #x92722c85
    #xa2bfe8a1 #xa81a664b #xc24b8b70 #xc76c51a3 #xd192e819 #xd6990624 #xf40e3585 #x106aa070
    #x19a4c116 #x1e376c08 #x2748774c #x34b0bcb5 #x391c0cb3 #x4ed8aa4a #x5b9cca4f #x682e6ff3
    #x748f82ee #x78a5636f #x84c87814 #x8cc70208 #x90befffa #xa4506ceb #xbef9a3f7 #xc67178f2))
(declaim (inline m32))
(defun m32 (x) (logand x #xffffffff))
(defun rotr (x n) (m32 (logior (ash x (- n)) (ash x (- 32 n)))))
(defun sha256-bytes (bytes)
  (let* ((ml (length bytes)) (bitlen (* ml 8))
         (padlen (mod (- 56 (mod (+ ml 1) 64)) 64))
         (msg (make-array (+ ml 1 padlen 8) :element-type '(unsigned-byte 8) :initial-element 0)))
    (replace msg bytes) (setf (aref msg ml) #x80)
    (loop for i from 0 below 8 do (setf (aref msg (- (length msg) 1 i)) (ldb (byte 8 (* 8 i)) bitlen)))
    (let ((h (make-array 8 :initial-contents
              (list #x6a09e667 #xbb67ae85 #x3c6ef372 #xa54ff53a #x510e527f #x9b05688c #x1f83d9ab #x5be0cd19)))
          (w (make-array 64)))
      (loop for base from 0 below (length msg) by 64 do
        (loop for i from 0 below 16 do
          (setf (aref w i) (m32 (logior (ash (aref msg (+ base (* i 4))) 24) (ash (aref msg (+ base (* i 4) 1)) 16)
                                        (ash (aref msg (+ base (* i 4) 2)) 8) (aref msg (+ base (* i 4) 3))))))
        (loop for i from 16 below 64 do
          (let ((s0 (logxor (rotr (aref w (- i 15)) 7) (rotr (aref w (- i 15)) 18) (ash (aref w (- i 15)) -3)))
                (s1 (logxor (rotr (aref w (- i 2)) 17) (rotr (aref w (- i 2)) 19) (ash (aref w (- i 2)) -10))))
            (setf (aref w i) (m32 (+ (aref w (- i 16)) s0 (aref w (- i 7)) s1)))))
        (let ((a (aref h 0)) (b (aref h 1)) (c (aref h 2)) (d (aref h 3))
              (e (aref h 4)) (f (aref h 5)) (g (aref h 6)) (hh (aref h 7)))
          (loop for i from 0 below 64 do
            (let* ((s1 (logxor (rotr e 6) (rotr e 11) (rotr e 25)))
                   (ch (logxor (logand e f) (logand (m32 (lognot e)) g)))
                   (t1 (m32 (+ hh s1 ch (aref +k+ i) (aref w i))))
                   (s0 (logxor (rotr a 2) (rotr a 13) (rotr a 22)))
                   (maj (logxor (logand a b) (logand a c) (logand b c)))
                   (t2 (m32 (+ s0 maj))))
              (setf hh g g f f e e (m32 (+ d t1)) d c c b b a a (m32 (+ t1 t2)))))
          (setf (aref h 0) (m32 (+ (aref h 0) a)) (aref h 1) (m32 (+ (aref h 1) b))
                (aref h 2) (m32 (+ (aref h 2) c)) (aref h 3) (m32 (+ (aref h 3) d))
                (aref h 4) (m32 (+ (aref h 4) e)) (aref h 5) (m32 (+ (aref h 5) f))
                (aref h 6) (m32 (+ (aref h 6) g)) (aref h 7) (m32 (+ (aref h 7) hh)))))
      (string-downcase (format nil "~{~8,'0x~}" (coerce h 'list))))))
(defun sha256-hex-of-file (path)
  (with-open-file (s path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length s) :element-type '(unsigned-byte 8))))
      (read-sequence bytes s) (sha256-bytes bytes))))
