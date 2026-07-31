;;;; authority-v2/proof-manifest.sexp
;;;; ============================================================================
;;;; PROOF MANIFEST — κάθε θεώρημα με ΜΙΑ από τρεις καταστάσεις (διορθωτική §5)
;;;; ============================================================================
;;;; ΕΠΙΤΡΕΠΤΕΣ ΚΑΤΑΣΤΑΣΕΙΣ: :proved · :failed · :blocked-toolchain
;;;;
;;;; ΚΑΝΟΝΑΣ: certificates και bounded checking ΜΠΟΡΟΥΝ να λειτουργούν κατά την
;;;; κατασκευή, αλλά ΔΕΝ αναβαθμίζουν status. Το συνολικό Level-7 gate περνά
;;;; ΜΟΝΟ όταν ΟΛΑ τα φέροντα θεωρήματα είναι :proved.
;;;;
;;;; Το proof debt ΔΕΝ είναι αποδεκτό τελικό αποτέλεσμα — είναι καταγεγραμμένο
;;;; χρέος με ονομασμένο μονοπάτι εξόφλησης (hermetic build ανά toolchain).

(:lawmax-proof-manifest/1

 :assurance-status :under-construction
 :gate :not-passed
 :gate-rule "PASS ⟺ κάθε θεώρημα με :load-bearing t είναι :proved"

 :provers
 ((:name "F*" :purpose "admission kernel + parser soundness" :present nil
   :unblock-path "authority-v2/toolchain/everparse.Dockerfile")
  (:name "Coq/Perennial" :purpose "store atomicity + recovery" :present nil
   :unblock-path "authority-v2/toolchain/perennial.Dockerfile")
  (:name "CompCert" :purpose "compiler correctness (κρίκος 3)" :present nil
   :unblock-path "εμπορική άδεια — απόφαση δημιουργού"))

 :theorems
 ;; ── Admission kernel (πηγή: authority-v2/kernel/admission-model.sexp) ──
 ((:id :T1-authorization              :load-bearing t :status :blocked-toolchain :prover "F*")
  (:id :T2-completeness               :load-bearing t :status :blocked-toolchain :prover "F*")
  (:id :T3-no-rollback                :load-bearing t :status :blocked-toolchain :prover "F*")
  (:id :T4-unique-latest              :load-bearing t :status :blocked-toolchain :prover "F*")
  (:id :T5-monotonic-sequence         :load-bearing t :status :blocked-toolchain :prover "F*")
  (:id :T6-deterministic-replay       :load-bearing t :status :blocked-toolchain :prover "F*")
  (:id :T7-rejection-no-state-change  :load-bearing t :status :blocked-toolchain :prover "F*")
  (:id :T8-profile-continuity         :load-bearing t :status :blocked-toolchain :prover "F*")
  (:id :T9-certificate-soundness      :load-bearing t :status :blocked-toolchain :prover "F*")
  ;; ── Parser (απαίτηση 3) ──
  (:id :P1-cddl-parser-soundness      :load-bearing t :status :blocked-toolchain :prover "F*"
   :statement "ο παραγόμενος parser δέχεται ΑΚΡΙΒΩΣ τα byte-strings που το CDDL ορίζει")
  (:id :P2-deterministic-encoding     :load-bearing t :status :blocked-toolchain :prover "F*"
   :statement "encode∘decode = id ΚΑΙ decode∘encode = id στο πεδίο του σχήματος
               (καμία δεύτερη έγκυρη κωδικοποίηση της ίδιας τιμής)")
  ;; ── Store (απαίτηση 7) ──
  (:id :S1-transaction-atomicity      :load-bearing t :status :blocked-toolchain :prover "Coq/Perennial"
   :statement "τα έξι στοιχεία της συναλλαγής γίνονται ορατά ΟΛΑ ή ΚΑΝΕΝΑ")
  (:id :S2-crash-recovery             :load-bearing t :status :blocked-toolchain :prover "Coq/Perennial"
   :statement "crash σε οποιοδήποτε σημείο ⇒ recovery σε ΠΡΙΝ ή ΜΕΤΑ, ποτέ υβρίδιο")
  ;; ── Checker (απαίτηση 6) ──
  (:id :C1-checker-soundness          :load-bearing t :status :blocked-toolchain :prover "F*"
   :statement "ο checker δέχεται certificate ⇒ ΚΑΘΕ conjunct της K ίσχυε")
  ;; ── Refinement (γραμμή 9b) ──
  (:id :R1-extraction-soundness       :load-bearing t :status :blocked-toolchain :prover "KaRaMeL/Goose")
  (:id :R2-compiler-correctness       :load-bearing t :status :blocked-toolchain :prover "CompCert"
   :note "ΚΑΙ εμπορική άδεια — διπλό blocker")
  (:id :R3-reproducible-build         :load-bearing t :status :blocked-toolchain :prover "byte comparison"
   :note "δεν χρειάζεται prover· χρειάζεται δύο ανεξάρτητα builds"))

 :summary
 (:total 17 :proved 0 :failed 0 :blocked-toolchain 17
  :statement "0/17 PROVED. ΤΟ ΣΥΣΤΗΜΑ ΔΕΝ ΕΙΝΑΙ LEVEL-7 ΚΑΙ ΔΕΝ ΧΑΡΑΚΤΗΡΙΖΕΤΑΙ
              FORMALLY-VERIFIED. Καμία απαίτηση δεν αντικαταστάθηκε από κατώτερη
              υλοποίηση· κάθε blocker έχει ονομασμένο hermetic μονοπάτι άρσης."))
