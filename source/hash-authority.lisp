;;;; source/hash-authority.lisp
;;;; GATE-3: HASH AUTHORITY UNIFICATION

(defpackage #:orchestrator.hash-authority
  (:use :cl)
  (:export #:compute-hash
           #:compute-hash-prefixed))

(in-package :orchestrator.hash-authority)

(defun compute-hash (content &key algorithm)
  "Compute cryptographic hash with mandatory algorithm.

   Arguments:
     content: String or byte-vector to hash
     algorithm: REQUIRED - :sha256, :sha512, :blake2, or :blake3

   Fail-fast guarantees:
     - Errors if ALGORITHM not provided (prevents accidental omission)
     - Errors if algorithm not in allowed set

   [audit#13] ΑΚΡΙΒΗΣ ΕΜΒΕΛΕΙΑ (τίμια, όχι «η ONLY hash»): αυτή είναι η έδρα του
   ΓΕΝΙΚΟΥ content-addressing hash (αυθαίρετο περιεχόμενο → hex, ρητό algorithm).
   ΔΕΝ είναι η μόνη hash του συστήματος: υπάρχουν ΔΗΛΩΜΕΝΕΣ protocol-local hashes με
   ΔΙΑΦΟΡΕΤΙΚΟ συμβόλαιο που ΔΕΝ μπορούν/πρέπει να περάσουν από εδώ — JWS/RS256 (RFC 7515),
   X.509 SPKI, RFC-3161 TSA, RFC-6962 Merkle (domain-separated), keccak/256 (Ethereum),
   digest-file ακεραιότητας. Το πλήρες, ΑΠΟΚΛΕΙΣΤΙΚΟ μητρώο κάθε hash-έδρας ζει στο
   deployment/verify/hash-seat-registry.sexp και επιβάλλεται μηχανικά (καμία ΚΡΥΦΗ hash
   έδρα): tests/hash-seat-registry-test.lisp. «Μία έδρα ανά ΕΝΝΟΙΑ» — η έννοια εδώ είναι
   το γενικό content hash, όχι κάθε πρωτόκολλο.

   Returns:
     Hex string (lowercase, without algorithm prefix)"

  (unless algorithm
    (error "ALGORITHM parameter is required. Use :algorithm :sha256/:sha512/:blake2/:blake3"))

  (unless (member algorithm '(:sha256 :sha512 :blake2 :blake3))
    (error "ALGORITHM must be :sha256, :sha512, :blake2, or :blake3, got: ~A" algorithm))

  (let ((bytes (etypecase content
                 (string (babel:string-to-octets content))
                 ((simple-array (unsigned-byte 8) (*)) content)
                 (vector content))))
    (ironclad:byte-array-to-hex-string
     (ironclad:digest-sequence algorithm bytes))))

(defun compute-hash-prefixed (content &key algorithm)
  "Compute cryptographic hash with algorithm prefix.

   Arguments:
     content: String content to hash
     algorithm: REQUIRED - :sha256, :sha512, :blake2, or :blake3

   Returns:
     Prefixed hex string (e.g., 'blake3:abcd1234...')"

  (let ((hex (compute-hash content :algorithm algorithm)))
    (format nil "~(~A~):~A" algorithm hex)))

;;; [P1.5-A] Το νεκρό tombstone export `merkle-root` (0 καλούντες, εγειρε πάντα
;;; σφάλμα) ΔΙΑΓΡΑΦΗΚΕ. Η ΜΙΑ Merkle έδρα είναι orchestrator.merkle (RFC 6962).
