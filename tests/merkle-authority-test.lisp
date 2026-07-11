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

(format t "~%== Edge: empty ⇒ error ==~%")
(ck "κενή λίστα φύλλων ⇒ σφάλμα"
    (handler-case (progn (merkle-tree-hash '()) nil) (error () t)))

(format t "~%========================================~%")
(format t "Merkle authority (RFC 6962) tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
