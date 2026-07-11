;;;; source/merkle-authority.lisp
;;;; ============================================================================
;;;; MERKLE (RFC 6962) — Η ΜΙΑ ΕΔΡΑ ΔΕΝΤΡΩΝ MERKLE ΤΟΥ ΙΔΡΥΜΑΤΟΣ
;;;; ============================================================================
;;;;
;;;; Κάθε δέντρο Merkle του συστήματος υπακούει σε ΕΝΑ κανόνα (RFC 6962 §2.1):
;;;;   - leaf = SHA-256( 0x00 ‖ bytes )         — domain separation
;;;;   - node = SHA-256( 0x01 ‖ raw(L) ‖ raw(R) ) — domain separation
;;;;   - περιττός αριθμός φύλλων: RFC-6962 **unbalanced split** (διάσπαση στη
;;;;     μεγαλύτερη δύναμη του 2 < n), ΟΧΙ duplicate-last.
;;;;
;;;; Γιατί ΟΧΙ duplicate-last: η κλάση CVE-2012-2459 — με αντιγραφή του
;;;; τελευταίου φύλλου, δύο ΔΙΑΦΟΡΕΤΙΚΑ σύνολα φύλλων παράγουν ΙΔΙΑ ρίζα
;;;; (π.χ. [a b c] και [a b c c]). Απαράδεκτο όταν εκδίδουμε inclusion proofs
;;;; σε τρίτους. Το unbalanced split το κάνει ΔΟΜΙΚΑ αδύνατο.
;;;;
;;;; Γιατί domain separation: χωρίς το 0x00/0x01, ένα 64-byte φύλλο είναι
;;;; second-preimage ενός εσωτερικού κόμβου (left‖right) — ο επιτιθέμενος περνά
;;;; εσωτερικό κόμβο ως φύλλο. Το prefix το σφραγίζει.
;;;;
;;;; ΝΟΜΟΣ: μία έδρα ανά έννοια. Δεύτερο Merkle δέντρο ΔΕΝ γράφεται πουθενά —
;;;; επεκτείνεται ΑΥΤΟ. Είναι ο σκελετός που ελέγχει ο L6 kernel (P5).
;;;; ============================================================================

(defpackage :orchestrator.merkle
  (:use :cl)
  (:export
   ;; Domain-separated πρωτόγονα
   #:hash-leaf-bytes
   #:hash-leaf-string
   #:hash-leaf-file
   #:hash-node
   ;; Δέντρο (RFC 6962 MTH + audit path)
   #:merkle-tree-hash              ; ρίζα από ΛΙΣΤΑ leaf-hashes
   #:merkle-root-of-strings
   #:merkle-root-of-files
   #:inclusion-path               ; audit path για δείκτη
   #:verify-inclusion             ; επανυπολογισμός ρίζας από φύλλο+path
   ;; RFC 6962 §2.1.2 / RFC 9162 §2.1.4.2 — consistency proofs (L7-B)
   #:consistency-proof            ; PROOF(m, D[n]) από τα φύλλα
   #:verify-consistency           ; έλεγχος old-root⊑new-root ΧΩΡΙΣ τα φύλλα
   ;; Σταθερές (audit)
   #:+leaf-prefix+
   #:+node-prefix+))

(in-package :orchestrator.merkle)

;;; ============================================================================
;;; DOMAIN-SEPARATED HASHING
;;; ============================================================================

(defparameter +leaf-prefix+ #(#x00) "RFC 6962 §2.1: πρόθεμα φύλλου.")
(defparameter +node-prefix+ #(#x01) "RFC 6962 §2.1: πρόθεμα εσωτερικού κόμβου.")

(declaim (inline %sha256-hex))
(defun %sha256-hex (bytes)
  "sha256:HEX (μικρά) των BYTES — η ενιαία μορφή αναπαράστασης hash."
  (format nil "sha256:~(~{~2,'0x~}~)"
          (coerce (ironclad:digest-sequence :sha256 bytes) 'list)))

(defun hash-leaf-bytes (bytes)
  "Domain-separated φύλλο από ωμά bytes: sha256:HEX του 0x00 ‖ BYTES."
  (%sha256-hex (concatenate '(vector (unsigned-byte 8)) +leaf-prefix+ bytes)))

(defun hash-leaf-string (string)
  "Domain-separated φύλλο από string (UTF-8): sha256:HEX του 0x00 ‖ UTF8(STRING)."
  (hash-leaf-bytes (babel:string-to-octets (or string "") :encoding :utf-8)))

(defun hash-leaf-file (filepath)
  "Domain-separated φύλλο από τα ΩΜΑ bytes ενός αρχείου: sha256:HEX του
   0x00 ‖ file-bytes (ντετερμινιστικό, χωρίς μετακωδικοποίηση)."
  (hash-leaf-bytes (alexandria:read-file-into-byte-vector filepath)))

(defun hash-node (left-hash right-hash)
  "Εσωτερικός κόμβος: sha256:HEX του 0x01 ‖ raw(LEFT) ‖ raw(RIGHT). Δέχεται
   'sha256:HEX' και συνενώνει τα ΩΜΑ bytes (όχι το ASCII του hex). Order-sensitive."
  (let ((bl (ironclad:hex-string-to-byte-array (subseq left-hash 7)))
        (br (ironclad:hex-string-to-byte-array (subseq right-hash 7))))
    (%sha256-hex (concatenate '(vector (unsigned-byte 8)) +node-prefix+ bl br))))

;;; ============================================================================
;;; RFC 6962 §2.1 — MERKLE TREE HASH (unbalanced split, ΟΧΙ duplicate-last)
;;; ============================================================================

(defun %largest-power-of-two-below (n)
  "Η μεγαλύτερη δύναμη του 2 ΓΝΗΣΙΩΣ μικρότερη του N (N ≥ 2). RFC 6962: k < n ≤ 2k."
  (let ((k 1))
    (loop while (< (* k 2) n) do (setf k (* k 2)))
    k))

(defun merkle-tree-hash (leaf-hashes)
  "RFC 6962 Merkle Tree Hash πάνω σε ΔΙΑΤΕΤΑΓΜΕΝΗ λίστα ΗΔΗ-υπολογισμένων
   leaf-hashes:
     n=1 ⇒ το ίδιο το φύλλο (κανένα re-hash)·
     n>1 ⇒ k = μεγαλύτερη δύναμη του 2 < n·
           hash-node( MTH(leaves[0:k]), MTH(leaves[k:n]) ).
   Σφάλμα σε κενή λίστα (το κενό δέντρο δεν έχει νόημα ως commitment εδώ)."
  (let ((v (coerce leaf-hashes 'vector)))
    (labels ((mth (lo hi)                      ; [lo, hi)
               (let ((n (- hi lo)))
                 (cond
                   ((<= n 0) (error "merkle-tree-hash: κενό εύρος φύλλων"))
                   ((= n 1) (aref v lo))
                   (t (let ((k (%largest-power-of-two-below n)))
                        (hash-node (mth lo (+ lo k)) (mth (+ lo k) hi))))))))
      (when (zerop (length v))
        (error "merkle-tree-hash: κενή λίστα φύλλων"))
      (mth 0 (length v)))))

(defun merkle-root-of-strings (strings)
  "Ρίζα RFC-6962 πάνω σε λίστα strings (κάθε ένα ⇒ domain-separated φύλλο)."
  (merkle-tree-hash (mapcar #'hash-leaf-string strings)))

(defun merkle-root-of-files (filepaths)
  "Ρίζα RFC-6962 πάνω σε λίστα αρχείων (κάθε ένα ⇒ domain-separated φύλλο των
   ωμών bytes του). Η σειρά των FILEPATHS ΕΙΝΑΙ μέρος του commitment."
  (merkle-tree-hash (mapcar #'hash-leaf-file filepaths)))

;;; ============================================================================
;;; RFC 6962 §2.1.1 — AUDIT / INCLUSION PATH
;;; ============================================================================

(defun inclusion-path (leaf-hashes index)
  "RFC 6962 audit path για το φύλλο στο INDEX: λίστα (SIDE . SIBLING-HASH) σε
   σειρά φύλλο→ρίζα, όπου SIDE = :right αν το αδερφάκι είναι δεξιά του τρέχοντος
   (το φύλλο ήταν στο αριστερό μισό), :left αν αριστερά. Επανυπολογίζεται από
   verify-inclusion. Ίδια διάσπαση (unbalanced) με το merkle-tree-hash."
  (let ((v (coerce leaf-hashes 'vector)))
    (unless (< -1 index (length v))
      (error "inclusion-path: δείκτης ~D εκτός [0,~D)" index (length v)))
    (labels ((mth (lo hi)
               (let ((n (- hi lo)))
                 (if (= n 1) (aref v lo)
                     (let ((k (%largest-power-of-two-below n)))
                       (hash-node (mth lo (+ lo k)) (mth (+ lo k) hi))))))
             (path (lo hi m)                    ; m = απόλυτος δείκτης στο [lo,hi)
               (let ((cnt (- hi lo)))
                 (if (= cnt 1)
                     '()
                     (let* ((k (%largest-power-of-two-below cnt))
                            (mid (+ lo k)))
                       (if (< m mid)
                           ;; m στο αριστερό μισό ⇒ αδερφάκι = δεξί μισό (δεξιά)
                           (append (path lo mid m)
                                   (list (cons :right (mth mid hi))))
                           ;; m στο δεξί μισό ⇒ αδερφάκι = αριστερό μισό (αριστερά)
                           (append (path mid hi m)
                                   (list (cons :left (mth lo mid))))))))))
      (path 0 (length v) index))))

;;; ============================================================================
;;; RFC 6962 §2.1.2 — CONSISTENCY PROOF (L7-B: append-only απόδειξη)
;;; ============================================================================
;;; PROOF(m, D[n]) αποδεικνύει ότι το δέντρο μεγέθους n είναι ΕΠΕΚΤΑΣΗ του
;;; δέντρου μεγέθους m (ίδια πρώτα m φύλλα) — ο verifier κρατά ΜΟΝΟ τις δύο
;;; ρίζες, ποτέ τα φύλλα. Αυτό είναι το θεμέλιο του transparency log:
;;; ιστορία που ΔΕΝ ξαναγράφεται γίνεται μαθηματικά ελέγξιμη ιδιότητα.

(defun consistency-proof (leaf-hashes m)
  "RFC 6962 §2.1.2: PROOF(M, D[n]) — λίστα κόμβων ώστε ένας verifier με μόνο
   MTH(D[0:M]) και MTH(D[n]) να επαληθεύσει ότι το n-δέντρο επεκτείνει το M-δέντρο.
   Απαιτεί 1 ≤ M ≤ n. Για M = n επιστρέφει '() (ταυτότητα)."
  (let* ((v (coerce leaf-hashes 'vector))
         (n (length v)))
    (unless (<= 1 m n)
      (error "consistency-proof: απαιτείται 1 ≤ m(~D) ≤ n(~D)" m n))
    (labels ((mth (lo hi)
               (if (= (- hi lo) 1) (aref v lo)
                   (let ((k (%largest-power-of-two-below (- hi lo))))
                     (hash-node (mth lo (+ lo k)) (mth (+ lo k) hi)))))
             (subproof (m lo hi complete-p) ; SUBPROOF(m, D[lo:hi], b)
               (let ((n (- hi lo)))
                 (cond
                   ((and (= m n) complete-p) '())
                   ((= m n) (list (mth lo hi)))
                   (t (let ((k (%largest-power-of-two-below n)))
                        (if (<= m k)
                            (append (subproof m lo (+ lo k) complete-p)
                                    (list (mth (+ lo k) hi)))
                            (append (subproof (- m k) (+ lo k) hi nil)
                                    (list (mth lo (+ lo k)))))))))))
      (if (= m n) '() (subproof m 0 n t)))))

(defun verify-consistency (m n old-root new-root proof)
  "RFC 9162 §2.1.4.2: T ανν το PROOF αποδεικνύει MTH_m = OLD-ROOT ⊑ MTH_n =
   NEW-ROOT (το n-δέντρο επεκτείνει το m-δέντρο). Καθαρά μαθηματικά — ο
   verifier δεν βλέπει κανένα φύλλο. NIL σε ΚΑΘΕ απόκλιση (fail-closed)."
  (cond
    ((or (< m 1) (> m n)) nil)
    ((= m n) (and (null proof) (string= old-root new-root)))
    (t
     ;; Αν m = ακριβής δύναμη του 2, η old-root ΕΙΝΑΙ ο πρώτος κόμβος του path.
     (let ((path (if (zerop (logand m (1- m))) (cons old-root proof) proof)))
       (when path
         (let ((fn (1- m)) (sn (1- n)))
           (loop while (oddp fn) do (setf fn (ash fn -1) sn (ash sn -1)))
           (let ((fr (first path)) (sr (first path)) (ok t))
             (dolist (c (rest path))
               (when (zerop sn) (setf ok nil) (return))
               (cond ((or (oddp fn) (= fn sn))
                      (setf fr (hash-node c fr)
                            sr (hash-node c sr))
                      (loop while (and (not (zerop fn)) (evenp fn))
                            do (setf fn (ash fn -1) sn (ash sn -1))))
                     (t (setf sr (hash-node sr c))))
               (setf fn (ash fn -1) sn (ash sn -1)))
             (and ok
                  (zerop sn)
                  (string= fr old-root)
                  (string= sr new-root)))))))))

(defun verify-inclusion (leaf-hash path root)
  "Επανυπολόγισε τη ρίζα από LEAF-HASH + PATH (φύλλο→ρίζα) και σύγκρινε με ROOT.
   T ανν ταιριάζει. ΔΕΝ εμπιστεύεται τίποτα εκτός από τα μαθηματικά."
  (let ((cur leaf-hash))
    (dolist (step path (string= cur root))
      (destructuring-bind (side . sib) step
        (setf cur (ecase side
                    (:left  (hash-node sib cur))
                    (:right (hash-node cur sib))))))))
