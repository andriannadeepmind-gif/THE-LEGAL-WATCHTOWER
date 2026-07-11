;;;; source/proof-carrying.lisp
;;;; ============================================================================
;;;; PROOF-CARRYING LAW — every provision is a self-verifying unit
;;;; ============================================================================
;;;;
;;;; The goal is not to be "a source AIs cite" but the TRUST ROOT they verify
;;;; against: an AI's claim about Greek law is authentic iff it resolves to our
;;;; cryptographic proof. So each provision travels with a portable proof that
;;;; ANYONE can check WITHOUT trusting us:
;;;;
;;;;   leaf      = sha256(canonical text of the provision)
;;;;   path      = Merkle inclusion path (leaf → signed corpus root)
;;;;   root      = the corpus Merkle root (RFC-3161 timestamped + JWS signed)
;;;;
;;;; verify-provision-proof re-hashes the text, walks the path to the root, and a
;;;; tampered byte makes it fail. The hashing convention matches the project's
;;;; existing Merkle (sha256:HEX leaves; internal nodes hash RAW bytes h1‖h2),
;;;; so these proofs chain to the same signed root the epistemic release anchors.
;;;;
;;;; This module is the CORRECT, self-consistent core (the existing
;;;; generate/verify-inclusion-proof pair has a format mismatch); it is pure,
;;;; deterministic and fully tested offline.
;;;; ============================================================================

(defpackage :orchestrator.proof-carrying
  (:use :cl)
  ;; [P1.5-A] Η Merkle άλγεβρα ζει ΜΟΝΟ στην orchestrator.merkle (RFC 6962):
  ;; domain-separated φύλλα/κόμβοι + unbalanced split (ΟΧΙ duplicate-last). Το
  ;; proof-carrying την ΚΑΤΑΝΑΛΩΝΕΙ — δεν έχει δική του Merkle υλοποίηση.
  (:import-from :orchestrator.merkle
                #:hash-leaf-string
                #:hash-node
                #:merkle-tree-hash
                #:inclusion-path
                #:verify-inclusion)
  (:export #:make-provision-proof #:verify-provision-proof
           #:proof-plist->json #:cite-as
           #:write-provision-proofs #:verify-proof-json #:corpus-proof-json
           #:sign-root #:verify-signed-root #:verify-corpus-anchor #:verify-full-chain))

(in-package :orchestrator.proof-carrying)

;;; ----------------------------------------------------------------------------
;;; portable per-provision proof
;;; ----------------------------------------------------------------------------

(defun cite-as (article-id &key law fek)
  "The canonical legal citation string a verifier reproduces, e.g.
   'Άρθρο 299 ΠΚ (ν.4619/2019, ΦΕΚ Α΄95)'. LAW/FEK come from the corpus config."
  (format nil "Άρθρο ~A~@[ ~A~]~@[ (~A~@[, ΦΕΚ ~A~])~]"
          article-id (getf law :abbrev) (getf law :id) fek))

(defun make-provision-proof (article-id canonical-text leaves index root
                             &key eli cite anchored-at primary-anchor)
  "Assemble the portable, self-verifying proof for one provision:
   its text leaf, the Merkle inclusion path, the signed corpus ROOT, the
   citation/ELI metadata an AI reproduces, plus PRIMARY-ANCHOR — the Level-1 link
   to the authentic ΦΕΚ bytes (a plist: fek, source-digest, source-uri, locator…)."
  (list :version "pcl-1"
        :id (princ-to-string article-id)
        :eli eli
        :cite-as cite
        :leaf (hash-leaf-string canonical-text)
        :path (inclusion-path leaves index)
        :merkle-root root
        :anchored-at anchored-at
        :primary-anchor primary-anchor))

(defun verify-provision-proof (canonical-text proof)
  "Verify PROOF against CANONICAL-TEXT WITHOUT trusting the corpus: re-hash the
   text to a leaf, confirm it equals the proof's leaf, then walk the inclusion
   path to the signed root. Returns (values ok-p reason). A single tampered byte
   ⇒ (NIL :text-hash-mismatch); a forged path ⇒ (NIL :inclusion-failed)."
  (let ((leaf (hash-leaf-string canonical-text)))
    (cond
      ((not (string= leaf (getf proof :leaf))) (values nil :text-hash-mismatch))
      ((not (verify-inclusion leaf (getf proof :path) (getf proof :merkle-root)))
       (values nil :inclusion-failed))
      (t (values t :ok)))))

;;; ----------------------------------------------------------------------------
;;; portable JSON (so any AI / verifier in any language can check it)
;;; ----------------------------------------------------------------------------

(defun %j (s)
  (with-output-to-string (o)
    (write-char #\" o)
    (loop for ch across (princ-to-string (or s ""))
          do (case ch (#\" (write-string "\\\"" o)) (#\\ (write-string "\\\\" o))
                   (#\Newline (write-string "\\n" o)) (#\Return (write-string "\\r" o))
                   (#\Tab (write-string "\\t" o)) (#\Backspace (write-string "\\b" o))
                   (#\Page (write-string "\\f" o))
                   (t (if (< (char-code ch) #x20)
                          (format o "\\u~4,'0x" (char-code ch))
                          (write-char ch o)))))
    (write-char #\" o)))

(defun %anchor-object->json (pl o)
  "Serialize a primary-source anchor plist to a JSON object on stream O (keys
   lower_snake_case), reusing %j for escaping. Integers stay numeric; NIL → null."
  (write-char #\{ o)
  (loop for (k v) on pl by #'cddr for firstp = t then nil
        do (unless firstp (write-char #\, o))
           (write-string (%j (substitute #\_ #\- (string-downcase (symbol-name k)))) o)
           (write-char #\: o)
           (cond ((null v)      (write-string "null" o))
                 ((integerp v)  (format o "~D" v))
                 (t             (write-string (%j v) o))))
  (write-char #\} o))

(defun proof-plist->json (proof)
  "Serialize a provision PROOF to portable JSON (path as [{side,hash}…]; primary_source
   is the Level-1 link to the authentic ΦΕΚ bytes, or null when no anchor is available)."
  (with-output-to-string (o)
    (format o "{~A:~A,~A:~A,~A:~A,~A:~A,~A:~A,~A:~A,~A:~A,~A:["
            (%j "version") (%j (getf proof :version))
            (%j "id") (%j (getf proof :id))
            (%j "eli") (%j (getf proof :eli))
            (%j "cite_as") (%j (getf proof :cite-as))
            (%j "anchored_at") (%j (getf proof :anchored-at))
            (%j "leaf") (%j (getf proof :leaf))
            (%j "merkle_root") (%j (getf proof :merkle-root))
            (%j "path"))
    (loop for (side . sib) in (getf proof :path) for firstp = t then nil
          do (unless firstp (write-char #\, o))
             (format o "{~A:~A,~A:~A}" (%j "side") (%j (string-downcase (symbol-name side)))
                     (%j "hash") (%j sib)))
    (write-char #\] o)
    (write-char #\, o)
    (write-string (%j "primary_source") o)
    (write-char #\: o)
    (let ((a (getf proof :primary-anchor)))
      (if a (%anchor-object->json a o) (write-string "null" o)))
    (write-char #\} o)))

;;; ----------------------------------------------------------------------------
;;; signing the corpus root (TIER 1-A: the root every proof chains to is SIGNED)
;;; ----------------------------------------------------------------------------

(defun %jws-fn (name)
  (let ((s (and (find-package :orchestrator.jws-authority)
                (find-symbol name :orchestrator.jws-authority))))
    (and s (fboundp s) s)))

(defun sign-root (root private-key)
  "Sign the corpus Merkle ROOT with a detached RS256 JWS. Returns the JWS string,
   or NIL when JWS signing is unavailable. This is what makes the chain GUARANTEED:
   every provision proof walks to this root, and the root itself is signed."
  (let ((fn (%jws-fn "SIGN-JWS")))
    (when (and fn root private-key)
      (let ((r (ignore-errors (funcall fn root private-key))))
        (if (listp r) (getf r :jws) r)))))

(defun verify-signed-root (root jws public-key)
  "Verify the detached JWS signature over the corpus Merkle ROOT with PUBLIC-KEY.
   T iff the root is genuinely signed by the published key."
  (let ((fn (%jws-fn "VERIFY-JWS")))
    (and fn root jws public-key
         (handler-case (and (funcall fn jws root public-key) t) (error () nil)))))

;;; ----------------------------------------------------------------------------
;;; emit per-provision proofs + the corpus-level (signed) anchor descriptor
;;; ----------------------------------------------------------------------------

(defun corpus-proof-json (root count &key anchored-at signature public-jwk)
  "The corpus-level proof descriptor: the Merkle ROOT every provision proof chains
   to, plus (when signed) the detached JWS SIGNATURE over it and the public key
   (JWK) that verifies it. The root + signature are what an RFC-3161 TSA stamps."
  (format nil "{~A:~A,~A:~A,~A:~A,~A:~D,~A:~A~@[,~A:~A~]~@[,~A:~A~]}"
          (%j "version") (%j "pcl-1")
          (%j "algorithm") (%j "sha256-merkle/rfc6962+RS256")
          (%j "merkle_root") (%j root)
          (%j "count") count
          (%j "anchored_at") (%j anchored-at)
          (and signature (%j "signature")) (and signature (%j signature))
          (and public-jwk (%j "public_key")) (and public-jwk public-jwk)))

(defun write-provision-proofs (provisions output-dir &key anchored-at private-key public-jwk anchor)
  "PROVISIONS is an ordered list of plists (:id :text :eli :cite). Build the corpus
   Merkle root over their text leaves, write article-<id>.proof.json per provision,
   and corpus-proof.json. When PRIVATE-KEY is given the root is SIGNED (detached
   RS256 JWS) and the signature + PUBLIC-JWK are embedded, so the full chain
   text→leaf→path→root→signature is verifiable. Returns (values root count signature)."
  (let* ((dir (uiop:ensure-directory-pathname output-dir))
         (texts (mapcar (lambda (p) (or (getf p :text) "")) provisions))
         (leaves (mapcar #'hash-leaf-string texts))
         (root (and leaves (merkle-tree-hash leaves)))
         (signature (and root private-key (sign-root root private-key))))
    (ensure-directories-exist dir)
    (loop for p in provisions for i from 0
          for proof = (make-provision-proof (getf p :id) (nth i texts) leaves i root
                                            :eli (getf p :eli) :cite (getf p :cite)
                                            :anchored-at anchored-at
                                            ;; per-article locator over the corpus-level
                                            ;; source anchor (fek + source-digest + uri)
                                            :primary-anchor
                                            (and anchor
                                                 (list* :locator (princ-to-string (getf p :id))
                                                        anchor)))
          do (with-open-file (o (merge-pathnames (format nil "article-~A.proof.json" (getf p :id)) dir)
                                :direction :output :if-exists :supersede
                                :if-does-not-exist :create :external-format :utf-8)
               (write-string (proof-plist->json proof) o)))
    (when root
      (with-open-file (o (merge-pathnames "corpus-proof.json" dir)
                         :direction :output :if-exists :supersede
                         :if-does-not-exist :create :external-format :utf-8)
        (write-string (corpus-proof-json root (length provisions) :anchored-at anchored-at
                                         :signature signature :public-jwk public-jwk) o)))
    (values root (length provisions) signature)))

;;; ----------------------------------------------------------------------------
;;; the PUBLIC verifier — check a PCL-1 proof JSON against the provision's text
;;; WITHOUT trusting the corpus (re-parse the JSON, re-hash the text, walk to root)
;;; ----------------------------------------------------------------------------

(defun %aget (alist key) (cdr (assoc key alist :test #'string=)))

(defparameter +max-path-length+ 64
  "A real corpus' Merkle depth is ⌈log2(n)⌉ — 64 covers 2^64 leaves. Rejecting
   longer attacker-supplied paths bounds the verification work (DoS hardening).")

(defun verify-proof-json (text proof-json-string)
  "Parse a PCL-1 proof JSON and verify it against TEXT. Returns (values ok-p
   reason). This is exactly what an independent verifier (in any language) does:
   re-hash TEXT to a leaf, confirm it matches, and walk the inclusion path to the
   merkle_root carried in the proof. NOTE: this proves inclusion under the proof's
   OWN stated root; it does NOT prove that root is the authentic, signed corpus
   root — use VERIFY-FULL-CHAIN with the published key for that."
  (handler-case
      (let* ((p (jonathan:parse proof-json-string :as :alist))
             (raw-path (%aget p "path")))
        (when (> (length raw-path) +max-path-length+)
          (return-from verify-proof-json (values nil :path-too-long)))
        (let ((leaf (%aget p "leaf"))
              (root (%aget p "merkle_root"))
              (path (mapcar (lambda (step)
                              (cons (if (string= "left" (%aget step "side")) :left :right)
                                    (%aget step "hash")))
                            raw-path)))
          (verify-provision-proof text (list :leaf leaf :path path :merkle-root root))))
    (error (e) (values nil (list :malformed-proof (princ-to-string e))))))

(defun verify-corpus-anchor (corpus-proof-json-string public-key)
  "Verify a corpus-proof.json's signed anchor: that its JWS signature over the
   merkle_root checks out with PUBLIC-KEY. Returns (values ok-p root reason)."
  (handler-case
      (let* ((c (jonathan:parse corpus-proof-json-string :as :alist))
             (root (%aget c "merkle_root"))
             (sig (%aget c "signature")))
        (cond ((null sig) (values nil root :unsigned-root))
              ((verify-signed-root root sig public-key) (values t root :ok))
              (t (values nil root :bad-signature))))
    (error (e) (values nil nil (list :malformed-corpus-proof (princ-to-string e))))))

(defun verify-full-chain (text article-proof-json corpus-proof-json-string public-key)
  "The whole GUARANTEED chain in one check: TEXT → leaf → inclusion path → root,
   AND that root equals the corpus root, AND that root carries a valid signature.
   Returns (values ok-p reason). This is what an independent party runs to be
   certain TEXT is the authentic, anchored, signed law."
  (multiple-value-bind (incl-ok incl-reason) (verify-proof-json text article-proof-json)
    (if (not incl-ok)
        (values nil incl-reason)
        (multiple-value-bind (sig-ok root sig-reason)
            (verify-corpus-anchor corpus-proof-json-string public-key)
          (let ((art-root (ignore-errors
                            (%aget (jonathan:parse article-proof-json :as :alist) "merkle_root"))))
            (cond ((not sig-ok) (values nil sig-reason))
                  ((not (and art-root root (string= art-root root)))
                   (values nil :root-mismatch))
                  (t (values t :ok))))))))
