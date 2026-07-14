;; deployment/data/body-kind-registry.sexp — [0088] Φ1
;; Μητρώο ειδών νομικών σωμάτων για την έδρα orchestrator.identity.
;; ΔΕΝ είναι κλειστό enum στον κώδικα: επεκτείνεται ΜΟΝΟ με νέα εγγραφή εδώ
;; + receipt + ρητή έγκριση δημιουργού (σχέδιο LAWMAX-TEMPORAL-IDENTITY-DESIGN §1.1).
(:schema :body-kind-registry/1
 :kinds (:syntagma      ; Σύνταγμα
         :kodikas       ; Κώδικας (ΠΚ, ΚΠΔ, ΑΚ, ΚΠολΔ, ΚΔΔ …)
         :nomos         ; Νόμος
         :nd            ; Νομοθετικό Διάταγμα
         :an            ; Αναγκαστικός Νόμος
         :pd            ; Προεδρικό Διάταγμα
         :ya            ; Υπουργική Απόφαση
         :psifisma      ; Ψήφισμα (αναθεωρητικής Βουλής)
         :eu-reg        ; Κανονισμός ΕΕ
         :eu-dir))      ; Οδηγία ΕΕ
