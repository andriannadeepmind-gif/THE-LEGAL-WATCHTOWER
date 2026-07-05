;;;; docker/verify-deps.lisp
;;;; ============================================================================
;;;; Hermetic dependency verification (Pure Lisp, REAL content hashing).
;;;; ============================================================================
;;;; Runs in the deps-verify Docker stage under vanilla SBCL, BEFORE any vendored
;;;; library is trusted/loaded. It recomputes the canonical content hash of every
;;;; dependency directory (docker/dep-hash.lisp — no third-party, no ironclad) and
;;;; checks it against deps.lock. The check is BIJECTIVE:
;;;;   * every deps.lock entry must exist on disk and its hash must match, AND
;;;;   * every directory under third-party/ must be pinned in deps.lock.
;;;; Any mismatch, missing, or unpinned dependency fails the build (exit 1).
;;;;
;;;;   sbcl --script /app/docker/verify-deps.lisp
;;;;   env: DEPS_LOCK_FILE (default /app/deps.lock), THIRD_PARTY_DIR (/app/third-party/)
;;;; ============================================================================

(let ((here (or *load-pathname* *default-pathname-defaults*)))
  (handler-bind ((warning #'muffle-warning))
    (load (merge-pathnames "dep-hash.lisp" here))))

(defun getenv-or (name default) (or (uiop:getenvp name) default))

(defun parse-deps-lock (path)
  "Return an alist (name . expected-hash) from PATH, skipping comments/blanks."
  (with-open-file (s path :direction :input :external-format :utf-8)
    (loop for line = (read-line s nil nil) while line
          for trimmed = (string-trim '(#\Space #\Tab #\Return) line)
          unless (or (zerop (length trimmed)) (char= (char trimmed 0) #\#))
            collect (let ((bar (position #\| trimmed)))
                      (cons (string-trim '(#\Space #\Tab) (subseq trimmed 0 bar))
                            (and bar (string-trim '(#\Space #\Tab) (subseq trimmed (1+ bar)))))))))

(defun main ()
  (let* ((deps-lock (getenv-or "DEPS_LOCK_FILE" "/app/deps.lock"))
         (third-party (getenv-or "THIRD_PARTY_DIR" "/app/third-party/")))
    (format t "~&======================================================================~%")
    (format t "DEPENDENCY VERIFICATION — Pure Lisp, canonical content hashes~%")
    (format t "======================================================================~%")
    (unless (probe-file deps-lock)
      (format t "ERROR: deps.lock not found at ~A~%" deps-lock) (sb-ext:exit :code 1))
    (let* ((expected (parse-deps-lock deps-lock))
           (on-disk (pcl-dep-hash:third-party-deps third-party))
           (locked-names (mapcar #'car expected))
           (mismatch 0) (missing 0) (ok 0))
      ;; 1) every locked dep exists and its content hash matches
      (dolist (e expected)
        (destructuring-bind (name . want) e
          (let ((dir (cdr (assoc name on-disk :test #'string=))))
            (cond
              ((null dir) (incf missing) (format t "  ✗ MISSING : ~A~%" name))
              (t (let ((got (pcl-dep-hash:dep-hash dir)))
                   (if (string= got want)
                       (progn (incf ok) (format t "  ✓ ~A~%" name))
                       (progn (incf mismatch)
                              (format t "  ✗ MISMATCH: ~A~%      want ~A~%      got  ~A~%"
                                      name want got)))))))))
      ;; 2) bijective: no unpinned directory under third-party/
      (let ((unpinned (loop for (name . nil) in on-disk
                            unless (member name locked-names :test #'string=) collect name)))
        (dolist (u unpinned) (format t "  ✗ UNPINNED (not in deps.lock): ~A~%" u))
        (format t "~%----------------------------------------------------------------------~%")
        (format t "  matched=~D  mismatch=~D  missing=~D  unpinned=~D  (of ~D on disk)~%"
                ok mismatch missing (length unpinned) (length on-disk))
        (if (and (zerop mismatch) (zerop missing) (null unpinned))
            (progn (format t "✓ All ~D dependencies verified against deps.lock.~%" ok)
                   (sb-ext:exit :code 0))
            (progn (format t "✗ Dependency verification FAILED.~%")
                   (sb-ext:exit :code 1)))))))

(main)
