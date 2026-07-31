;;;; authority-v2/genesis/genesis-policy.sexp
;;;; ============================================================================
;;;; LEVEL-7 VCCT-RSM — GENESIS POLICY (sequence 0)
;;;; ============================================================================
;;;; Η ΠΟΛΙΤΙΚΗ υπό την οποία γεννιέται η νέα authority epoch. Το hash ΑΥΤΟΥ του
;;;; αρχείου δεσμεύεται μέσα στο LEGACY-ADOPTION-CERTIFICATE (πεδίο
;;;; genesis_policy_hash) — η γένεση δεν είναι «ό,τι έτυχε», είναι δηλωμένη
;;;; πολιτική με ταυτότητα.
;;;;
;;;; ΚΡΙΣΙΜΟ: adoption-mode = evidence-only. Η παλιά ιστορία ΔΕΣΜΕΥΕΤΑΙ (ώστε
;;;; καμία αναδρομική επανεγγραφή της να μην περνά απαρατήρητη) αλλά ΔΕΝ
;;;; υιοθετείται: κανένα legacy release δεν γίνεται accepted state, καμία
;;;; authority/attestation/conformance δεν κληρονομείται. Το πρώτο release που
;;;; αποκτά ΝΕΑ authority είναι το sequence 1 και περνά ΟΛΟΚΛΗΡΟ τον admission
;;;; kernel.
;;;;
;;;; Data-only. assurance_status = under-construction.

(:lawmax-genesis-policy/1

 :epoch-id "lawmax-authority-epoch-2"
 :predecessor-epoch "legacy (pre-VCCT-RSM, evidence-only)"

 ;; ── ΤΡΟΠΟΣ ΥΙΟΘΕΣΙΑΣ ──
 :adoption-mode :evidence-only
 :inherited-authority nil
 :inherited-attestation nil
 :inherited-conformance nil

 ;; ── ΤΙ ΓΙΝΕΤΑΙ ΜΕ ΤΑ ΠΑΛΙΑ ΔΕΔΟΜΕΝΑ ──
 ;; ΔΕΝ διαγράφονται, ΔΕΝ μετακινούνται, ΔΕΝ ξαναγράφονται. Παραμένουν
 ;; read-only στο legacy namespace. Η αναστρεψιμότητα είναι απαίτηση:
 ;; η γένεση ΠΡΟΣΘΕΤΕΙ δέσμευση, δεν καταστρέφει ιστορία.
 :legacy-disposition :read-only-preserved
 :legacy-namespace-roots ("output" "releases" "output_run1")
 :destructive-operations-allowed nil

 ;; ── Η ΠΡΩΤΗ ΠΡΑΓΜΑΤΙΚΗ ΕΞΟΥΣΙΑ ──
 :first-authoritative-sequence 1
 :sequence-0-kind :legacy-adoption-certificate
 :sequence-0-writes-authoritative-release nil

 ;; ── ΥΠΟΧΡΕΩΤΙΚΑ ΠΕΔΙΑ ΤΟΥ CERTIFICATE ΤΗΣ ΓΕΝΕΣΗΣ ──
 ;; Απόν πεδίο = ΑΚΥΡΟ certificate (fail-closed, ελέγχεται από τον checker).
 :required-certificate-fields
 (:source-commit :legacy-manifest-digest :legacy-archive-root :legacy-releases
  :legacy-latest-pointers :tsa-evidence :jws-evidence :new-verifier-result
  :known-divergences :adoption-mode :inherited-authority :inherited-attestation
  :genesis-policy-hash)

 ;; ── ΥΠΟΓΡΑΦΗ ΚΑΙ ΧΡΟΝΟΣ: FAIL-CLOSED ΜΕΧΡΙ ΤΗΝ ΤΕΛΕΤΗ ──
 ;; Η ΠΑΡΑΓΩΓΙΚΗ υπογραφή της γένεσης και το TSA receipt της ΑΠΑΙΤΟΥΝ την
 ;; owner-root ceremony (πραγματικό ιδιωτικό κλειδί). Μέχρι τότε το genesis
 ;; certificate είναι ΑΝΥΠΟΓΡΑΦΟ και το production authority writer ΚΛΕΙΣΤΟ.
 ;; Τα test keys είναι ΜΟΝΟ για fixtures — ΠΟΤΕ production.
 :production-signature-status :fail-closed-pending-owner-root-ceremony
 :production-tsa-status :fail-closed-pending-owner-root-ceremony
 :test-key-usage :fixtures-only

 ;; ── ΕΞΩΤΕΡΙΚΟΙ ΤΡΙΤΟΙ (απαίτηση 7 της διορθωτικής) ──
 :external-quorum-status :disabled
 :external-genesis-anchor-status :disabled
 :split-view-resistance-claim nil          ; ΚΑΜΙΑ δήλωση πριν από πραγματικούς witnesses

 ;; ── ΓΝΩΣΤΕΣ ΑΠΟΚΛΙΣΕΙΣ ΑΠΟ ΤΗΝ ΕΝΤΟΛΗ (τίμια άγνοια ως δεδομένο) ──
 :known-divergences
 ((:id :release-count
   :expected "η εντολή ανέφερε 24 legacy releases"
   :observed "ο ντετερμινιστικός snapshot βρήκε 18 top-level releases (6 corpora × 3)"
   :resolution "καταγράφεται ο ΠΡΑΓΜΑΤΙΚΟΣ αριθμός· κανένας αριθμός δεν κατασκευάζεται για να ταιριάξει")
  (:id :canonical-wire
   :expected "deterministic CBOR επικυρωμένο από EverCBOR/EverCDDL/EverParse"
   :observed "F* toolchain ΑΠΩΝ στο περιβάλλον· δίκτυο 403"
   :resolution "canonical parser gate = RED (BLOCKED-TOOLCHAIN)· ΚΑΜΙΑ δεύτερη κανονική έδρα σε CL· τα staging artifacts φέρουν canonical_encoding=PENDING-EVERPARSE")
  (:id :store-substrate
   :expected "Perennial 2.0/GoTxn αποδεδειγμένο store"
   :observed "Coq ΑΠΩΝ· δίκτυο 403"
   :resolution "production writer ΑΠΕΝΕΡΓΟΠΟΙΗΜΕΝΟΣ· ΚΑΝΕΝΑ προσωρινό intent-log πίσω από το τελικό interface")))
