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
           #:verify-receipt #:verify-receipt-intrinsic #:receipt-alist
           #:lr-receipt-id #:lr-provision-id #:lr-effectivity #:lr-cut-graph-root #:lr-cut-journal-seq #:lr-cut-known-at #:lr-commencement #:lr-valid-until
           #:lr-recorded-from #:lr-content-hash #:lr-genealogy
           #:lr-assurance #:lr-trust-status #:lr-source-artifact))

(in-package :orchestrator.legal-receipt)

(defstruct (legal-authority-receipt (:conc-name lr-) (:predicate receipt-p))
  receipt-id            ; sha256 canonical ΟΛΟΚΛΗΡΟΥ του receipt (πλην του ίδιου)
  provision-id          ; canonical legal id (provision-id-string)
  commencement          ; [REVIEW Α] το sum type ΑΥΤΟΥΣΙΟ (:fixed d)|(:conditional cid)
                        ; — ΚΑΜΙΑ condition-ταυτότητα μεταμφιεσμένη σε ημερομηνία
  source-artifact       ; alist: source_digest/prov_content_sha256/channel — από τα prov stamps
  derivation            ; string: created-by της ΓΕΝΕΣΗΣ (bootstrap:<corpus> | edge-id)
  valid-until
  recorded-from recorded-until
  genealogy             ; ΠΛΗΡΗΣ λίστα created-by από genesis → παρούσα (όχι last-touch)
  content-hash          ; version-hash της έκδοσης
  previous-version-hash ; sha256 | "genesis"
  release-generation    ; alist (era seq) | :unreleased
  assurance
  trust-status          ; :signed | :unsigned-explicit
  cut-graph-root        ; [REVIEW Ε] chain-head ΤΟΥ cut δέσμευσης
  cut-journal-seq       ; [Ε] ΑΚΡΙΒΗΣ αριθμός journal γραμμών του cut —
                        ; καμία 1s timestamp ταυτότητα: ίδιο δευτερόλεπτο,
                        ; διαφορετικό state ⇒ ΔΙΑΦΟΡΕΤΙΚΟ cut
  cut-known-at          ; [Ε] το known-at ΤΟΥ ερωτήματος — το effectivity
                        ; περιορίζεται σε ό,τι ήταν γνωστό ΤΟΤΕ (όχι build-time)
  effectivity)          ; [Φ7 Π5] alist condition_id/condition_class/regime_edge_ids
                        ; — query-ΑΝΕΞΑΡΤΗΤΑ intrinsic πεδία (spec §6)· NIL όταν
                        ; η έκδοση δεν φέρει αιρέσεις/καθεστώτα ⇒ ΤΑΥΤΟΣΗΜΟ
                        ; receipt-id με το προ-Π5 σχήμα (roots αμετάβλητα)

(defun %vu (x) (if (eq x :open) "open" x))
(defun %ru (x) (if (eq x :current) "current" x))

(defun receipt-alist (r &key without-id)
  "Η κανονική (alist) μορφή του receipt — αυτή σειριοποιείται/hash-άρεται.
   WITHOUT-ID: η μορφή πάνω στην οποία υπολογίζεται το receipt-id."
  (append
   (unless without-id (list (cons "receipt_id" (lr-receipt-id r))))
   ;; [Π5] το effectivity μπαίνει ΜΟΝΟ όταν υπάρχει — receipts χωρίς
   ;; αιρέσεις/καθεστώτα διατηρούν byte-ίδια κανονική μορφή (ids σταθερά)
   (when (lr-effectivity r) (list (cons "effectivity" (lr-effectivity r))))
   (list (cons "assurance" (string-downcase (symbol-name (lr-assurance r))))
         ;; [Ε] το ΑΚΡΙΒΕΣ cut ΔΕΣΜΕΥΕΤΑΙ πάντα (schema receipt/3)· το
         ;; release_root δένει δομικά ένα επίπεδο πάνω: receipt-id ∈
         ;; receipt_set_root ∈ census ∈ ΥΠΟΓΕΓΡΑΜΜΕΝΟ release root.
         (cons "cut" (list (cons "graph_root" (lr-cut-graph-root r))
                           (cons "journal_seq" (lr-cut-journal-seq r))
                           (cons "known_at" (lr-cut-known-at r))))
         (cons "content_hash" (lr-content-hash r))
         (cons "derivation" (lr-derivation r))
         ;; [Α] δομημένο commencement στο canonical contract (receipt/2)
         (cons "commencement"
               (let ((c (lr-commencement r)))
                 (list (cons "type" (string-downcase (symbol-name (first c))))
                       (cons "value" (second c)))))
         (cons "genealogy" (lr-genealogy r))
         (cons "previous_version_hash" (lr-previous-version-hash r))
         (cons "provision_id" (lr-provision-id r))
         (cons "recorded_from" (lr-recorded-from r))
         (cons "recorded_until" (%ru (lr-recorded-until r)))
         (cons "release_generation" (if (eq :unreleased (lr-release-generation r))
                                        "unreleased" (lr-release-generation r)))
         (cons "source_artifact" (lr-source-artifact r))
         (cons "trust_status" (string-downcase (symbol-name (lr-trust-status r))))
         (cons "receipt_schema" "lawmax/receipt/3")
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

(defun %effectivity-of (graph version as-of)
  "[Φ7 Π5 + HARDENING #7] Τα query-ΑΝΕΞΑΡΤΗΤΑ effectivity πεδία της έκδοσης
   ΟΠΩΣ ΗΤΑΝ ΓΝΩΣΤΑ κατά AS-OF (legal-instant): condition-id + class + τα
   live-κατά-AS-OF regime edge-ids που τη στοχεύουν — ταξινομημένα,
   ντετερμινιστικά. NIL όταν τίποτα. Το AS-OF κάνει το receipt αμετάβλητο
   απέναντι σε ΜΕΤΑΓΕΝΕΣΤΕΡΑ events (release-scoped verification)."
  (let* ((cid (orchestrator.version-graph::%tv-conditional-cid version))
         (cnd (and cid (orchestrator.version-graph:graph-condition graph cid)))
         (redges (sort (loop for re in (orchestrator.version-graph:graph-regimes graph)
                             when (and (orchestrator.version-graph::%live-at-p
                                        (orchestrator.version-graph:re-recorded-from re)
                                        (orchestrator.version-graph:re-recorded-until re)
                                        as-of)
                                       ;; version-στοχευμένα rewrites δένουν ΜΟΝΟ
                                       ;; στη δική τους έκδοση· pid-επίπεδα
                                       ;; (suspend/revive) σε ΟΛΕΣ του pid
                                       (if (orchestrator.version-graph:re-version re)
                                           (equal (orchestrator.version-graph:re-version re)
                                                  (orchestrator.version-graph:tv-version-hash version))
                                           (equal (orchestrator.version-graph:re-target re)
                                                  (orchestrator.version-graph:tv-provision-id version))))
                               collect (orchestrator.version-graph:re-edge-id re))
                       #'string<)))
    (when (or cid redges)
      (append
       (when cid
         (list (cons "condition_class"
                     (string-downcase (symbol-name (orchestrator.version-graph:condition-class cnd))))
               (cons "condition_id" cid)))
       (when redges (list (cons "regime_edge_ids" redges)))))))

(defun %current-record-of (graph version)
  "[PRE-#4 FREEZE #4] Το ΤΡΕΧΟΝ bitemporal record του content-hash της VERSION
   (recorded-until :current) στον γράφο — το receipt περιγράφει ΠΑΝΤΑ την
   τρέχουσα γνώση (όπως το version-at στην παραγωγή), ΟΧΙ superseded snapshot.
   Η διτεμπορική supersession διχάζει ένα content-hash σε πολλά records· ΕΝΑ
   είναι :current. Αν το δοθέν object είναι ήδη :current, επιστρέφεται ως έχει."
  (if (eq :current (orchestrator.version-graph:tv-recorded-until version))
      version
      (or (find-if (lambda (rec)
                     (and (equal (orchestrator.version-graph:tv-version-hash rec)
                                 (orchestrator.version-graph:tv-version-hash version))
                          (eq :current (orchestrator.version-graph:tv-recorded-until rec))))
                   (gethash (orchestrator.version-graph:tv-provision-id version)
                            (orchestrator.version-graph::vg-by-provision graph)))
          version)))

(defun build-receipt (graph version-in &key source-artifact
                                         (known-at (error "build-receipt: known-at ΥΠΟΧΡΕΩΤΙΚΟ — το receipt δεσμεύει το epistemic cut του ερωτήματος")))
  "Receipt για την έκδοση, με γενεαλογία ΑΠΟ ΤΟΝ ΓΡΑΦΟ. [Ε] Δεσμεύει ΑΚΡΙΒΕΣ
   cut {graph_root, journal_seq, known_at}. [#4] Περιγράφει το ΤΡΕΧΟΝ
   bitemporal record (τρέχουσα γνώση), όχι superseded snapshot."
  (let* ((version (%current-record-of graph version-in))
         (genealogy (%genealogy-of graph version))
         (r (make-legal-authority-receipt
             :receipt-id nil
             :provision-id (orchestrator.version-graph:tv-provision-id version)
             :commencement (orchestrator.version-graph:tv-commencement version)
             :source-artifact (or source-artifact
                                  (list (cons "declared" "missing-source-artifact")))
             :derivation (first genealogy)
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
             :trust-status :unsigned-explicit
             :cut-graph-root (orchestrator.version-graph:graph-chain-head graph)
             :cut-journal-seq (orchestrator.version-graph:graph-seq graph)
             :cut-known-at known-at
             :effectivity (%effectivity-of graph version known-at))))
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
             (when v (push (build-receipt graph v :source-artifact source-artifact
                                                  :known-at known-at)
                           receipts)))
         (orchestrator.version-graph:temporal-uncertainty (e)
           (push (cons pid (orchestrator.version-graph::uncertainty-why e)) uncertain))))
     (orchestrator.version-graph::vg-by-provision graph))
    (values (sort receipts #'string< :key #'lr-provision-id)
            (sort uncertain #'string< :key #'car))))

(defun %vu-eq (a b) (equal a b))
(defun %ru-eq (a b) (equal a b))

(defun verify-receipt-intrinsic (graph r)
  "[PRE-#4 FREEZE #4/#5] INTRINSIC receipt verification — self-hash + ΑΚΡΙΒΕΣ
   cut + ΟΛΑ ΤΑ GRAPH-DERIVED ΠΕΔΙΑ επί του cut-version:
     (1) receipt-id = canonical-hash ΟΛΟΚΛΗΡΟΥ του receipt (πλην id)·
     (2) cut {graph_root, journal_seq, known_at} typed· prefix replay ως το
         seq + prefix chain-head ≡ δεσμευμένο graph_root (same-second/
         μεταγενέστερα events ΑΟΡΑΤΑ — δομική εγγύηση, όχι χρονική)·
     (3) ΚΑΘΕ graph-derived πεδίο ≡ CUT-VERSION: provision-id, commencement,
         previous, valid-until, recorded-from, recorded-until, derivation,
         assurance, genealogy (replay), effectivity(cut, known-at).
   ΔΕΝ αποδεικνύει (ανήκουν στο verify-authority-proof-bundle, #4):
   source bytes, receipt membership σε signed receipt-set, census/release
   signature, TSA, tlog inclusion, TRA. Ονομαστικά ΞΕΧΩΡΙΣΤΟ ώστε ΚΑΝΕΝΑΣ
   να μη νομίσει ότι εδώ αποδεικνύεται εκδοτική αυθεντία.
   (values T :ok) ή (values NIL λόγος) — αποτυχία ΟΠΟΥΔΗΠΟΤΕ ⇒ FAIL."
  (block verify
    (flet ((fail (why) (return-from verify (values nil why))))
      ;; 1 — αυτο-συνέπεια δέσμευσης
      (unless (equal (lr-receipt-id r)
                     (orchestrator.canonical-representation:canonical-hash
                      (receipt-alist r :without-id t)))
        (fail :receipt-id-mismatch))
      ;; 2 — ΑΚΡΙΒΕΣ cut (prefix replay)
      (unless (and (stringp (lr-cut-graph-root r))
                   (integerp (lr-cut-journal-seq r))
                   (orchestrator.version-graph:legal-instant-p (lr-cut-known-at r)))
        (fail :cut-missing))
      (let ((cut-graph
              (if (and (equal (lr-cut-graph-root r)
                              (orchestrator.version-graph:graph-chain-head graph))
                       (= (lr-cut-journal-seq r)
                          (orchestrator.version-graph:graph-seq graph)))
                  graph
                  (let ((pg (orchestrator.version-graph:load-graph
                             (orchestrator.version-graph:graph-body graph)
                             :up-to-seq (lr-cut-journal-seq r))))
                    (unless (equal (lr-cut-graph-root r)
                                   (orchestrator.version-graph:graph-chain-head pg))
                      (fail :cut-not-in-journal-history))
                    pg))))
        ;; 3 — ΟΛΑ τα graph-derived πεδία ΕΠΙ ΤΟΥ ΑΚΡΙΒΟΥΣ bitemporal record.
        ;; [PRE-#4 FREEZE #4] Το content-hash ΔΕΝ αρκεί: η διτεμπορική
        ;; supersession διχάζει τον ίδιο content-hash σε ΠΟΛΛΑ records (το
        ;; παλιό με recorded-until=timestamp + το fork copy με :current). Το
        ;; receipt δεσμεύεται στο record ΤΟΥ ΟΠΟΙΟΥ η recorded-from (αμετάβλητη
        ;; ταυτότητα γέννησης) ταιριάζει — αλλιώς επαληθεύεται λάθος record.
        (let ((cv (find-if (lambda (rec)
                             (and (equal (orchestrator.version-graph:tv-version-hash rec)
                                         (lr-content-hash r))
                                  (equal (orchestrator.version-graph:tv-recorded-from rec)
                                         (lr-recorded-from r))))
                           (gethash (lr-provision-id r)
                                    (orchestrator.version-graph::vg-by-provision cut-graph)))))
          (unless cv (fail :version-not-in-cut))
          (unless (equal (lr-provision-id r)
                         (orchestrator.version-graph:tv-provision-id cv))
            (fail :provision-id-mismatch))
          (unless (equal (lr-commencement r)
                         (orchestrator.version-graph:tv-commencement cv))
            (fail :commencement-mismatch))
          (unless (equal (lr-previous-version-hash r)
                         (let ((p (orchestrator.version-graph:tv-previous-version-hash cv)))
                           (if (eq p :genesis) "genesis" p)))
            (fail :previous-mismatch))
          (unless (%vu-eq (lr-valid-until r)
                          (orchestrator.version-graph:tv-valid-until cv))
            (fail :valid-until-mismatch))
          (unless (equal (lr-recorded-from r)
                         (orchestrator.version-graph:tv-recorded-from cv))
            (fail :recorded-from-mismatch))
          (unless (%ru-eq (lr-recorded-until r)
                          (orchestrator.version-graph:tv-recorded-until cv))
            (fail :recorded-until-mismatch))
          (unless (equal (lr-assurance r)
                         (orchestrator.version-graph:tv-assurance cv))
            (fail :assurance-mismatch))
          (handler-case
              (let ((gen (%genealogy-of cut-graph cv)))
                (unless (equal (lr-genealogy r) gen)
                  (fail :genealogy-mismatch))
                (unless (equal (lr-derivation r) (first gen))
                  (fail :derivation-mismatch)))
            (error () (fail :genealogy-broken)))
          (unless (equal (lr-effectivity r)
                         (%effectivity-of cut-graph cv (lr-cut-known-at r)))
            (fail :effectivity-mismatch))))
      (values t :ok))))

(defun verify-receipt (graph r)
  "ΣΥΝΤΑΞΙΟΔΟΤΗΜΕΝΟ ΟΝΟΜΑ — δείχνει στο verify-receipt-intrinsic. Η ΠΛΗΡΗΣ
   εκδοτική αυθεντία (source bytes/membership/release signature) ανήκει στο
   ΜΕΛΛΟΝΤΙΚΟ verify-authority-proof-bundle (#4)."
  (verify-receipt-intrinsic graph r))
