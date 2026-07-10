;;;; systems/orchestrator-epistemic/merkle-tree.lisp
;;;; Release-integrity Merkle tree — ADAPTER πάνω στη ΜΙΑ έδρα orchestrator.merkle
;;;; ============================================================================
;;;;
;;;; [P1.5-A] Το release root ΔΕΝ έχει πλέον δική του Merkle υλοποίηση. Η μία
;;;; έδρα (orchestrator.merkle, RFC 6962) ορίζει: domain-separated φύλλα (0x00) /
;;;; κόμβους (0x01) + unbalanced split (ΟΧΙ duplicate-last / CVE-2012-2459). Το
;;;; προηγούμενο τοπικό δέντρο ΔΕΝ είχε domain separation ΚΑΙ έκανε duplicate-last
;;;; — και τα δύο διορθώνονται εδώ ενώνοντας στην έδρα. Αλλάζει το release root
;;;; (⇒ νέα γενιά release ids, εκ κατασκευής καθαρή — φάση P1.5).
;;;;
;;;; Το «δέντρο» εδώ είναι απλώς (:filepaths … :leaves …): η διατεταγμένη λίστα
;;;; των canonical αρχείων + τα domain-separated leaf-hashes τους. Η ρίζα και τα
;;;; audit paths παράγονται από την έδρα.
;;;; ============================================================================

(in-package :orchestrator.epistemic)

(defun build-merkle-tree (filepaths)
  "Χτίσε το commitment αντικείμενο για μια ΔΙΑΤΕΤΑΓΜΕΝΗ λίστα canonical αρχείων.
   Επιστρέφει plist (:filepaths … :leaves …) όπου κάθε leaf = domain-separated
   RFC-6962 φύλλο των ωμών bytes του αρχείου (orchestrator.merkle:hash-leaf-file)."
  (unless filepaths
    (error "Cannot build Merkle tree from empty file list"))
  (list :filepaths (copy-list filepaths)
        :leaves (mapcar #'orchestrator.merkle:hash-leaf-file filepaths)))

(defun merkle-tree-root (tree)
  "Το release Merkle root (μορφή «sha256:<64-hex>») από το commitment αντικείμενο,
   μέσω της έδρας orchestrator.merkle (RFC 6962 MTH)."
  (orchestrator.merkle:merkle-tree-hash (getf tree :leaves)))

(defun generate-inclusion-proof (tree target-filepath)
  "RFC-6962 audit path για ένα αρχείο του commitment, ως λίστα από
   (:direction :left/:right :hash \"sha256:…\") — η φορητή μορφή που γράφεται στα
   temporal-proof/inclusion-proofs/. Σφάλμα αν το αρχείο δεν ανήκει στο δέντρο."
  (let* ((files (getf tree :filepaths))
         (leaves (getf tree :leaves))
         (index (position (namestring target-filepath) files
                          :key #'namestring :test #'string=)))
    (unless index
      (error "File not found in Merkle tree: ~A" target-filepath))
    (mapcar (lambda (step)
              (list :direction (car step) :hash (cdr step)))
            (orchestrator.merkle:inclusion-path leaves index))))

(defun generate-all-inclusion-proofs (tree filepaths)
  "Inclusion proofs για ΟΛΑ τα αρχεία, ως alist (filepath . proof)."
  (loop for filepath in filepaths
        collect (cons filepath (generate-inclusion-proof tree filepath))))

(defun verify-inclusion-proof (leaf-hash proof merkle-root)
  "Επαλήθευσε ένα inclusion proof (μορφή :direction/:hash) έναντι ρίζας, μέσω της
   έδρας orchestrator.merkle:verify-inclusion. T ανν ταιριάζει."
  (orchestrator.merkle:verify-inclusion
   leaf-hash
   (mapcar (lambda (step) (cons (getf step :direction) (getf step :hash))) proof)
   merkle-root))
