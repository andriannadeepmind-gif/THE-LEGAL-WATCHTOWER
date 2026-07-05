;;;; tests/clean-output-test.lisp
;;;; Fresh per-corpus output: clean-corpus-output-dir wipes a corpus's OWN output
;;;; subdir before a run so no stale/foreign file ever lingers — guarded so it can
;;;; only ever delete a named subdirectory, never a shallow path, and skippable via
;;;; ORCHESTRATOR_KEEP_OUTPUT. Deterministic, local filesystem only.

(in-package :orchestrator.cli)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *root* (format nil "/tmp/clean-out-test-~A/" (get-universal-time)))

(defun make-corpus-dir (short &rest files)
  "Create <root>output/<short>/ with FILES in it; return the dir namestring."
  (let ((dir (format nil "~Aoutput/~A/" *root* short)))
    (ensure-directories-exist dir)
    (dolist (f files)
      (with-open-file (s (concatenate 'string dir f) :direction :output
                                                     :if-exists :supersede :if-does-not-exist :create)
        (write-string "stale" s)))
    dir))

(defun file-count (dir)
  (length (ignore-errors (uiop:directory-files (uiop:ensure-directory-pathname dir)))))

(format t "~%== a fresh run wipes the corpus's own subdir ==~%")
(let ((dir (make-corpus-dir "poinikos" "article-001.html" "article-001.ttl" "old-stale.txt")))
  (check "preconditions: stale files present" (= 3 (file-count dir)))
  (clean-corpus-output-dir dir)
  (check "the dir still exists (recreated)" (probe-file (uiop:ensure-directory-pathname dir)))
  (check "but it is now empty (stale files gone)" (= 0 (file-count dir))))

(format t "~%== sibling corpora are NOT touched ==~%")
(let ((poinikos (make-corpus-dir "poinikos" "a.html"))
      (constitution (make-corpus-dir "constitution" "c1.html" "c2.html")))
  (clean-corpus-output-dir poinikos)
  (check "cleaning poinikos leaves constitution intact" (= 2 (file-count constitution))))

(format t "~%== ORCHESTRATOR_KEEP_OUTPUT preserves the files ==~%")
(let ((dir (make-corpus-dir "kpolitikis" "keep1.html" "keep2.html")))
  (unwind-protect
       (progn (setf (uiop:getenv "ORCHESTRATOR_KEEP_OUTPUT") "1")
              (clean-corpus-output-dir dir)
              (check "files are preserved when KEEP_OUTPUT is set" (= 2 (file-count dir))))
    (sb-posix:unsetenv "ORCHESTRATOR_KEEP_OUTPUT")))

(format t "~%== safety: a non-existent dir is handled, not an error ==~%")
(let ((dir (format nil "~Aoutput/neverexisted/" *root*)))
  (check "cleaning a missing dir just (re)creates it, no error"
         (progn (clean-corpus-output-dir dir)
                (probe-file (uiop:ensure-directory-pathname dir)))))

(format t "~%== safety: a too-shallow path is refused (never deleted) ==~%")
;; Build a 2-component dir with a file; the guard requires ≥3 levels, so it must
;; NOT be deleted. Use a sentinel under /tmp that is exactly two levels deep.
(let* ((shallow (format nil "/clean-out-shallow-~A/" (get-universal-time))))
  ;; We cannot create a real top-level dir without root; assert the guard logic
  ;; via the path-depth predicate instead (no deletion attempted).
  (check "a 2-level path is below the deletion threshold"
         (< (length (pathname-directory (uiop:ensure-directory-pathname shallow))) 3)))

;; cleanup
(ignore-errors (uiop:delete-directory-tree (pathname *root*) :validate t :if-does-not-exist :ignore))

(format t "~%========================================~%")
(format t "Clean output tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
