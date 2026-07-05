;;;; tests/cross-language-verifier-test.lisp
;;;; CONFORMANCE: the independent public verifiers (deployment/verify/verify.py and
;;;; verify.mjs) must agree with the canonical Common Lisp implementation
;;;; byte-for-byte. The Lisp side EMITS a signed corpus; the external verifiers
;;;; (Python pure-stdlib bigint RSA, Node OpenSSL) then VERIFY it. Genuine text and
;;;; signature pass; a single tampered byte and the wrong key fail — in BOTH
;;;; languages. This locks the trust root against silent cross-language drift.
;;;;
;;;; If neither python3 nor node is available, the suite SKIPS (exit 0) so it is
;;;; safe to run in an SBCL-only environment; the dedicated Docker stage provides
;;;; both interpreters and turns it into a hard gate.

(in-package :orchestrator.proof-carrying)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %which (program)
  "Absolute path of PROGRAM if runnable, else NIL."
  (handler-case
      (let ((p (uiop:run-program (list "sh" "-c" (format nil "command -v ~A" program))
                                 :output '(:string :stripped t) :ignore-error-status t)))
        (and (plusp (length p)) p))
    (error () nil)))

(defun %repo-root ()
  "Repo root from this test file's location (tests/ → ..)."
  (let ((here (or *load-truename* *load-pathname*)))
    (truename (merge-pathnames "../" (make-pathname :directory (pathname-directory here))))))

(defun %verify-dir ()
  (or (uiop:getenv "VERIFY_DIR")
      (namestring (merge-pathnames "deployment/verify/" (%repo-root)))))

(defun %run (program &rest args)
  "Run PROGRAM ARGS; return the exit code (no error on non-zero)."
  (nth-value 2 (uiop:run-program (cons program args)
                                 :output t :error-output t :ignore-error-status t)))

(defun %write-file (path string)
  (with-open-file (o path :direction :output :if-exists :supersede
                          :if-does-not-exist :create :external-format :utf-8)
    (write-string string o)))

(let* ((py (%which "python3"))
       (nodejs (or (%which "node") (%which "nodejs")))
       (vdir (%verify-dir))
       (vpy (namestring (merge-pathnames "verify.py" vdir)))
       (vjs (namestring (merge-pathnames "verify.mjs" vdir))))
  (format t "~%== cross-language verifier conformance ==~%")
  (format t "  python3=~A~%  node=~A~%  verify-dir=~A~%" py nodejs vdir)
  (cond
    ((not (and py nodejs (probe-file vpy) (probe-file vjs)))
     (format t "~%  SKIP — python3/node (or verifier files) unavailable; ~
nothing to gate in this environment.~%")
     (sb-ext:exit :code 0))
    (t
     ;; 1) Emit a SIGNED corpus from the canonical Lisp implementation.
     (let* ((jws :orchestrator.jws-authority)
            (kp (funcall (find-symbol "GENERATE-RSA-KEYPAIR" jws) :bits 2048))
            (priv (getf kp :private-key)) (pub (getf kp :public-key))
            (jwk (funcall (find-symbol "EXPORT-JWK" jws) pub :kid "stavropoulos-law-root"))
            (jwk-json (jonathan:to-json jwk))
            (dir (format nil "/tmp/xlang-conf-~A/" (get-universal-time)))
            (provs (list (list :id "299" :text "Ανθρωποκτονία με πρόθεση." :eli "…/299" :cite "Άρθρο 299 ΠΚ")
                         (list :id "300" :text "Ανθρωποκτονία από αμέλεια." :eli "…/300" :cite "Άρθρο 300 ΠΚ")
                         (list :id "301" :text "Συμμετοχή σε αυτοκτονία." :eli "…/301" :cite "Άρθρο 301 ΠΚ"))))
       (ensure-directories-exist dir)
       (multiple-value-bind (root count sig)
           (write-provision-proofs provs dir :private-key priv :public-jwk jwk-json
                                   :anchored-at "2025-01-01T00:00:00Z")
         (declare (ignore count))
         (%write-file (format nil "~Aart-299.txt" dir) "Ανθρωποκτονία με πρόθεση.")
         (%write-file (format nil "~Aart-299-bad.txt" dir) "Κλοπή.")
         ;; The PINNED trust anchor: the genuine public key, published out-of-band.
         (%write-file (format nil "~Apin-key.jwk" dir) jwk-json)
         ;; A FULLY SELF-CONSISTENT FORGERY (the Finding-5 attack): an attacker
         ;; mints a fake provision, builds its own root, signs it with THEIR key,
         ;; and embeds THEIR key as public_key. It is internally consistent — so a
         ;; verifier that trusts the embedded key would call it authentic. Pinning
         ;; the genuine key must reject it.
         (let* ((kp2 (funcall (find-symbol "GENERATE-RSA-KEYPAIR" jws) :bits 2048))
                (priv2 (getf kp2 :private-key))
                (jwk2-json (jonathan:to-json
                            (funcall (find-symbol "EXPORT-JWK" jws) (getf kp2 :public-key) :kid "attacker")))
                (ftext "Η κλοπή είναι νόμιμη.")
                (fleaves (list (leaf-hash ftext)))
                (froot (build-merkle-root fleaves))
                (fproof (make-provision-proof "1" ftext fleaves 0 froot :anchored-at "2025-01-01T00:00:00Z"))
                (fsig (sign-root froot priv2)))
           (%write-file (format nil "~Aart-forged.txt" dir) ftext)
           (%write-file (format nil "~Aarticle-forged.proof.json" dir) (proof-plist->json fproof))
           (%write-file (format nil "~Acorpus-proof-forged.json" dir)
                        (corpus-proof-json froot 1 :anchored-at "2025-01-01T00:00:00Z"
                                           :signature fsig :public-jwk jwk2-json))))

       (let ((art (format nil "~Aarticle-299.proof.json" dir))
             (cp  (format nil "~Acorpus-proof.json" dir))
             (pin (format nil "~Apin-key.jwk" dir))
             (fart (format nil "~Aarticle-forged.proof.json" dir))
             (fcp  (format nil "~Acorpus-proof-forged.json" dir))
             (ftext (format nil "~Aart-forged.txt" dir))
             (good (format nil "~Aart-299.txt" dir))
             (bad  (format nil "~Aart-299-bad.txt" dir)))
         (dolist (v (list (list "PY" py vpy) (list "NODE" nodejs vjs)))
           (destructuring-bind (label bin script) v
             (format t "~%-- ~A --~%" label)
             (check (format nil "~A full + PINNED genuine key → AUTHENTIC (0)" label)
                    (zerop (%run bin script "--key" pin "full" art cp good)))
             (check (format nil "~A tampered text → FAIL (1)" label)
                    (= 1 (%run bin script "--key" pin "full" art cp bad)))
             ;; Finding 5: the self-consistent forgery is rejected by the pinned key.
             (check (format nil "~A self-consistent FORGERY vs pinned key → FAIL (not 0/3)" label)
                    (let ((rc (%run bin script "--key" pin "signature" fcp))) (and (/= rc 0) (/= rc 3))))
             (check (format nil "~A forged FULL chain vs pinned key → FAIL" label)
                    (let ((rc (%run bin script "--key" pin "full" fart fcp ftext))) (and (/= rc 0) (/= rc 3))))
             ;; Finding 2: without a pinned key, a valid-looking signature is NOT
             ;; authentic — the verifier must say so (exit 3), never 0.
             (check (format nil "~A signature WITHOUT pinned key → UNPINNED (3), not authentic" label)
                    (= 3 (%run bin script "signature" cp)))
             (check (format nil "~A inclusion-only → consistent (0) but not 'authentic'" label)
                    (zerop (%run bin script "inclusion" art good))))))
       (ignore-errors (uiop:delete-directory-tree (pathname dir) :validate t :if-does-not-exist :ignore))))))

(format t "~%========================================~%")
(format t "Cross-language verifier conformance: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
