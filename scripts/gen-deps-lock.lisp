;;;; scripts/gen-deps-lock.lisp
;;;; ============================================================================
;;;; Regenerate deps.lock with canonical, reproducible content hashes.
;;;; ============================================================================
;;;; Pure vanilla SBCL (loads docker/dep-hash.lisp; no third-party). Enumerates
;;;; EVERY directory under third-party/ and pins its canonical content hash, so
;;;; the lock is bijective with the vendored tree. Deterministic: same tree →
;;;; byte-identical deps.lock.
;;;;
;;;;   sbcl --script scripts/gen-deps-lock.lisp           # writes ./deps.lock
;;;;   THIRD_PARTY_DIR=… DEPS_LOCK_FILE=… sbcl --script scripts/gen-deps-lock.lisp
;;;; ============================================================================

(let ((here (or *load-pathname* *default-pathname-defaults*)))
  (handler-bind ((warning #'muffle-warning))
    (load (merge-pathnames "../docker/dep-hash.lisp" here))))

(defun getenv-or (name default) (or (uiop:getenvp name) default))

(let* ((third-party (getenv-or "THIRD_PARTY_DIR" "third-party/"))
       (out (getenv-or "DEPS_LOCK_FILE" "deps.lock"))
       (deps (pcl-dep-hash:third-party-deps third-party))
       (rows (loop for (name . dir) in deps
                   collect (cons name (pcl-dep-hash:dep-hash dir)))))
  (with-open-file (s out :direction :output :if-exists :supersede
                       :if-does-not-exist :create :external-format :utf-8)
    (format s "# Dependency Lock File — canonical, reproducible content hashes.~%")
    (format s "# Format:    <dir-name> | sha256~%")
    (format s "# Algorithm: docker/dep-hash.lisp — per-file SHA-256, sorted by~%")
    (format s "#            relative path, then SHA-256 of the manifest.~%")
    (format s "# Regenerate: sbcl --script scripts/gen-deps-lock.lisp~%")
    (format s "# Verify:     sbcl --script docker/verify-deps.lisp  (deps-verify stage)~%")
    (format s "# Hermetic: every dir under third-party/ is pinned (bijective). No network.~%")
    (loop for (name . hash) in rows do (format s "~A | ~A~%" name hash)))
  (format t "~&✓ Wrote ~A — ~D dependencies pinned (canonical content hashes).~%"
          out (length rows)))
