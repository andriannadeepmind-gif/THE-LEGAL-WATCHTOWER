;;;; source/legal-authority-receipt.lisp
;;;; ============================================================================
;;;; LEGAL AUTHORITY RECEIPT — [0088] Temporal/Identity Φ4 (σχέδιο §1.5)
;;;; ============================================================================
;;;;
;;;; Το φορητό τεκμήριο εξουσίας ΜΙΑΣ έκδοσης διάταξης: ταυτότητα, πηγή,
;;;; παραγωγή, χρόνοι (valid×transaction), ΠΛΗΡΗΣ τροποποιητική γενεαλογία
;;;; (όχι last-touch — PROV-01), content-hash, assurance, trust-status.
;;;;
;;;; ΤΟ ΚΛΕΙΔΙ (κλείσιμο PCL-01): receipt-id = canonical hash ΟΛΟΚΛΗΡΟΥ του
;;;; receipt — ταυτότητα/χρόνοι/γενεαλογία/πηγή ΜΕΣΑ στη δέσμευση, ποτέ
;;;; αδέσμευτα metadata δίπλα σε text-leaf. Όταν το receipt-set μπει στο
;;;; release root (Φ4β/Φ5), το Merkle φύλλο είναι το receipt-id — άρα η
;;;; αλλοίωση ΟΠΟΙΟΥΔΗΠΟΤΕ πεδίου σπάει την απόδειξη.
;;;;
;;;; trust-status: :signed | :unsigned-explicit — ΠΟΤΕ σιωπηλό (PCL-03)· η
;;;; υπογραφή του receipt-set root γίνεται στο release layer (owner κλειδιά)·
;;;; εδώ κάθε receipt γεννιέται ΡΗΤΑ :unsigned-explicit μέχρι το attest.

(defpackage :orchestrator.legal-receipt
  (:use :cl)
  (:export #:legal-authority-receipt #:receipt-p
           #:build-receipt #:build-receipts-for-graph
           #:verify-receipt #:receipt-alist
           #:lr-receipt-id #:lr-provision-id #:lr-valid-from #:lr-valid-until
           #:lr-recorded-from #:lr-content-hash #:lr-genealogy
           #:lr-assurance #:lr-trust-status #:lr-source-artifact))

(in-package :orchestrator.legal-receipt)

(defstruct (legal-authority-receipt (:conc-name lr-) (:predicate receipt-p))
  receipt-id            ; sha256 canonical ΟΛΟΚΛΗΡΟΥ του receipt (πλην του ίδιου)
  provision-id          ; canonical legal id (provision-id-string)
  expression            ; valid-from της έκδοσης (expression-level ταυτότητα)
  source-artifact       ; alist: source_digest/prov_content_sha256/channel — από τα prov stamps
  derivation            ; string: created-by της ΓΕΝΕΣΗΣ (bootstrap:<corpus> | edge-id)
  valid-from valid-until
  recorded-from recorded-until
  genealogy             ; ΠΛΗΡΗΣ λίστα created-by από genesis → παρούσα (όχι last-touch)
  content-hash          ; version-hash της έκδοσης
  previous-version-hash ; sha256 | "genesis"
  release-generation    ; alist (era seq) | :unreleased
  assurance
  trust-status)         ; :signed | :unsigned-explicit

(defun %vu (x) (if (eq x :open) "open" x))
(defun %ru (x) (if (eq x :current) "current" x))

(defun receipt-alist (r &key without-id)
  "Η κανονική (alist) μορφή του receipt — αυτή σειριοποιείται/hash-άρεται.
   WITHOUT-ID: η μορφή πάνω στην οποία υπολογίζεται το receipt-id."
  (append
   (unless without-id (list (cons "receipt_id" (lr-receipt-id r))))
   (list (cons "assurance" (string-downcase (symbol-name (lr-assurance r))))
         (cons "content_hash" (lr-content-hash r))
         (cons "derivation" (lr-derivation r))
         (cons "expression" (lr-expression r))
         (cons "genealogy" (lr-genealogy r))
         (cons "previous_version_hash" (lr-previous-version-hash r))
         (cons "provision_id" (lr-provision-id r))
         (cons "recorded_from" (lr-recorded-from r))
         (cons "recorded_until" (%ru (lr-recorded-until r)))
         (cons "release_generation" (if (eq :unreleased (lr-release-generation r))
                                        "unreleased" (lr-release-generation r)))
         (cons "source_artifact" (lr-source-artifact r))
         (cons "trust_status" (string-downcase (symbol-name (lr-trust-status r))))
         (cons "valid_from" (lr-valid-from r))
         (cons "valid_until" (%vu (lr-valid-until r))))))

(defun %genealogy-of (graph v)
  "ΠΛΗΡΗΣ αλυσίδα created-by από τη γένεση ως την έκδοση V — μέσω των
   previous-version-hash δεσμών του γράφου. Σπασμένος κρίκος ⇒ ΣΦΑΛΜΑ
   (incomplete reconstruction — ποτέ σιωπηλά κομμένη γενεαλογία)."
  (let ((chain '()) (cur v) (guard 0))
    (loop
      (when (> (incf guard) 10000)
        (error "γενεαλογία >10000 κρίκων — κύκλος στον γράφο;"))
      (push (orchestrator.version-graph:tv-created-by cur) chain)
      (let ((prev (orchestrator.version-graph:tv-previous-version-hash cur)))
        (when (eq prev :genesis) (return chain))
        (let ((pv (gethash prev (orchestrator.version-graph::vg-versions graph))))
          (unless pv
            (error "σπασμένη γενεαλογία: previous ~A ΔΕΝ υπάρχει στον γράφο" prev))
          (setf cur pv))))))

(defun build-receipt (graph version &key source-artifact)
  "Receipt για τη ΣΥΓΚΕΚΡΙΜΕΝΗ έκδοση, με γενεαλογία ΑΠΟ ΤΟΝ ΓΡΑΦΟ."
  (let* ((genealogy (%genealogy-of graph version))
         (r (make-legal-authority-receipt
             :receipt-id nil
             :provision-id (orchestrator.version-graph:tv-provision-id version)
             :expression (orchestrator.version-graph:tv-valid-from version)
             :source-artifact (or source-artifact
                                  (list (cons "declared" "missing-source-artifact")))
             :derivation (first genealogy)
             :valid-from (orchestrator.version-graph:tv-valid-from version)
             :valid-until (orchestrator.version-graph:tv-valid-until version)
             :recorded-from (orchestrator.version-graph:tv-recorded-from version)
             :recorded-until (orchestrator.version-graph:tv-recorded-until version)
             :genealogy genealogy
             :content-hash (orchestrator.version-graph:tv-version-hash version)
             :previous-version-hash
             (let ((p (orchestrator.version-graph:tv-previous-version-hash version)))
               (if (eq p :genesis) "genesis" p))
             :release-generation :unreleased
             :assurance (orchestrator.version-graph:tv-assurance version)
             :trust-status :unsigned-explicit)))
    (setf (lr-receipt-id r)
          (orchestrator.canonical-representation:canonical-hash
           (receipt-alist r :without-id t)))
    r))

(defun build-receipts-for-graph (graph &key source-artifact valid-at known-at)
  "Ένα receipt ανά διάταξη για την έκδοση που ισχύει στην τομή (VALID-AT,
   KNOWN-AT) — και τα δύο υποχρεωτικά (καμία σιωπηλή «τώρα» επιλογή).
   Επιστρέφει (values receipts uncertain) — τα αβέβαια ΟΝΟΜΑΣΤΙΚΑ."
  (let ((receipts '()) (uncertain '()))
    (maphash
     (lambda (pid records)
       (declare (ignore records))
       (handler-case
           (multiple-value-bind (v basis)
               (orchestrator.version-graph:version-at graph pid
                                                      :valid-at valid-at :known-at known-at)
             (declare (ignore basis))
             (when v (push (build-receipt graph v :source-artifact source-artifact)
                           receipts)))
         (orchestrator.version-graph:temporal-uncertainty (e)
           (push (cons pid (orchestrator.version-graph::uncertainty-why e)) uncertain))))
     (orchestrator.version-graph::vg-by-provision graph))
    (values (sort receipts #'string< :key #'lr-provision-id)
            (sort uncertain #'string< :key #'car))))

(defun verify-receipt (graph r)
  "ΠΛΗΡΗΣ επανέλεγχος: (1) receipt-id recompute, (2) η έκδοση υπάρχει στον
   γράφο και ΚΑΘΕ δεσμευμένο πεδίο ταυτίζεται, (3) γενεαλογία replay από τον
   γράφο κρίκο-προς-κρίκο (όχι count). (values T :ok) ή (values NIL λόγος) —
   αποτυχία ΟΠΟΥΔΗΠΟΤΕ ⇒ FAIL, ποτέ μερικό πράσινο."
  (block verify
    (flet ((fail (why) (return-from verify (values nil why))))
      ;; 1 — αυτο-συνέπεια δέσμευσης
      (unless (equal (lr-receipt-id r)
                     (orchestrator.canonical-representation:canonical-hash
                      (receipt-alist r :without-id t)))
        (fail :receipt-id-mismatch))
      ;; 2 — η έκδοση στον γράφο
      (let ((v (gethash (lr-content-hash r)
                        (orchestrator.version-graph::vg-versions graph))))
        (unless v (fail :version-not-in-graph))
        (unless (equal (lr-provision-id r)
                       (orchestrator.version-graph:tv-provision-id v))
          (fail :provision-id-mismatch))
        (unless (equal (lr-valid-from r)
                       (orchestrator.version-graph:tv-valid-from v))
          (fail :valid-from-mismatch))
        (unless (equal (lr-previous-version-hash r)
                       (let ((p (orchestrator.version-graph:tv-previous-version-hash v)))
                         (if (eq p :genesis) "genesis" p)))
          (fail :previous-mismatch))
        ;; 3 — γενεαλογία replay
        (handler-case
            (unless (equal (lr-genealogy r) (%genealogy-of graph v))
              (fail :genealogy-mismatch))
          (error () (fail :genealogy-broken)))
        (values t :ok)))))
