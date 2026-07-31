;;;; authority-v2/log/witness-policy.sexp
;;;; ============================================================================
;;;; WITNESS INTERFACE + QUORUM/FRESHNESS POLICY (απαίτηση 8, μέρος)
;;;; ============================================================================
;;;; ΑΥΣΤΗΡΟ ΟΡΙΟ (διορθωτική §2): το C2SP WIRE FORMAT (tlog-tiles@v0.1.0,
;;;; tlog-checkpoint, tlog-witness@v1.0.0) είναι BLOCKED-SPEC-INPUT — τα
;;;; κανονικά κείμενα δεν ανακτώνται (403) και ΑΠΑΓΟΡΕΥΕΤΑΙ υλοποίηση από μνήμη.
;;;;
;;;; ΤΙ ΕΙΝΑΙ ΑΥΤΟ: η ΠΟΛΙΤΙΚΗ κβόρουμ/φρεσκάδας και το interface των μαρτύρων,
;;;; ΑΝΕΞΑΡΤΗΤΑ ΑΠΟ ΜΟΡΦΗ. Ο μάρτυρας δέχεται ΑΔΙΑΦΑΝΗ bytes checkpoint και
;;;; επιστρέφει υπογραφή· η ΠΟΛΙΤΙΚΗ κρίνει πόσες/πόσο φρέσκες χρειάζονται.
;;;; Καμία γραμμή εδώ δεν υποθέτει σειριοποίηση — όταν έρθει το κανονικό
;;;; κείμενο, μπαίνει ΚΑΤΩ από αυτό το interface χωρίς να το αλλάξει.
;;;;
;;;; ΚΑΜΙΑ ΔΗΛΩΣΗ SPLIT-VIEW RESISTANCE: external_quorum_status = disabled.
;;;; Με ΜΟΝΟ τοπικούς fake witnesses δεν υπάρχει ανεξαρτησία — και δεν
;;;; προσποιούμαστε ότι υπάρχει.

(:lawmax-witness-policy/1

 :assurance-status :under-construction
 :external-quorum-status :disabled
 :split-view-resistance-claim nil
 :wire-format-status :blocked-spec-input
 :wire-format-pins
 ((:name "C2SP tlog-tiles"      :version "v0.1.0" :source-hash :required)
  (:name "C2SP tlog-checkpoint" :version :latest  :source-hash :required)
  (:name "C2SP tlog-witness"    :version "v1.0.0" :source-hash :required))

 ;; ── INTERFACE ΜΑΡΤΥΡΑ (format-agnostic) ──────────────────────────────────
 :witness-interface
 (:operation "cosign"
  :input  ((:name :checkpoint-bytes :type "opaque bytes" :note "ΑΔΙΑΦΑΝΗ — ο μάρτυρας
             δεν χρειάζεται να ξέρει τη μορφή για να δεσμευτεί σε αυτά τα bytes")
           (:name :expected-origin :type "string"))
  :output ((:name :signature :type "ed25519-sig")
           (:name :witness-id :type "string")
           (:name :observed-at :type "utc-seconds"))
  :failure-modes (:refused-inconsistent   ; ο μάρτυρας ΕΙΔΕ αντικρουόμενη εικόνα
                  :refused-stale
                  :unreachable))

 ;; ── ΠΟΛΙΤΙΚΗ ΚΒΟΡΟΥΜ ──────────────────────────────────────────────────────
 ;; Το κβόρουμ έχει νόημα ΜΟΝΟ αν οι μάρτυρες είναι ΠΡΑΓΜΑΤΙΚΑ ανεξάρτητοι.
 ;; Γι' αυτό η πολιτική απαιτεί ΔΗΛΩΜΕΝΗ ανεξαρτησία ανά μάρτυρα — αλλιώς N
 ;; μάρτυρες στο ίδιο μηχάνημα μετρούν ως ΕΝΑΣ.
 :quorum-policy
 (:required-signatures 3
  :from-independent-operators 3
  :independence-criteria
  ("διαφορετικός φορέας εκμετάλλευσης (νομικό πρόσωπο)"
   "διαφορετική υποδομή δικτύου/φιλοξενίας"
   "καμία κοινή διοικητική εξουσία με την αρχή")
  :counting-rule "μάρτυρες που μοιράζονται ΟΠΟΙΟΔΗΠΟΤΕ κριτήριο ανεξαρτησίας
                  μετρούν ΩΣ ΕΝΑΣ — το πλήθος δεν είναι κβόρουμ"
  :enforcement :fail-closed
  :current-state "ΚΑΝΕΝΑΣ ανεξάρτητος μάρτυρας ⇒ το κβόρουμ ΔΕΝ ικανοποιείται ⇒
                  η δημοσίευση με witness quorum είναι ΑΝΕΝΕΡΓΗ (disabled), ΟΧΙ
                  'προσωρινά 0-of-3'")

 ;; ── ΠΟΛΙΤΙΚΗ ΦΡΕΣΚΑΔΑΣ (anti-freeze) ─────────────────────────────────────
 :freshness-policy
 (:max-checkpoint-age-seconds 86400
  :max-witness-observation-lag-seconds 3600
  :monotonic-time-required t
  :rule "checkpoint παλαιότερο του ορίου ΑΠΟΡΡΙΠΤΕΤΑΙ ακόμη κι αν είναι έγκυρα
         υπογεγραμμένο — η εγκυρότητα δεν είναι φρεσκάδα"
  :rationale "χωρίς όριο ηλικίας, ο επιτιθέμενος σε παγώνει σερβίροντας τέλεια
              έγκυρο ΠΑΛΙΟ checkpoint· η επίθεση δεν σπάει κρυπτογραφία")

 ;; ── ΤΟΠΙΚΟΙ FAKE WITNESSES (ΜΟΝΟ για tests) ──────────────────────────────
 :local-fake-witnesses
 (:purpose "να ασκείται η ΠΟΛΙΤΙΚΗ (κβόρουμ/φρεσκάδα/αντιφατική εικόνα) χωρίς
            δίκτυο — ΠΟΤΕ ως υποκατάστατο ανεξαρτησίας"
  :independence :none
  :counts-toward-quorum nil            ; ΔΟΜΙΚΑ: δεν μετρούν ποτέ
  :scenarios (:all-agree :one-refuses-inconsistent :one-stale :two-share-operator
              :all-unreachable)))
