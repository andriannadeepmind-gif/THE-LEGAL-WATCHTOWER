;;;; authority-v2/toolchain/trusted-toolchain-manifest.sexp
;;;; ============================================================================
;;;; TRUSTED TOOLCHAIN MANIFEST + END-TO-END REFINEMENT OBLIGATION (γραμμή 9b)
;;;; ============================================================================
;;;; ΑΠΑΙΤΗΣΗ (διορθωτική §9): «ρητό end-to-end refinement obligation από formal
;;;; specification → generated source → compiled binary, reproducible-build
;;;; comparison και trusted-toolchain manifest».
;;;;
;;;; ΤΟ ΠΡΟΒΛΗΜΑ ΠΟΥ ΛΥΝΕΙ: μια απόδειξη στο επίπεδο προδιαγραφής δεν λέει
;;;; ΤΙΠΟΤΑ για το binary που τρέχει. Ανάμεσά τους μεσολαβούν: extraction,
;;;; compilation, linking, libc, kernel. Κάθε κρίκος ΠΡΕΠΕΙ να έχει ονομασμένη
;;;; υποχρέωση και ονομασμένο εργαλείο — αλλιώς το «formally verified» είναι
;;;; τελετουργία (trusting-trust).
;;;;
;;;; ΚΑΤΑΣΤΑΣΗ: κάθε κρίκος φέρει status. Το gate 9b γίνεται PROVED ΜΟΝΟ όταν
;;;; ΚΑΘΕ κρίκος είναι :discharged.

(:lawmax-trusted-toolchain/1

 :assurance-status :under-construction
 :gate-9b :not-passed

 ;; ── Η ΑΛΥΣΙΔΑ ΔΙΥΛΙΣΗΣ (refinement chain) ──────────────────────────────────
 ;; Κάθε κρίκος: από τι, σε τι, με ποιο εργαλείο, με ποια υποχρέωση απόδειξης.
 :refinement-chain
 ((:link 1
   :from "formal specification (CDDL σχήματα + pure state-transition model)"
   :to   "F*/Coq ορισμοί"
   :tool "EverCDDL + Perennial (Goose)"
   :obligation "οι ορισμοί ΑΠΟΔΙΔΟΥΝ ΠΙΣΤΑ το σχήμα: κάθε δεκτό byte-string του
                CDDL γίνεται δεκτό από τον παραγόμενο parser και αντιστρόφως"
   :status :blocked-toolchain
   :blocker "F*/Coq απόντα (403)")

  (:link 2
   :from "F*/Coq ορισμοί"
   :to   "παραγόμενος πηγαίος (C μέσω KaRaMeL / Go μέσω Goose)"
   :tool "KaRaMeL, Goose"
   :obligation "extraction soundness: η σημασιολογία του παραγόμενου ΤΑΥΤΙΖΕΤΑΙ
                με του αποδεδειγμένου ορισμού (θεώρημα του εργαλείου, ΟΧΙ δικό μας)"
   :status :blocked-toolchain
   :blocker "τα εργαλεία απόντα (403)")

  (:link 3
   :from "παραγόμενος πηγαίος C"
   :to   "εκτελέσιμο binary"
   :tool "CompCert (verified C compiler)"
   :obligation "compiler correctness: η συμπεριφορά του binary είναι ΜΙΑ ΑΠΟ ΤΙΣ
                επιτρεπτές του πηγαίου (CompCert θεώρημα)"
   :status :externally-blocked
   :blocker "ccomp απόν ΚΑΙ εμπορική άδεια απαιτούμενη — βλ. :compcert-license-gate")

  (:link 4
   :from "εκτελέσιμο binary (δικό μας build)"
   :to   "εκτελέσιμο binary (ανεξάρτητο rebuild)"
   :tool "reproducible build comparison"
   :obligation "byte-for-byte ταυτότητα από ανεξάρτητο rebuild του ΙΔΙΟΥ πηγαίου
                — αν διαφέρουν, κάτι μη δηλωμένο μπήκε στο binary"
   :status :not-started
   :blocker nil)

  (:link 5
   :from "binary + περιβάλλον εκτέλεσης"
   :to   "παρατηρούμενη συμπεριφορά"
   :tool "runtime TCB declaration"
   :obligation "ΔΗΛΩΣΗ (όχι απόδειξη): libc, kernel, CPU microcode είναι ΕΚΤΟΣ
                απόδειξης. Καταγράφονται ρητά ως residual TCB."
   :status :declared-residual
   :blocker nil))

 ;; ── ΑΔΕΙΑ COMPCERT (διορθωτική §6) ────────────────────────────────────────
 :compcert-license-gate
 (:variable "COMPCERT_COMMERCIAL_LICENSE"
  :value :required-for-production
  :rules
  ("η δωρεάν έκδοση CompCert ΔΕΝ επιτρέπεται ως εμπορική production εξάρτηση"
   "επιτρέπεται ΜΟΝΟ μη-εμπορική evaluation σύμφωνα με την άδεια"
   "ΚΑΝΕΝΑ production binary δεν χαρακτηρίζεται compiler-verified μέχρι την απόφαση"
   "η υπόλοιπη αρχιτεκτονική συνεχίζει κανονικά — ο κρίκος 3 μένει ανοιχτός")
  :decision-owner :creator
  :decision-status :pending)

 ;; ── ΤΑ ΕΡΓΑΛΕΙΑ ΠΟΥ ΕΜΠΙΣΤΕΥΟΜΑΣΤΕ (και τι σημαίνει αυτό) ─────────────────
 ;; Κάθε εγγραφή: τι κάνει, τι ΔΕΝ αποδεικνύει, πώς καρφώνεται.
 :trusted-tools
 ((:tool "F*/EverParse" :role "verified parsing" :pin :required
   :trusted-because "τα θεωρήματά του ελέγχονται από το F* kernel"
   :does-not-prove "ότι το CDDL σχήμα εκφράζει τη ΣΩΣΤΗ πρόθεση")
  (:tool "Coq/Perennial" :role "crash-safety proofs" :pin :required
   :trusted-because "Coq kernel"
   :does-not-prove "ότι το μοντέλο αποθήκευσης αντιστοιχεί στον ΠΡΑΓΜΑΤΙΚΟ δίσκο")
  (:tool "CompCert" :role "verified compilation" :pin :required
   :trusted-because "θεώρημα ορθότητας μεταγλωττιστή σε Coq"
   :does-not-prove "τίποτα για assembler/linker/libc")
  (:tool "SBCL" :role "legacy producer runtime" :pin :required
   :trusted-because "ΔΕΝ εμπιστευόμαστε — ο producer είναι ΜΗ ΕΜΠΙΣΤΟΣ εξ ορισμού"
   :does-not-prove "τίποτα· γι' αυτό ο producer δεν έχει write capability"))

 ;; ── RESIDUAL TCB (κλειστός κατάλογος — αν λείπει, είναι σφάλμα) ───────────
 :residual-tcb
 ("F* kernel" "Coq kernel" "OCaml runtime των provers" "CompCert (όταν ενεργοποιηθεί)"
  "assembler + linker" "libc" "Linux kernel (DAC επιβολή capability)"
  "CPU/microcode" "SHA-256 collision resistance (εμπειρική υπόθεση)"
  "Ed25519 (εμπειρική υπόθεση)"
  "η ΑΝΤΙΣΤΟΙΧΙΑ CDDL σχήματος ↔ πρόθεσης (ανθρώπινη κρίση)"))
