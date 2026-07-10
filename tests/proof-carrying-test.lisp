;;;; tests/proof-carrying-test.lisp
;;;; Proof-Carrying Law: every provision is a self-verifying unit. A correct
;;;; proof verifies WITHOUT trusting the corpus; a single tampered byte, a forged
;;;; path, or another article's proof must all FAIL. Pure, deterministic, offline.

(in-package :orchestrator.proof-carrying)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun texts (n) (loop for i from 1 to n collect (format nil "Άρθρο ~D — αυθεντικό κείμενο διάταξης." i)))
(defun leaves-of (texts) (mapcar #'hash-leaf-string texts))

(format t "~%== leaf hashing (deterministic, sha256: convention) ==~%")
(check "hash-leaf-string carries the sha256: prefix" (eql 0 (search "sha256:" (hash-leaf-string "x"))))
(check "hash-leaf-string is deterministic" (string= (hash-leaf-string "Άρθρο 299") (hash-leaf-string "Άρθρο 299")))
(check "different text → different leaf" (not (string= (hash-leaf-string "α") (hash-leaf-string "β"))))
(check "hash-node is order-sensitive (a‖b ≠ b‖a)"
       (not (string= (hash-node (hash-leaf-string "a") (hash-leaf-string "b"))
                     (hash-node (hash-leaf-string "b") (hash-leaf-string "a")))))

(format t "~%== a single-leaf tree: leaf IS the root ==~%")
(let* ((tx (texts 1)) (lv (leaves-of tx)) (root (merkle-tree-hash lv)))
  (check "root of one leaf equals that leaf" (string= root (first lv)))
  (check "its (empty) path verifies" (verify-inclusion (first lv) (inclusion-path lv 0) root)))

(format t "~%== every leaf's inclusion path verifies to the root (2,3,4,5,536) ==~%")
(dolist (n '(2 3 4 5 536))
  (let* ((tx (texts n)) (lv (leaves-of tx)) (root (merkle-tree-hash lv))
         (all-ok t))
    (dotimes (i n)
      (unless (verify-inclusion (nth i lv) (inclusion-path lv i) root) (setf all-ok nil)))
    (check (format nil "all ~D leaves prove inclusion (odd-count safe)" n) all-ok)))

(format t "~%== full provision proof: make + verify ==~%")
(let* ((tx (texts 536)) (lv (leaves-of tx)) (root (merkle-tree-hash lv))
       (idx 298)                                   ; the famous art. 299 is index 298
       (proof (make-provision-proof "299" (nth idx tx) lv idx root
                                    :eli "https://stavropouloslaw.com/eli/gr/l/2019/4619/art/299"
                                    :cite (cite-as "299" :law '(:abbrev "ΠΚ" :id "ν.4619/2019") :fek "Α΄95")
                                    :anchored-at "2025-01-01T00:00:00Z")))
  (multiple-value-bind (ok reason) (verify-provision-proof (nth idx tx) proof)
    (check "the authentic text verifies against its proof" ok)
    (check "reason is :ok" (eq :ok reason)))
  (check "the proof carries its citation" (string= "Άρθρο 299 ΠΚ (ν.4619/2019, ΦΕΚ Α΄95)" (getf proof :cite-as)))
  (check "the proof carries the ELI" (search "/art/299" (getf proof :eli)))

  (format t "~%== tamper detection (the trust-root property) ==~%")
  (multiple-value-bind (ok reason) (verify-provision-proof
                                    (concatenate 'string (nth idx tx) " (αλλοιωμένο)") proof)
    (check "a single tampered byte FAILS" (not ok))
    (check "reason is :text-hash-mismatch" (eq :text-hash-mismatch reason)))

  (multiple-value-bind (ok reason)
      (verify-provision-proof (nth 100 tx) proof)   ; different article's text
    (check "another article's text does NOT verify against this proof" (not ok))
    (check "reason is :text-hash-mismatch" (eq :text-hash-mismatch reason)))

  (let ((forged (copy-list proof)))
    ;; corrupt one sibling hash in the path → inclusion must fail
    (setf (getf forged :path)
          (cons (cons (car (first (getf proof :path))) (hash-leaf-string "forged-sibling"))
                (rest (getf proof :path))))
    (multiple-value-bind (ok reason) (verify-provision-proof (nth idx tx) forged)
      (check "a forged inclusion path FAILS" (not ok))
      (check "reason is :inclusion-failed" (eq :inclusion-failed reason))))

  (format t "~%== portable JSON (any language can verify) ==~%")
  (let* ((json (proof-plist->json proof))
         (parsed (jonathan:parse json :as :alist)))
    (check "JSON re-parses" (consp parsed))
    (check "JSON keeps the merkle_root"
           (string= root (cdr (assoc "merkle_root" parsed :test #'string=))))
    (check "JSON keeps the citation"
           (search "299" (princ-to-string (cdr (assoc "cite_as" parsed :test #'string=)))))
    (check "JSON path is a non-empty array"
           (let ((p (cdr (assoc "path" parsed :test #'string=)))) (and (listp p) (plusp (length p)))))))

(format t "~%== RFC 6962 domain separation (leaf 0x00, node 0x01) ==~%")
(flet ((raw-sha (prefix bytes)
         (format nil "sha256:~(~{~2,'0x~}~)"
                 (coerce (ironclad:digest-sequence :sha256
                          (concatenate '(vector (unsigned-byte 8)) prefix bytes)) 'list))))
  (check "hash-leaf-string prepends the 0x00 leaf domain byte"
         (string= (hash-leaf-string "x") (raw-sha #(#x00) (babel:string-to-octets "x" :encoding :utf-8))))
  (check "hash-node prepends the 0x01 node domain byte"
         (let ((a (hash-leaf-string "a")) (b (hash-leaf-string "b")))
           (string= (hash-node a b)
                    (raw-sha #(#x01) (concatenate '(vector (unsigned-byte 8))
                                                  (ironclad:hex-string-to-byte-array (subseq a 7))
                                                  (ironclad:hex-string-to-byte-array (subseq b 7)))))))
  ;; A leaf and an internal node over the SAME 64 raw bytes must NOT collide.
  (check "a leaf can never be reinterpreted as an internal node"
         (let* ((a (hash-leaf-string "a")) (b (hash-leaf-string "b"))
                (node (hash-node a b))
                (sixtyfour (concatenate '(vector (unsigned-byte 8))
                                        (ironclad:hex-string-to-byte-array (subseq a 7))
                                        (ironclad:hex-string-to-byte-array (subseq b 7))))
                (leaf-over-same-bytes (raw-sha #(#x00) sixtyfour)))
           (not (string= node leaf-over-same-bytes)))))

(format t "~%== DoS hardening: an over-long inclusion path is rejected ==~%")
(let* ((step "{\"side\":\"right\",\"hash\":\"sha256:00\"}")
       (long-path (format nil "[~{~A~^,~}]" (loop repeat 65 collect step)))
       (json (format nil "{\"leaf\":\"sha256:00\",\"merkle_root\":\"sha256:00\",\"path\":~A}" long-path)))
  (multiple-value-bind (ok reason) (verify-proof-json "x" json)
    (check "a path longer than 64 fails fast" (and (not ok) (eq :path-too-long reason)))))

(format t "~%== determinism: same corpus → same root & proofs ==~%")
(let ((a (merkle-tree-hash (leaves-of (texts 64))))
      (b (merkle-tree-hash (leaves-of (texts 64)))))
  (check "the Merkle root is deterministic" (string= a b)))

(format t "~%== emit per-provision proof files + verify them back from JSON ==~%")
(let* ((dir (format nil "/tmp/pcl-emit-~A/" (get-universal-time)))
       (provisions (list (list :id "1"    :text "Καμία ποινή χωρίς νόμο." :eli "…/art/1"   :cite "Άρθρο 1 ΠΚ")
                         (list :id "100"  :text "Αναστολή εκτέλεσης ποινής υπό όρο." :eli "…/art/100" :cite "Άρθρο 100 ΠΚ")
                         (list :id "100Α" :text "Αναστολή υπό επιτήρηση." :eli "…/art/100Α" :cite "Άρθρο 100Α ΠΚ")
                         (list :id "299"  :text "Ανθρωποκτονία με πρόθεση." :eli "…/art/299" :cite "Άρθρο 299 ΠΚ"))))
  (multiple-value-bind (root count) (write-provision-proofs provisions dir :anchored-at "2025-01-01T00:00:00Z")
    (check "emit returns the corpus root + count" (and (stringp root) (= 4 count)))
    (check "a proof file exists per article (lettered included)"
           (and (probe-file (format nil "~Aarticle-1.proof.json" dir))
                (probe-file (format nil "~Aarticle-100Α.proof.json" dir))
                (probe-file (format nil "~Aarticle-299.proof.json" dir))))
    (check "corpus-proof.json exists with the root"
           (search root (uiop:read-file-string (format nil "~Acorpus-proof.json" dir) :external-format :utf-8)))
    ;; the PUBLIC verifier: read each proof.json and check it against the text
    (let ((all-ok t))
      (dolist (p provisions)
        (let ((json (uiop:read-file-string (format nil "~Aarticle-~A.proof.json" dir (getf p :id))
                                           :external-format :utf-8)))
          (unless (verify-proof-json (getf p :text) json) (setf all-ok nil))))
      (check "every emitted proof verifies from its JSON against the authentic text" all-ok))
    ;; tamper: wrong text must fail through the JSON verifier too
    (let ((json (uiop:read-file-string (format nil "~Aarticle-299.proof.json" dir) :external-format :utf-8)))
      (multiple-value-bind (ok reason) (verify-proof-json "Κλοπή." json)
        (check "the JSON verifier rejects tampered text" (and (not ok) (eq :text-hash-mismatch reason))))
      (check "100 and 100Α get DISTINCT proofs (different leaves)"
             (not (string= (uiop:read-file-string (format nil "~Aarticle-100.proof.json" dir) :external-format :utf-8)
                           (uiop:read-file-string (format nil "~Aarticle-100Α.proof.json" dir) :external-format :utf-8))))))
  (ignore-errors (uiop:delete-directory-tree (pathname dir) :validate t :if-does-not-exist :ignore)))

(format t "~%== TIER 1-A: the corpus root is SIGNED → the chain is GUARANTEED ==~%")
(let* ((kp (orchestrator.jws-authority:generate-rsa-keypair :bits 2048))
       (priv (getf kp :private-key)) (pub (getf kp :public-key))
       (dir (format nil "/tmp/pcl-sign-~A/" (get-universal-time)))
       (provs (list (list :id "299" :text "Ανθρωποκτονία με πρόθεση." :eli "…/299" :cite "Άρθρο 299 ΠΚ")
                    (list :id "300" :text "Ανθρωποκτονία από αμέλεια." :eli "…/300" :cite "Άρθρο 300 ΠΚ"))))
  (multiple-value-bind (root count sig)
      (write-provision-proofs provs dir :private-key priv :public-jwk "{\"kty\":\"RSA\"}"
                              :anchored-at "2025-01-01T00:00:00Z")
    (declare (ignore count))
    (check "the root gets a signature" (and (stringp sig) (plusp (length sig))))
    (check "verify-signed-root accepts the genuine signature" (verify-signed-root root sig pub))
    (check "verify-signed-root rejects a tampered root" (not (verify-signed-root (hash-leaf-string "x") sig pub)))
    (let ((art (uiop:read-file-string (format nil "~Aarticle-299.proof.json" dir) :external-format :utf-8))
          (cp  (uiop:read-file-string (format nil "~Acorpus-proof.json" dir) :external-format :utf-8)))
      (check "corpus-proof.json carries the signature + public key"
             (and (search "\"signature\"" cp) (search "\"public_key\"" cp)))
      (multiple-value-bind (ok reason) (verify-full-chain "Ανθρωποκτονία με πρόθεση." art cp pub)
        (check "FULL CHAIN verifies: text→leaf→path→root→SIGNATURE" ok)
        (check "reason :ok" (eq :ok reason)))
      (multiple-value-bind (ok reason) (verify-full-chain "Αλλοιωμένο." art cp pub)
        (check "a tampered byte breaks the full chain" (and (not ok) (eq :text-hash-mismatch reason))))
      (let* ((kp2 (orchestrator.jws-authority:generate-rsa-keypair :bits 2048))
             (pub2 (getf kp2 :public-key)))
        (multiple-value-bind (ok reason) (verify-full-chain "Ανθρωποκτονία με πρόθεση." art cp pub2)
          (check "the WRONG public key → signature fails" (and (not ok) (eq :bad-signature reason)))))))
  (ignore-errors (uiop:delete-directory-tree (pathname dir) :validate t :if-does-not-exist :ignore)))

(format t "~%========================================~%")
(format t "Proof-carrying tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
