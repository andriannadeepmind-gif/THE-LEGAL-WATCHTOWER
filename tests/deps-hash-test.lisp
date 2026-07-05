;;;; tests/deps-hash-test.lisp
;;;; Locks the dependency-pinning trust root: the pure-Lisp SHA-256 must match the
;;;; FIPS 180-4 vectors byte-for-byte, and the canonical per-dependency hash must
;;;; be deterministic and path-independent. These are the primitives the
;;;; deps-verify build stage uses to verify every vendored library BEFORE it is
;;;; trusted — so they must be exactly correct.

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;; Locate docker/sha256.lisp + dep-hash.lisp relative to this test file. Skip
;; gracefully if absent (so the suite is safe wherever docker/ isn't present).
(let* ((here (or *load-truename* *load-pathname*))
       (docker (merge-pathnames "../docker/" (make-pathname :directory (pathname-directory here))))
       (sha (merge-pathnames "sha256.lisp" docker))
       (dh  (merge-pathnames "dep-hash.lisp" docker)))
  (cond
    ((not (and (probe-file sha) (probe-file dh)))
     (format t "~%  SKIP — docker/sha256.lisp / dep-hash.lisp not present here.~%")
     (sb-ext:exit :code 0))
    (t
     (handler-bind ((warning #'muffle-warning)) (load sha) (load dh))
     (let ((s256 (lambda (str) (funcall (find-symbol "SHA256-HEX" :pcl-sha256)
                                        (sb-ext:string-to-octets str :external-format :utf-8))))
           (dep-hash (find-symbol "DEP-HASH" :pcl-dep-hash))
           (tp-deps  (find-symbol "THIRD-PARTY-DEPS" :pcl-dep-hash)))

       (format t "~%== pure SHA-256 vs FIPS 180-4 vectors ==~%")
       (check "SHA256(\"\")   = e3b0c442…"
              (string= (funcall s256 "") "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"))
       (check "SHA256(\"abc\") = ba7816bf…"
              (string= (funcall s256 "abc") "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"))
       (check "SHA256(56-byte) = 248d6a61…"
              (string= (funcall s256 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
                       "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"))

       (format t "~%== canonical dep-hash: deterministic + sensitive to content ==~%")
       (let* ((root (merge-pathnames "../third-party/" (make-pathname :directory (pathname-directory here))))
              (deps (and (probe-file root) (funcall tp-deps root))))
         (cond
           ((null deps) (format t "  (third-party/ absent — dep-hash content check skipped)~%"))
           (t
            (let* ((one (cdr (first deps)))
                   (h1 (funcall dep-hash one))
                   (h2 (funcall dep-hash one)))
              (check "dep-hash is 64 hex chars" (and (= 64 (length h1))
                                                     (every (lambda (c) (digit-char-p c 16)) h1)))
              (check "dep-hash is deterministic (same dir → same hash)" (string= h1 h2))
              (check "different dependencies → different hashes"
                     (not (string= h1 (funcall dep-hash (cdr (second deps))))))
              ;; tamper sensitivity: hashing a tree with one extra byte changes it.
              (let* ((tmp (format nil "/tmp/dephash-~A/" (get-universal-time)))
                     (sub (merge-pathnames "x/" tmp)))
                (ensure-directories-exist sub)
                (with-open-file (o (merge-pathnames "a.txt" tmp) :direction :output
                                   :if-exists :supersede :if-does-not-exist :create)
                  (write-string "hello" o))
                (let ((ha (funcall dep-hash tmp)))
                  (with-open-file (o (merge-pathnames "a.txt" tmp) :direction :output
                                     :if-exists :supersede :if-does-not-exist :create)
                    (write-string "hello!" o))
                  (check "a single changed byte changes the dep-hash"
                         (not (string= ha (funcall dep-hash tmp)))))
                (ignore-errors (uiop:delete-directory-tree (pathname tmp) :validate t :if-does-not-exist :ignore))))))) )

       (format t "~%========================================~%")
       (format t "Deps-hash tests: ~D passed, ~D failed~%" *pass* *fail*)
       (format t "========================================~%")
       (sb-ext:exit :code (if (zerop *fail*) 0 1))))))
