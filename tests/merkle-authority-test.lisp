;;;; tests/merkle-authority-test.lisp
;;;; RFC 6962 conformance for the ONE Merkle seat (orchestrator.merkle):
;;;; domain separation, unbalanced split (anti CVE-2012-2459), audit paths.

(in-package :orchestrator.merkle)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro ck (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== Domain separation (RFC 6962 §2.1) ==~%")
;; leaf(x) uses 0x00 prefix; a 1-element tree = the leaf itself, NOT re-hashed.
(let ((l (hash-leaf-string "a")))
  (ck "1-element tree = το φύλλο (κανένα re-hash)"
      (string= (merkle-tree-hash (list l)) l))
  ;; leaf hash ≠ raw sha256 of the bytes (prefix present)
  (ck "leaf ≠ ωμό sha256 (πρόθεμα 0x00 παρόν)"
      (not (string= l (format nil "sha256:~(~{~2,'0x~}~)"
                              (coerce (ironclad:digest-sequence
                                       :sha256 (babel:string-to-octets "a")) 'list))))))
;; node prefix: hash-node(a,a) ≠ leaf built from concatenation
(let* ((a (hash-leaf-string "a")))
  (ck "node(a,a) ≠ leaf(raw a‖a) — 0x01 vs 0x00 domain"
      (not (string= (hash-node a a)
                    (hash-leaf-bytes (concatenate '(vector (unsigned-byte 8))
                                                  (ironclad:hex-string-to-byte-array (subseq a 7))
                                                  (ironclad:hex-string-to-byte-array (subseq a 7))))))))

(format t "~%== CVE-2012-2459 resistance (unbalanced split, ΟΧΙ duplicate-last) ==~%")
(let* ((a (hash-leaf-string "a")) (b (hash-leaf-string "b")) (c (hash-leaf-string "c")))
  ;; RFC 6962: MTH([a,b,c]) = node(node(a,b), c)  — c is NOT duplicated.
  (ck "MTH([a,b,c]) = node(node(a,b), c) (RFC 6962 split k=2)"
      (string= (merkle-tree-hash (list a b c))
               (hash-node (hash-node a b) c)))
  ;; The CVE: honest 3-leaf tree must DIFFER from a forged [a,b,c,c] 4-leaf tree.
  (ck "MTH([a,b,c]) ≠ MTH([a,b,c,c]) (duplicate-last ΘΑ έδινε ίδια ρίζα)"
      (not (string= (merkle-tree-hash (list a b c))
                    (merkle-tree-hash (list a b c c)))))
  ;; 4 leaves: balanced.
  (let ((d (hash-leaf-string "d")))
    (ck "MTH([a,b,c,d]) = node(node(a,b), node(c,d))"
        (string= (merkle-tree-hash (list a b c d))
                 (hash-node (hash-node a b) (hash-node c d))))))

;; 5 leaves: k=4 ⇒ node(MTH([a..d]), e)
(let* ((ls (mapcar #'hash-leaf-string '("a" "b" "c" "d" "e")))
       (abcd (hash-node (hash-node (first ls) (second ls))
                        (hash-node (third ls) (fourth ls)))))
  (ck "MTH(5 φύλλα) = node(MTH(4), φύλλο5) (k=4)"
      (string= (merkle-tree-hash ls) (hash-node abcd (fifth ls)))))

(format t "~%== Determinism ==~%")
(ck "ίδια είσοδος ⇒ ίδια ρίζα"
    (string= (merkle-root-of-strings '("x" "y" "z" "w" "q"))
             (merkle-root-of-strings '("x" "y" "z" "w" "q"))))
(ck "σειρά μετράει (μετάθεση ⇒ διαφορετική ρίζα)"
    (not (string= (merkle-root-of-strings '("x" "y" "z"))
                  (merkle-root-of-strings '("z" "y" "x")))))

(format t "~%== Inclusion / audit paths (RFC 6962 §2.1.1) ==~%")
(dolist (n '(1 2 3 5 7 8 13))
  (let* ((leaves (loop for i below n collect (hash-leaf-string (format nil "leaf-~D" i))))
         (root (merkle-tree-hash leaves))
         (all-ok t) (all-reject t))
    (loop for i below n
          for lh = (nth i leaves)
          for path = (inclusion-path leaves i)
          do (unless (verify-inclusion lh path root) (setf all-ok nil))
             ;; wrong leaf must be rejected
             (when (verify-inclusion (hash-leaf-string "WRONG") path root)
               (setf all-reject nil)))
    (ck (format nil "n=~D: κάθε φύλλο επαληθεύεται· λάθος φύλλο απορρίπτεται" n)
        (and all-ok all-reject))))

;; Tamper: swapping a sibling in the path must break verification.
(let* ((leaves (mapcar #'hash-leaf-string '("a" "b" "c" "d" "e")))
       (root (merkle-tree-hash leaves))
       (path (inclusion-path leaves 0))
       (bad (cons (cons (car (first path)) (hash-leaf-string "TAMPER")) (rest path))))
  (ck "παραποίηση αδερφού στο path ⇒ αποτυχία επαλήθευσης"
      (not (verify-inclusion (first leaves) bad root))))

(format t "~%== Edge: ΚΕΝΟ ΔΕΝΤΡΟ — ΜΗΧΑΝΙΣΜΟΣ, όχι πολιτική ==~%")
;; [MERKLE-SINGLE-TRUTH] ΑΛΛΑΓΗ ΣΥΜΒΟΛΑΙΟΥ, κατ' εντολή του profile
;; `lawmax-merkle-sha256-v1` (RFC 9162 §2.1.1): ο ΠΡΩΤΟΓΟΝΟΣ οφείλει να δίνει
;; την ΚΑΝΟΝΙΚΗ ρίζα του κενού δέντρου — MTH({}) = SHA-256(""). Πριν, σήκωνε
;; σφάλμα, δηλαδή ήταν ΜΗ ΣΥΜΜΟΡΦΟΣ με το πρότυπο.
;;
;; Η ΑΠΑΓΟΡΕΥΣΗ κενού corpus ΔΕΝ χάθηκε — ΜΕΤΑΚΙΝΗΘΗΚΕ εκεί που ανήκει: στην
;; ΠΟΛΙΤΙΚΗ δημοσίευσης (orchestrator.proof-carrying:write-provision-proofs ⇒
;; EMPTY-CORPUS-PUBLICATION), με ΔΙΚΟ ΤΗΣ ανεξάρτητο έλεγχο στο
;; tests/merkle-single-truth-test.lisp §Β. Δύο ιδιότητες, δύο έλεγχοι.
(ck "κενό δέντρο ⇒ MTH({}) = SHA-256(\"\")  (RFC 9162 §2.1.1)"
    (string= (merkle-tree-hash '())
             "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"))
(ck "η κανονική σταθερά +empty-tree-hash+ συμφωνεί με τον υπολογισμό"
    (string= (merkle-tree-hash '()) orchestrator.merkle:+empty-tree-hash+))
(ck "κενό δέντρο != οποιοδήποτε μονο-φυλλο δέντρο (καμία σύγχυση)"
    (not (string= (merkle-tree-hash '())
                  (merkle-tree-hash (list (hash-leaf-string ""))))))

(format t "~%========================================~%")
(format t "Merkle authority (RFC 6962) tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
