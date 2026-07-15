;;;; tests/authority-cross-language-test.lisp
;;;; ============================================================================
;;;; [0088 Φ7-HARDENING #4B] N-VERSION AGREEMENT: ανεξάρτητος Python verifier
;;;; ============================================================================
;;;; Ο Lisp παράγει τα δομικά commitments (RFC-6962 merkle roots, canonical
;;;; authority-statement + sha256, RFC-7638 Ed25519 thumbprint) από τις ΕΔΡΕΣ·
;;;; ο ανεξάρτητος deployment/verify/verify-authority-bundle.py (ΜΟΝΟ Python
;;;; stdlib, καμία Lisp έδρα) τα ΞΑΝΑΫΠΟΛΟΓΙΖΕΙ. 0 διαφωνίες = N-version
;;;; agreement — αλλιώς ΣΦΑΛΜΑ (η δεύτερη γλώσσα πιάνει σφάλμα κωδικοποίησης
;;;; που μια μόνη υλοποίηση θα «επιβεβαίωνε» ταυτολογικά).
;;;; ============================================================================

(in-package :orchestrator.apb-replay)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %sha256hex (str)
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string
           (ironclad:digest-sequence :sha256 (babel:string-to-octets str :encoding :utf-8)))))

;; ── Lisp-side commitments ΑΠΟ ΤΙΣ ΕΔΡΕΣ ──
(multiple-value-bind (sk pk) (ironclad:generate-key-pair :ed25519)
  (declare (ignore sk))
  (defparameter *owner-x* (cdr (assoc "x" (apb:ed25519-public-to-jwk pk) :test #'equal)))
  (defparameter *owner-thumb* (apb:ed25519-jwk-thumbprint pk)))

(defparameter *receipt-ids* (list "rid:a" "rid:b" "sha256:receipt-c" "rid:d" "rid:e"))
(defparameter *receipt-set-root* (orchestrator.merkle:merkle-root-of-strings *receipt-ids*))
(defparameter *verifier-set* (list "sha256:vt" "sha256:vr" "sha256:vc"))
(defparameter *verifier-set-root* (orchestrator.merkle:merkle-root-of-strings *verifier-set*))

;; authority-statement fields (string keys/values) — ίδιο dict σε Lisp & Python
(defparameter *astmt-fields*
  (list (cons "protocol" +bundle-protocol+)
        (cons "corpus_id" "syntagma")
        (cons "graph_root" "sha256:graphrootABC")
        (cons "receipt_set_root" *receipt-set-root*)
        (cons "verifier_set_root" *verifier-set-root*)
        (cons "tlog_root" "sha256:tlogXYZ")
        (cons "policy_digest" "sha256:pol")))
(defparameter *astmt-canonical*
  (apb:canonical-statement-string +authority-statement-tag+ *astmt-fields*))
(defparameter *astmt-sha256* (%sha256hex *astmt-canonical*))

;; merkle boundary sizes (n=1, n=2) + inclusion + consistency (RFC-6962/9162)
(defparameter *n1* (list "solo"))
(defparameter *n2* (list "a" "b"))
(defun %incl-json (strings idx)
  "inclusion path ως JSON-friendly [[side sib]...]"
  (let ((hashes (mapcar #'orchestrator.merkle:hash-leaf-string strings)))
    (mapcar (lambda (step)
              (list (cons "side" (string-downcase (symbol-name (car step))))
                    (cons "sib" (cdr step))))
            (orchestrator.merkle:inclusion-path hashes idx))))
(defparameter *incl-strings* (list "x0" "x1" "x2" "x3" "x4"))
(defparameter *incl-idx* 3)
(defparameter *incl-leaf* (orchestrator.merkle:hash-leaf-string (nth *incl-idx* *incl-strings*)))
(defparameter *incl-root* (orchestrator.merkle:merkle-root-of-strings *incl-strings*))
(defparameter *incl-path* (%incl-json *incl-strings* *incl-idx*))
;; consistency m=2,n=5
(defparameter *cons-leaves* (mapcar #'orchestrator.merkle:hash-leaf-string
                                    (list "c0" "c1" "c2" "c3" "c4")))
(defparameter *cons-old* (orchestrator.merkle:merkle-tree-hash (subseq *cons-leaves* 0 2)))
(defparameter *cons-new* (orchestrator.merkle:merkle-tree-hash *cons-leaves*))
(defparameter *cons-proof* (orchestrator.merkle:consistency-proof *cons-leaves* 2))

;; non-canonical x (low-bit variant, ίδια 32 bytes)
(defparameter *owner-x-nc*
  (let* ((alpha "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
         (lastc (char *owner-x* (1- (length *owner-x*)))))
    (concatenate 'string (subseq *owner-x* 0 (1- (length *owner-x*)))
                 (string (char alpha (mod (1+ (position lastc alpha)) 64))))))

;; ── emit vector JSON ──
(defparameter *vec*
  (list (cons "receipt_ids" *receipt-ids*)
        (cons "receipt_set_root" *receipt-set-root*)
        (cons "verifier_set" *verifier-set*)
        (cons "verifier_set_root" *verifier-set-root*)
        (cons "authority_statement_tag" +authority-statement-tag+)
        (cons "authority_statement_fields" *astmt-fields*)
        (cons "authority_statement_sha256" *astmt-sha256*)
        (cons "owner_x" *owner-x*)
        (cons "owner_x_noncanonical" *owner-x-nc*)
        (cons "owner_thumbprint" *owner-thumb*)
        (cons "merkle_roots"
              (list (list (cons "label" "n1") (cons "strings" *n1*)
                          (cons "root" (orchestrator.merkle:merkle-root-of-strings *n1*)))
                    (list (cons "label" "n2") (cons "strings" *n2*)
                          (cons "root" (orchestrator.merkle:merkle-root-of-strings *n2*)))))
        (cons "inclusions"
              (list (list (cons "label" "idx3of5") (cons "leaf" *incl-leaf*)
                          (cons "path" *incl-path*) (cons "root" *incl-root*)
                          (cons "expect" t))))
        (cons "consistencies"
              (list (list (cons "label" "m2n5") (cons "m" 2) (cons "n" 5)
                          (cons "old_root" *cons-old*) (cons "new_root" *cons-new*)
                          (cons "proof" *cons-proof*) (cons "expect" t))))))

(defparameter *vec-path*
  (merge-pathnames "apb-xlang-vector.json"
                   (uiop:ensure-directory-pathname
                    (or (uiop:getenv "TMPDIR") "/tmp/"))))
(with-open-file (s *vec-path* :direction :output :if-exists :supersede
                              :if-does-not-exist :create :external-format :utf-8)
  (write-string (jonathan:to-json *vec* :from :alist) s))

(defparameter *py* (orchestrator.paths:institution-dir "deployment/verify/verify-authority-bundle.py"))

(format t "~%== [1] N-version agreement (Python ανεξάρτητος recompute) ==~%")
(multiple-value-bind (out err code)
    (uiop:run-program (list "python3" (namestring *py*) (namestring *vec-path*))
                      :output :string :error-output :string :ignore-error-status t)
  (format t "~A" out)
  (ck "python verifier exit 0 (0 διαφωνίες)" (zerop code))
  (ck "python OK γραμμή" (search "N-version agreement" out))
  (when (plusp code) (format t "stderr: ~A~%" err)))

;; ── αρνητικά: ΚΑΘΕ commitment νοθεύεται ξεχωριστά ⇒ κάθε cross-check ζωντανό
;;    (cross-lang-critic SERIOUS-1: 3/4 checks ήταν χωρίς αρνητικό μάρτυρα) ──
(format t "~%== [2] Αρνητικά: κάθε cross-check ζωντανό ==~%")
(defun run-py-on (vec)
  (with-open-file (s *vec-path* :direction :output :if-exists :supersede :external-format :utf-8)
    (write-string (jonathan:to-json vec :from :alist) s))
  (uiop:run-program (list "python3" (namestring *py*) (namestring *vec-path*))
                    :output :string :error-output :string :ignore-error-status t))
(defun mutate (key val)
  (let ((bad (copy-tree *vec*))) (setf (cdr (assoc key bad :test #'equal)) val) bad))
(dolist (case (list (list "receipt_set_root" "sha256:FORGED" "receipt_set_root")
                    (list "verifier_set_root" "sha256:FORGED" "verifier_set_root")
                    (list "authority_statement_sha256" "sha256:FORGED" "authority_statement_sha256")
                    (list "owner_thumbprint" "FORGEDTHUMB" "owner_thumbprint")))
  (destructuring-bind (key val expect) case
    (multiple-value-bind (out e code) (run-py-on (mutate key val))
      (declare (ignore e))
      (ck (format nil "νοθευμένο ~A ⇒ python exit 1" key) (not (zerop code)))
      (ck (format nil "  python ονομάζει ~A" expect) (search expect out)))))
;; νοθευμένο consistency old_root ⇒ python πιάνει (RFC-9162 loop, ΟΧΙ Lisp seat)
(let ((bad (copy-tree *vec*)))
  (setf (cdr (assoc "consistencies" bad :test #'equal))
        (list (list (cons "label" "m2n5") (cons "m" 2) (cons "n" 5)
                    (cons "old_root" "sha256:FORGEDOLD") (cons "new_root" *cons-new*)
                    (cons "proof" *cons-proof*) (cons "expect" t))))
  (multiple-value-bind (out e code) (run-py-on bad)
    (declare (ignore e out))
    (ck "νοθευμένο consistency old_root ⇒ python exit 1 (RFC-9162)" (not (zerop code)))))
;; νοθευμένο inclusion root ⇒ python πιάνει (RFC-6962 audit path)
(let ((bad (copy-tree *vec*)))
  (setf (cdr (assoc "inclusions" bad :test #'equal))
        (list (list (cons "label" "idx3of5") (cons "leaf" *incl-leaf*)
                    (cons "path" *incl-path*) (cons "root" "sha256:FORGEDROOT") (cons "expect" t))))
  (multiple-value-bind (out e code) (run-py-on bad)
    (declare (ignore e out))
    (ck "νοθευμένο inclusion root ⇒ python exit 1 (RFC-6962)" (not (zerop code)))))

(ignore-errors (delete-file *vec-path*))

(format t "~%======================================================~%")
(format t "authority-cross-language: ~D passed, ~D failed~%" *p* *f*)
(when (plusp *f*) (format t "ΑΠΟΤΥΧΙΑ~%") (sb-ext:exit :code 1))
(format t "ΟΛΑ ΠΡΑΣΙΝΑ — N-version (Lisp↔Python) agreement κλειδωμένο~%")
