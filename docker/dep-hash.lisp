;;;; docker/dep-hash.lisp
;;;; ============================================================================
;;;; Canonical, reproducible content hash of a vendored dependency directory.
;;;; ============================================================================
;;;; Pure vanilla SBCL (uses only ASDF/UIOP, which ships with SBCL — no
;;;; third-party). Loads docker/sha256.lisp. The hash is:
;;;;
;;;;   for each regular file under DIR:  "<relative/path>:<sha256(file-bytes)>"
;;;;   sort those lines by code point (locale-independent)
;;;;   manifest = each line + newline, concatenated
;;;;   dep-hash = sha256( UTF-8(manifest) )
;;;;
;;;; This is path-prefix independent (relative paths only, so /app vs /home does
;;;; not matter), file-order independent (sorted), and line-ending/locale stable.
;;;; It is the single algorithm shared by the generator and the verifier, so they
;;;; can never disagree — eliminating the old "tooling differences" that forced
;;;; hash verification to be disabled.
;;;; ============================================================================

(require :asdf)                         ; UIOP, bundled with SBCL (no network/deps)
(load (merge-pathnames "sha256.lisp" (or *load-pathname* *default-pathname-defaults*)))

(defpackage :pcl-dep-hash (:use :cl) (:export #:dep-hash #:third-party-deps))
(in-package :pcl-dep-hash)

(defun %read-octets (path)
  (with-open-file (s path :element-type '(unsigned-byte 8))
    (let ((v (make-array (file-length s) :element-type '(unsigned-byte 8))))
      (read-sequence v s)
      v)))

(defun %walk-files (dir)
  "All regular files under DIR, recursively (absolute pathnames)."
  (append (uiop:directory-files dir)
          (loop for sub in (uiop:subdirectories dir) append (%walk-files sub))))

(defun dep-hash (dir)
  "Canonical SHA-256 of the dependency directory DIR (see file header)."
  (let* ((dir (uiop:ensure-directory-pathname dir))
         (lines (loop for f in (%walk-files dir)
                      collect (format nil "~A:~A"
                                      (uiop:native-namestring (uiop:enough-pathname f dir))
                                      (pcl-sha256:sha256-hex (%read-octets f)))))
         (manifest (format nil "~{~A~%~}" (sort lines #'string<))))
    (pcl-sha256:sha256-hex (sb-ext:string-to-octets manifest :external-format :utf-8))))

(defun third-party-deps (third-party-dir)
  "Sorted list of (name . absolute-dir) for every vendored dependency directory."
  (let ((root (uiop:ensure-directory-pathname third-party-dir)))
    (sort (loop for d in (uiop:subdirectories root)
                collect (cons (car (last (pathname-directory d))) d))
          #'string< :key #'car)))
