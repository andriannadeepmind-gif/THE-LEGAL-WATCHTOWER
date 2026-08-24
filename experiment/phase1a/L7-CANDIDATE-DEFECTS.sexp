;;;; experiment/phase1a/L7-CANDIDATE-DEFECTS.sexp
;;;; ΕΞΩΤΕΡΙΚΟ ΜΗΤΡΩΟ ΤΑΞΙΝΟΜΗΣΗΣ — ΟΧΙ μέσα στο σφραγισμένο dossier.
;;;;
;;;; EARLY CORRECTION §1: τα 30 ευρήματα του L7 ΔΕΝ εισάγονται ακόμη στο B⁻.
;;;; Ταξινομούνται ως L7-UNRECONCILED-CANDIDATE-DEFECTS. Οριστικό baseline
;;;; defect απαιτεί, ΜΕΤΑ τη σφράγιση και των επτά lanes: ανεξάρτητη
;;;; επιβεβαίωση άλλης lane Ή κεντρική επαλήθευση στο frozen corpus +
;;;; ακριβή claim/evidence/defeater analysis + root-cause classification.
;;;; Το σφραγισμένο dossier (sha256 6ab0457e…) ΔΕΝ αλλάζει από αυτό το αρχείο.

(:lawmax-L7-candidate-defects/1
 :classification :L7-UNRECONCILED-CANDIDATE-DEFECTS
 :source-dossier "experiment/phase1a/contracts.sexp"
 :source-dossier-sha256 "6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"
 :count-reported-by-lane 30
 :promotion-to-B-minus :BLOCKED-UNTIL-ALL-SEVEN-SEALED
 :promotion-requires
 ("ανεξάρτητη επιβεβαίωση από άλλη lane Ή κεντρική επαλήθευση στο frozen corpus"
  "ακριβής claim/evidence/defeater analysis ανά εύρημα"
  "root-cause classification")

 ;; EARLY CORRECTION §4: αυστηρός διαχωρισμός σε 4 τάξεις εξάρτησης/εκτέλεσης.
 ;; Κάθε candidate defect ΠΡΕΠΕΙ να δεθεί με το ΑΚΡΙΒΕΣ δημόσιο claim που
 ;; διαψεύδει — όχι με γενική «καθαρότητα».
 :dependency-taxonomy
 ((:class :build-time        :meaning "χρειάζεται ΜΟΝΟ κατά το docker build")
  (:class :test-conformance  :meaning "χρειάζεται σε build stage επαλήθευσης/conformance")
  (:class :final-runtime-pkg :meaning "εγκατεστημένο στην ΤΕΛΙΚΗ εικόνα")
  (:class :runtime-subprocess :meaning "ΠΡΑΓΜΑΤΙΚΗ εκτέλεση υποδιεργασίας σε λειτουργία"))

 :requires-final-stage-closure
 "Η παρουσία Python/node/bash σε ΥΠΟΧΡΕΩΤΙΚΟ build stage ΔΕΝ αποδεικνύει από
  μόνη της ότι το τελικό runtime τα χρειάζεται. Πριν προαχθεί οποιοδήποτε
  εύρημα «runtime purity», απαιτείται απόδειξη final-stage package/process
  closure — ΕΚΚΡΕΜΕΙ, ανατίθεται στην κεντρική επαλήθευση της reconciliation."

 :claim-binding-required
 "Τα apt-get update διαψεύδουν ΙΣΧΥΡΙΣΜΟ offline/content-addressed reproducible
  CONSTRUCTION (DEPENDENCY-CONTRACT.md «docker build --network=none»,
  PROVENANCE.yaml hermetic:true). ΔΕΝ διαψεύδουν αυτομάτως κάθε σημασία
  runtime hermeticity. Κάθε εύρημα δένεται με το ΑΚΡΙΒΕΣ claim του."

 :note "Το πλήρες κείμενο των 30 candidate defects ΖΕΙ στο σφραγισμένο dossier
        (contracts.sexp) με τις άγκυρές του. Εδώ κρατείται ΜΟΝΟ η ταξινόμηση
        κατάστασης και οι κανόνες προαγωγής — καμία επανάληψη, μία έδρα.")
